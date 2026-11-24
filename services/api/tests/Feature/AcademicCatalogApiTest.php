<?php

namespace Tests\Feature;

use Database\Seeders\DevelopmentAcademicCatalogSeeder;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

final class AcademicCatalogApiTest extends TestCase
{
    private bool $transactionStarted = false;

    private static array $signer = [];

    private array $ids = [];

    protected function setUp(): void
    {
        parent::setUp();
        if (getenv('ACADEMIC_TEST_POSTGRES') !== '1') {
            $this->markTestSkipped('Requires ACADEMIC_TEST_POSTGRES=1 and isolated local PostgreSQL.');
        }
        $this->assertSame('pgsql', config('database.default'));
        $this->assertSame('127.0.0.1', config('database.connections.pgsql.host'));
        $this->assertSame('5433', (string) config('database.connections.pgsql.port'));
        $this->assertEmpty(config('database.connections.pgsql.url'));
        DB::beginTransaction();
        $this->transactionStarted = true;
        $schema = 'catalog_test_'.str_replace('-', '', (string) Str::uuid());
        DB::statement('CREATE SCHEMA '.$schema);
        DB::statement('SET LOCAL search_path TO '.$schema);
        (require database_path('migrations/2026_11_13_000001_create_users_table.php'))->up();
        (require database_path('migrations/2026_11_15_000001_create_academic_tables.php'))->up();
        foreach (['owner', 'other', 'university', 'otherUniversity', 'course', 'otherCourse', 'global', 'skill'] as $key) {
            $this->ids[$key] = (string) Str::uuid();
        }
        foreach (['owner', 'other'] as $user) {
            DB::table('users')->insert(['id' => $this->ids[$user], 'display_name' => 'Private '.$user, 'created_at' => now(), 'updated_at' => now()]);
            DB::table('academic_profiles')->insert(['user_id' => $this->ids[$user], 'bio' => 'Secret biography']);
            DB::table('academic_preferences')->insert(['user_id' => $this->ids[$user], 'preferred_language' => 'id']);
        }
        DB::table('universities')->insert([
            ['id' => $this->ids['university'], 'name' => 'Fixture Alpha', 'verified_domains' => '["internal.invalid"]'],
            ['id' => $this->ids['otherUniversity'], 'name' => 'Fixture Beta', 'verified_domains' => '[]'],
        ]);
        DB::table('courses')->insert([
            ['id' => $this->ids['course'], 'university_id' => $this->ids['university'], 'code' => 'CS101', 'name' => 'Alpha Computing'],
            ['id' => $this->ids['otherCourse'], 'university_id' => $this->ids['otherUniversity'], 'code' => 'CS101', 'name' => 'Beta Computing'],
            ['id' => $this->ids['global'], 'university_id' => null, 'code' => 'CS101', 'name' => 'Global Computing'],
        ]);
        DB::table('skills')->insert(['id' => $this->ids['skill'], 'normalized_name' => 'dart']);
        DB::table('user_courses')->insert(['user_id' => $this->ids['other'], 'course_id' => $this->ids['course']]);
        DB::table('user_skills')->insert(['user_id' => $this->ids['other'], 'skill_id' => $this->ids['skill'], 'level' => 5]);
        if (self::$signer === []) {
            $options = ['config' => base_path('tests/openssl.cnf'), 'private_key_type' => OPENSSL_KEYTYPE_RSA, 'private_key_bits' => 2048];
            $key = openssl_pkey_new($options);
            openssl_pkey_export($key, $pem, null, $options);
            $details = openssl_pkey_get_details($key);
            self::$signer = ['pem' => $pem, 'jwk' => ['kty' => 'RSA', 'kid' => 'catalog-fixture', 'alg' => 'RS256', 'use' => 'sig', 'n' => JWT::urlsafeB64Encode($details['rsa']['n']), 'e' => JWT::urlsafeB64Encode($details['rsa']['e'])]];
        }
        config(['cache.default' => 'array', 'supabase.url' => 'https://fixture.supabase.co', 'supabase.jwt_issuer' => 'https://fixture.supabase.co/auth/v1', 'supabase.jwks_url' => 'https://fixture.supabase.co/auth/v1/.well-known/jwks.json', 'supabase.jwt_audience' => 'authenticated']);
        Cache::flush();
        Http::preventStrayRequests();
        Http::fake(['https://fixture.supabase.co/*' => Http::response(['keys' => [self::$signer['jwk']]])]);
    }

    protected function tearDown(): void
    {
        if ($this->transactionStarted) {
            DB::rollBack();
        }
        parent::tearDown();
    }

    private function token(string $user = 'owner', array $claims = []): string
    {
        return JWT::encode(array_replace(['iss' => 'https://fixture.supabase.co/auth/v1', 'aud' => 'authenticated', 'role' => 'authenticated', 'sub' => $this->ids[$user], 'exp' => time() + 300], $claims), self::$signer['pem'], 'RS256', 'catalog-fixture');
    }

