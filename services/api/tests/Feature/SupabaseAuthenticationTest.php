<?php

namespace Tests\Feature;

use App\Modules\Identity\Http\AuthenticateSupabase;
use App\Modules\Identity\Models\User;
use Firebase\JWT\JWT;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

final class SupabaseAuthenticationTest extends TestCase
{
    private static array $signers = [];

    private string $subject = '7daf4462-6c1d-46c5-a4c9-6c41d26c3c43';

    private string $url = 'https://fixture.supabase.co';

    private bool $postgres = false;

    private array $jwksDocument = [];

    private int $jwksStatus = 200;

    protected function setUp(): void
    {
        parent::setUp();
        $this->postgres = getenv('IDENTITY_TEST_POSTGRES') === '1';
        if ($this->postgres) {
            // Transactional schema isolation: never migrate/reset existing tables.
            $this->assertSame('127.0.0.1', config('database.connections.pgsql.host'));
            $this->assertSame('5433', (string) config('database.connections.pgsql.port'));
            DB::beginTransaction();
            $schema = 'identity_test_'.str_replace('-', '', (string) Str::uuid());
            DB::statement('CREATE SCHEMA '.$schema);
            DB::statement('SET LOCAL search_path TO '.$schema);
        } else {
            config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:']);
            DB::purge('sqlite');
        }
        (require database_path('migrations/2026_11_13_000001_create_users_table.php'))->up();
        config([
            'cache.default' => 'array',
            'supabase.url' => $this->url,
            'supabase.jwt_issuer' => $this->url.'/auth/v1',
            'supabase.jwks_url' => $this->url.'/auth/v1/.well-known/jwks.json',
            'supabase.jwt_audience' => 'authenticated',
        ]);
        Cache::flush();
        Http::preventStrayRequests();
        $this->jwksDocument = ['keys' => [$this->signer('first')['jwk']]];
        Http::fake([$this->url.'/*' => fn () => Http::response($this->jwksDocument, $this->jwksStatus)]);
    }

    protected function tearDown(): void
    {
        if ($this->postgres) {
            DB::rollBack();
        }
        parent::tearDown();
    }

    private function signer(string $kid, string $alg = 'RS256'): array
    {
        $index = $kid.$alg;
        if (! isset(self::$signers[$index])) {
            $options = ['config' => base_path('tests/openssl.cnf')];
            $key = openssl_pkey_new($options + ($alg === 'ES256'
                ? ['private_key_type' => OPENSSL_KEYTYPE_EC, 'curve_name' => 'prime256v1']
                : ['private_key_type' => OPENSSL_KEYTYPE_RSA, 'private_key_bits' => 2048]));
            openssl_pkey_export($key, $pem, null, $options);
            $details = openssl_pkey_get_details($key);
            $jwk = ['kid' => $kid, 'alg' => $alg, 'use' => 'sig'];
            $jwk += $alg === 'ES256'
                ? ['kty' => 'EC', 'crv' => 'P-256', 'x' => JWT::urlsafeB64Encode($details['ec']['x']), 'y' => JWT::urlsafeB64Encode($details['ec']['y'])]
                : ['kty' => 'RSA', 'n' => JWT::urlsafeB64Encode($details['rsa']['n']), 'e' => JWT::urlsafeB64Encode($details['rsa']['e'])];
            self::$signers[$index] = ['pem' => $pem, 'jwk' => $jwk];
        }

        return self::$signers[$index];
    }

    private function token(array $claims = [], string $kid = 'first', string $alg = 'RS256'): string
    {
        return JWT::encode(array_replace([
            'iss' => $this->url.'/auth/v1', 'aud' => 'authenticated', 'sub' => $this->subject,
            'role' => 'authenticated', 'iat' => time() - 10, 'exp' => time() + 300,
        ], $claims), $this->signer($kid, $alg)['pem'], $alg, $kid);
    }

    public function test_missing_and_malformed_tokens_are_standardized(): void
    {
        foreach ([null, 'garbage', 'Bearer broken', 'Bearer a.b.c', 'Bearer a.b.c extra'] as $header) {
            $response = $this->getJson('/api/v1/me', $header === null ? [] : ['Authorization' => $header]);
            $response->assertUnauthorized()->assertJsonPath('error.code', 'UNAUTHENTICATED')
                ->assertJsonStructure(['error' => ['code', 'message', 'details'], 'request_id'])
                ->assertHeader('WWW-Authenticate', 'Bearer');
        }
        Http::assertNothingSent();
        $this->assertSame(0, User::count());
    }

    public static function invalidClaims(): array
    {
        return [
            'expired' => [['exp' => 1]], 'missing expiry' => [['exp' => null]],
            'string expiry' => [['exp' => '9999999999']], 'issuer' => [['iss' => 'https://other.supabase.co/auth/v1']],
            'audience' => [['aud' => 'anon']], 'subject' => [['sub' => 'not-a-uuid']],
            'missing subject' => [['sub' => null]], 'nil subject' => [['sub' => '00000000-0000-0000-0000-000000000000']],
            'privileged role' => [['role' => 'service_role']], 'future nbf' => [['nbf' => 4102444800]],
        ];
    }

    #[DataProvider('invalidClaims')]
    public function test_invalid_claims_never_provision(array $claims): void
    {
        $this->withToken($this->token($claims))->getJson('/api/v1/me')->assertUnauthorized();
        $this->assertSame(0, User::count());
    }