    public function test_development_seed_items_are_available_through_authenticated_catalog_routes(): void
    {
        $this->app['env'] = 'local';
        config(['app.env' => 'local']);
        $this->seed(DevelopmentAcademicCatalogSeeder::class);
        $this->withToken($this->token());
        foreach ([
            'universities' => ['name', DevelopmentAcademicCatalogSeeder::UNIVERSITIES],
            'courses' => ['name', array_values(DevelopmentAcademicCatalogSeeder::COURSES)],
            'skills' => ['normalized_name', DevelopmentAcademicCatalogSeeder::SKILLS],
        ] as $catalog => [$field, $expected]) {
            $response = $this->getJson($this->url($catalog))->assertOk()->assertHeader('Cache-Control', 'no-store, private');
            foreach ($expected as $name) {
                $this->assertContains($name, array_column($response->json('data'), $field));
            }
        }
        $university = DB::table('universities')->where('name', 'Telkom University')->value('id');
        $response = $this->getJson($this->url('courses', ['university_id' => $university]))->assertOk();
        foreach ($response->json('data') as $course) {
            $this->assertNull($course['university_id']);
        }
        $this->assertCount(9, $response->json('data')); // Eight seeds plus existing global fixture.
    }

    private function url(string $catalog, array $query = []): string
    {
        return '/api/v1/'.$catalog.($query === [] ? '' : '?'.http_build_query($query));
    }

    private function snapshot(): array
    {
        $snapshot = [];
        foreach (['universities', 'courses', 'skills', 'users', 'academic_profiles', 'academic_preferences', 'user_courses', 'user_skills'] as $table) {
            $snapshot[$table] = DB::table($table)->get()->map(fn ($row) => json_encode($row))->sort()->values()->all();
        }

        return $snapshot;
    }

    public static function catalogs(): array
    {
        return [['universities', ['id', 'name']], ['courses', ['id', 'university_id', 'code', 'name']], ['skills', ['id', 'normalized_name']]];
    }

    #[DataProvider('catalogs')]
    public function test_authenticated_allowlists_no_private_data_or_mutations(string $catalog, array $fields): void
    {
        $before = $this->snapshot();
        $first = null;
        foreach (['owner', 'other'] as $user) {
            $response = $this->withToken($this->token($user))->getJson($this->url($catalog))->assertOk()
                ->assertHeader('Cache-Control', 'no-store, private')->assertHeader('X-Request-ID')
                ->assertDontSee('internal.invalid')->assertDontSee('Private owner')->assertDontSee('Secret biography');
            $this->assertSame(['data', 'request_id'], array_keys($response->json()));
            $this->assertSame($response->headers->get('X-Request-ID'), $response->json('request_id'));
            foreach ($response->json('data') as $item) {
                $this->assertSame($fields, array_keys($item));
            }
            if ($first !== null) {
                $this->assertSame($first, $response->json('data'));
            }
            $first = $response->json('data');
        }
        $this->getJson($this->url($catalog, ['user_id' => $this->ids['other']]))->assertUnprocessable();
        foreach (['POST', 'PUT', 'PATCH', 'DELETE'] as $method) {
            $this->json($method, $this->url($catalog), ['name' => 'Attempted write'])->assertStatus(405);
        }
        $this->assertSame($before, $this->snapshot());
    }

    #[DataProvider('catalogs')]
    public function test_missing_invalid_expired_and_forged_tokens(string $catalog): void
    {
        $before = $this->snapshot();
        $parts = explode('.', $this->token());
        $parts[2] = JWT::urlsafeB64Encode(str_repeat('x', 256));
        foreach ([null, 'broken', implode('.', $parts), $this->token('owner', ['exp' => 1])] as $token) {
            $this->getJson($this->url($catalog), $token === null ? [] : ['Authorization' => 'Bearer '.$token])
                ->assertUnauthorized()->assertJsonPath('error.code', 'UNAUTHENTICATED')
                ->assertHeader('WWW-Authenticate', 'Bearer')->assertHeader('Cache-Control', 'no-store, private')->assertHeader('X-Request-ID');
        }
        $this->assertSame($before, $this->snapshot());
    }

    public function test_search_scope_and_ids_intersect_without_leaking_other_universities(): void
    {
        $this->withToken($this->token());
        $this->getJson($this->url('universities', ['q' => 'ALPHA']))->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $this->ids['university']);
        $this->getJson($this->url('skills', ['q' => 'ART']))->assertJsonCount(1, 'data');
        $this->getJson($this->url('courses', ['q' => 'cs101']))->assertJsonCount(3, 'data');
        $expected = [$this->ids['course'], $this->ids['global']];
        sort($expected);
        $response = $this->getJson($this->url('courses', ['university_id' => strtoupper($this->ids['university']), 'q' => 'computing']))->assertOk();
        $this->assertSame($expected, array_column($response->json('data'), 'id'));
        $this->getJson($this->url('courses', ['university_id' => $this->ids['university'], 'q' => 'Beta']))->assertJsonPath('data', []);
        $this->getJson($this->url('courses', ['university_id' => $this->ids['university'], 'ids' => [$this->ids['otherCourse']]]))->assertJsonPath('data', []);
        $this->getJson($this->url('courses', ['university_id' => $this->ids['university'], 'ids' => [$this->ids['global']]]))->assertJsonPath('data.0.university_id', null);
        foreach (['universities' => 'university', 'courses' => 'course', 'skills' => 'skill'] as $catalog => $key) {
            $this->getJson($this->url($catalog, ['ids' => [strtoupper($this->ids[$key])]]))->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $this->ids[$key]);
            $this->getJson($this->url($catalog, ['ids' => [(string) Str::uuid()]]))->assertJsonPath('data', []);
            $this->getJson($this->url($catalog, ['q' => 'no such fixture']))->assertJsonPath('data', []);
            $this->getJson($this->url($catalog, ['q' => "%' OR 1=1 --"]))->assertJsonPath('data', []);
        }
    }

    #[DataProvider('catalogs')]
    public function test_invalid_queries_and_limits(string $catalog): void
    {
        $before = $this->snapshot();
        $this->withToken($this->token());
        $queries = [
            ['limit' => 0], ['limit' => 51], ['limit' => -1], ['limit' => '1.5'], ['limit' => 'abc'], ['limit' => ''], ['limit' => [1]],
            ['q' => str_repeat('x', 101)], ['q' => ['x']], ['ids' => 'bad'], ['ids' => ['bad']], ['ids' => [['id' => 'bad']]],
            ['ids' => ['key' => $this->ids['skill']]], ['ids' => [$this->ids['skill'], strtoupper($this->ids['skill'])]],
            ['ids' => array_map(fn () => (string) Str::uuid(), range(1, $catalog === 'universities' ? 51 : 101))], ['unknown' => 'value'],
        ];
        if ($catalog === 'courses') {
            $queries[] = ['university_id' => 'bad'];
            $queries[] = ['university_id' => (string) Str::uuid()];
            $queries[] = ['university_id' => ['bad']];
        }
        foreach ($queries as $query) {
            $this->getJson($this->url($catalog, $query))->assertUnprocessable()->assertJsonPath('error.code', 'VALIDATION_ERROR')
                ->assertJsonStructure(['error' => ['code', 'message', 'details'], 'request_id'])->assertHeader('Cache-Control', 'no-store, private');
        }
        $this->json('GET', $this->url($catalog), ['q' => 'body'])->assertUnprocessable();
        $this->assertSame($before, $this->snapshot());
    }

    #[DataProvider('catalogs')]
    public function test_bounded_default_limit_and_deterministic_order(string $catalog): void
    {
        $order = match ($catalog) {
            'universities' => 'name', 'courses' => 'code', default => 'normalized_name'
        };
        for ($i = 0; $i < 55; $i++) {
            $row = ['id' => (string) Str::uuid(), $order => sprintf('fixture%03d', $i)];
            if ($catalog === 'courses') {
                $row['code'] = strtoupper($row['code']);
                $row['name'] = 'Fixture course';
            }
            DB::table($catalog)->insert($row);
        }
        // Equal names/codes must use UUID as the secondary ordering key.
        if ($catalog === 'universities') {
            DB::table($catalog)->where('id', $this->ids['otherUniversity'])->update(['name' => 'Fixture Alpha']);
        }
        $this->withToken($this->token());
        $this->getJson($this->url($catalog))->assertJsonCount(20, 'data');
        foreach ([1, 50] as $limit) {
            $expected = DB::table($catalog)->orderBy($order)->orderBy('id')->limit($limit)->pluck('id')->all();
            for ($repeat = 0; $repeat < 2; $repeat++) {
                $response = $this->getJson($this->url($catalog, ['limit' => $limit]))->assertOk()->assertJsonCount($limit, 'data');
                $this->assertSame($expected, array_column($response->json('data'), 'id'));
            }
        }
    }

    public function test_literal_search_metacharacters_and_empty_catalogs(): void
    {
        DB::table('skills')->insert(['id' => (string) Str::uuid(), 'normalized_name' => 'fixture%_\\literal']);
        $this->withToken($this->token());
        foreach (['%', '_', '\\'] as $query) {
            $this->getJson($this->url('skills', ['q' => $query]))->assertJsonCount(1, 'data')->assertJsonPath('data.0.normalized_name', 'fixture%_\\literal');
        }
        DB::table('user_courses')->delete();
        DB::table('user_skills')->delete();
        foreach (['courses', 'skills', 'universities'] as $catalog) {
            DB::table($catalog)->delete();
            $this->getJson($this->url($catalog))->assertOk()->assertJsonPath('data', []);
        }
    }
}