    public function test_invalid_signature_and_unsupported_algorithms(): void
    {
        $forged = JWT::encode(['exp' => time() + 300], $this->signer('attacker')['pem'], 'RS256', 'first');
        $this->withToken($forged)->getJson('/api/v1/me')->assertUnauthorized();
        $hmac = JWT::encode(['sub' => $this->subject], str_repeat('x', 32), 'HS256', 'first');
        $this->withToken($hmac)->getJson('/api/v1/me')->assertUnauthorized();
        $none = JWT::urlsafeB64Encode('{"alg":"none","kid":"first"}').'.e30.eA';
        $this->withToken($none)->getJson('/api/v1/me')->assertUnauthorized();
        Http::assertSentCount(1);
        $this->assertSame(0, User::count());
    }

    public function test_verified_identity_is_idempotent_and_cannot_select_another_user(): void
    {
        $other = '3a63d1dd-08cf-446d-9bcd-d7cb3110e377';
        User::create(['id' => $other]);
        $token = $this->token(['aud' => ['authenticated'], 'user_metadata' => ['status' => 'verified']]);
        $this->withToken($token)->getJson('/api/v1/me?user_id='.$other)->assertOk()
            ->assertJsonPath('data.id', $this->subject)->assertJsonPath('data.status', 'pending');
        $created = User::findOrFail($this->subject)->created_at;
        $this->withToken($token)->getJson('/api/v1/me')->assertOk();
        $this->assertSame(2, User::count());
        $this->assertTrue($created->equalTo(User::findOrFail($this->subject)->created_at));
        Http::assertSentCount(1);
    }

    public function test_disabled_user_is_forbidden(): void
    {
        $user = User::create(['id' => $this->subject]);
        $user->status = 'disabled';
        $user->save();
        $this->withToken($this->token())->getJson('/api/v1/me')->assertForbidden()->assertJsonPath('error.code', 'FORBIDDEN');
    }

    public function test_owner_policy_denies_another_users_resource(): void
    {
        Gate::define('read-identity-fixture', fn ($user, $id) => $user->id === $id);
        Route::get('/api/identity-fixture/{id}', function (Request $request, string $id) {
            Gate::forUser($request->user())->authorize('read-identity-fixture', $id);

            return response()->json(['id' => $id]);
        })->middleware(AuthenticateSupabase::class);
        $this->withToken($this->token())->getJson('/api/identity-fixture/'.$this->subject)->assertOk();
        $this->withToken($this->token())->getJson('/api/identity-fixture/3a63d1dd-08cf-446d-9bcd-d7cb3110e377')
            ->assertForbidden()->assertJsonPath('error.code', 'FORBIDDEN');
    }

    public function test_malformed_jwks_and_untrusted_endpoint_fail_closed(): void
    {
        $this->jwksDocument = ['keys' => [['kid' => 'first', 'alg' => 'RS256', 'kty' => 'RSA']]];
        $this->withToken($this->token())->getJson('/api/v1/me')->assertStatus(503);
        config(['supabase.jwks_url' => 'https://attacker.invalid/keys']);
        $this->withToken($this->token())->getJson('/api/v1/me')->assertStatus(503);
        Http::assertSentCount(1);
        $this->assertSame(0, User::count());
    }

    public function test_es256_signatures_are_supported(): void
    {
        $this->jwksDocument = ['keys' => [$this->signer('ec', 'ES256')['jwk']]];
        $this->withToken($this->token([], 'ec', 'ES256'))->getJson('/api/v1/me')->assertOk();
    }

    public function test_rotation_refresh_is_bounded_and_accepts_new_key(): void
    {
        $this->withToken($this->token())->getJson('/api/v1/me')->assertOk();
        $this->withToken($this->token([], 'rotated'))->getJson('/api/v1/me')->assertUnauthorized();
        Http::assertSentCount(1);
        $this->travel(31)->seconds();
        $this->jwksDocument = ['keys' => [$this->signer('rotated')['jwk']]];
        $this->withToken($this->token([], 'rotated'))->getJson('/api/v1/me')->assertOk();
        $this->withToken($this->token())->getJson('/api/v1/me')->assertUnauthorized();
    }

    public function test_jwks_outage_fails_closed_and_does_not_repeatedly_fetch(): void
    {
        $this->jwksStatus = 503;
        for ($i = 0; $i < 2; $i++) {
            $this->withToken($this->token())->getJson('/api/v1/me')->assertStatus(503)->assertJsonPath('error.code', 'AUTH_UNAVAILABLE');
        }
        Http::assertSentCount(1);
        $this->assertSame(0, User::count());
    }

    public function test_expired_cache_is_not_used_during_outage(): void
    {
        $this->withToken($this->token())->getJson('/api/v1/me')->assertOk();
        $this->travel(301)->seconds();
        $this->jwksStatus = 503;
        $this->withToken($this->token())->getJson('/api/v1/me')->assertStatus(503);
    }

    public function test_rate_limit_has_standard_error(): void
    {
        $key = 'identity:ip:'.hash('sha256', '127.0.0.1');
        for ($i = 0; $i < 60; $i++) {
            RateLimiter::hit($key, 60);
        }
        $this->getJson('/api/v1/me')->assertStatus(429)->assertJsonPath('error.code', 'RATE_LIMITED')->assertHeader('Retry-After');
        Http::assertNothingSent();
    }

    public function test_identity_schema_is_reversible_and_has_no_password_columns(): void
    {
        $this->assertFalse(Schema::hasColumn('users', 'password'));
        $this->assertSame([], config('auth.guards'));
        $this->assertSame([], config('auth.providers'));
        $this->assertSame([], config('auth.passwords'));
        $migration = require database_path('migrations/2026_11_13_000001_create_users_table.php');
        $migration->down();
        $this->assertFalse(Schema::hasTable('users'));
        $migration->up();
        $this->assertTrue(Schema::hasTable('users'));
    }
}
