<?php

namespace Tests\Feature;

use App\Modules\Academic\Models\AcademicProfile;
use App\Modules\Academic\Models\Course;
use App\Modules\Academic\Models\Skill;
use App\Modules\Academic\Models\University;
use App\Modules\Identity\Models\User;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

final class AcademicProfileApiTest extends TestCase
{
    private bool $transactionStarted = false;

    private static array $signer = [];

    private string $owner;

    private string $other;

    private string $university;

    private string $otherUniversity;

    private string $globalCourse;

    private string $course;

    private string $skill;

    private const ENDPOINT = '/api/v1/me/academic-profile';

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
        $schema = 'profile_test_'.str_replace('-', '', (string) Str::uuid());
        DB::statement('CREATE SCHEMA '.$schema);
        DB::statement('SET LOCAL search_path TO '.$schema);
        (require database_path('migrations/2026_11_13_000001_create_users_table.php'))->up();
        (require database_path('migrations/2026_11_15_000001_create_academic_tables.php'))->up();
        foreach (['owner', 'other', 'university', 'otherUniversity', 'globalCourse', 'course', 'skill'] as $field) {
            $this->$field = (string) Str::uuid();
        }
        DB::table('users')->insert([
            ['id' => $this->owner, 'status' => 'pending', 'display_name' => 'Existing owner', 'created_at' => now(), 'updated_at' => now()],
            ['id' => $this->other, 'status' => 'verified', 'display_name' => 'Other user', 'created_at' => now(), 'updated_at' => now()],
        ]);
        DB::table('universities')->insert([['id' => $this->university, 'name' => 'One'], ['id' => $this->otherUniversity, 'name' => 'Two']]);
        DB::table('courses')->insert([
            ['id' => $this->course, 'university_id' => $this->university, 'code' => 'CS101', 'name' => 'Local'],
            ['id' => $this->globalCourse, 'university_id' => null, 'code' => 'CS101', 'name' => 'Global'],
        ]);
        DB::table('skills')->insert(['id' => $this->skill, 'normalized_name' => 'dart']);
        if (self::$signer === []) {
            $key = openssl_pkey_new(['config' => base_path('tests/openssl.cnf'), 'private_key_type' => OPENSSL_KEYTYPE_RSA, 'private_key_bits' => 2048]);
            openssl_pkey_export($key, $pem, null, ['config' => base_path('tests/openssl.cnf')]);
            $details = openssl_pkey_get_details($key);
            self::$signer = ['pem' => $pem, 'jwk' => ['kty' => 'RSA', 'kid' => 'profile-fixture', 'alg' => 'RS256', 'use' => 'sig', 'n' => JWT::urlsafeB64Encode($details['rsa']['n']), 'e' => JWT::urlsafeB64Encode($details['rsa']['e'])]];
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

    private function token(?string $subject = null): string
    {
        return JWT::encode(['iss' => 'https://fixture.supabase.co/auth/v1', 'aud' => 'authenticated', 'role' => 'authenticated', 'sub' => $subject ?? $this->owner, 'exp' => time() + 300], self::$signer['pem'], 'RS256', 'profile-fixture');
    }

    private function payload(): array
    {
        return ['display_name' => 'Student', 'university_id' => $this->university, 'program' => 'Computing', 'semester' => 2, 'bio' => 'Study together', 'mbti_badge' => null, 'visibility' => 'private', 'courses' => [$this->course, $this->globalCourse], 'skills' => [['skill_id' => $this->skill, 'level' => 2]], 'preferences' => ['study_mode' => 'hybrid', 'preferred_language' => 'id']];
    }

    public function test_empty_precondition_rejects_existing_data_without_changes(): void
    {
        $before = $this->snapshot();
        $this->withToken($this->token())->withHeader('X-Re-Require-Empty-Profile', 'true')
            ->putJson(self::ENDPOINT, $this->payload())->assertStatus(409)
            ->assertJsonPath('error.code', 'PROFILE_NOT_EMPTY');
        $this->assertSame($before, $this->snapshot());
    }

    public function test_empty_precondition_allows_only_first_write(): void
    {
        DB::table('users')->where('id', $this->owner)->update(['display_name' => null]);
        $this->withToken($this->token())->withHeader('X-Re-Require-Empty-Profile', 'true')
            ->putJson(self::ENDPOINT, $this->payload())->assertOk();
        $before = $this->snapshot();
        $this->putJson(self::ENDPOINT, $this->payload())->assertStatus(409);
        $this->assertSame($before, $this->snapshot());
    }

    private function snapshot(): array
    {
        $result = [];
        foreach (['users', 'academic_profiles', 'academic_preferences', 'user_courses', 'user_skills'] as $table) {
            $result[$table] = DB::table($table)->orderBy($table === 'users' ? 'id' : 'user_id')->get()->toJson();
        }

        return $result;
    }

    public function test_get_default_is_private_and_does_not_create_profile_or_change_existing_users(): void
    {
        $before = $this->snapshot();
        $this->withToken($this->token())->getJson(self::ENDPOINT)->assertOk()
            ->assertJsonPath('data.user_id', $this->owner)->assertJsonPath('data.visibility', 'private')
            ->assertJsonPath('data.display_name', 'Existing owner')->assertJsonPath('data.courses', [])
            ->assertJsonPath('data.preferences.study_mode', null)->assertHeader('Cache-Control', 'no-store, private')->assertHeader('X-Request-ID');
        $this->assertSame($before, $this->snapshot());
        $this->getJson('/api/v1/me')->assertOk()->assertJsonPath('data.id', $this->owner)->assertJsonPath('data.status', 'pending')->assertJsonMissingPath('data.program');
    }

    public function test_create_update_replace_and_repeat_preserve_other_user_and_identity(): void
    {
        $otherBefore = DB::table('users')->where('id', $this->other)->first();
        $createdAt = DB::table('users')->where('id', $this->owner)->value('created_at');
        $payload = $this->payload();
        $this->withToken($this->token())->putJson(self::ENDPOINT, $payload)->assertOk()->assertJsonPath('data.semester', 2);
        $this->getJson(self::ENDPOINT)->assertOk()->assertJsonPath('data.skills.0.level', 2)->assertJsonPath('data.preferences.study_mode', 'hybrid');
        $payload['courses'] = [$this->globalCourse];
        $payload['skills'][0]['level'] = 5;
        $payload['bio'] = null;
        $this->putJson(self::ENDPOINT, $payload)->assertOk()->assertJsonPath('data.skills.0.level', 5)->assertJsonPath('data.bio', null);
        $this->putJson(self::ENDPOINT, $payload)->assertOk();
        $this->assertSame(1, DB::table('academic_profiles')->count());
        $this->assertSame(1, DB::table('academic_preferences')->count());
        $this->assertSame(1, DB::table('user_courses')->count());
        $this->assertSame(1, DB::table('user_skills')->count());
        $this->assertEquals($otherBefore, DB::table('users')->where('id', $this->other)->first());
        $this->assertSame($createdAt, DB::table('users')->where('id', $this->owner)->value('created_at'));
        $this->assertSame('pending', User::findOrFail($this->owner)->status);
        $payload['courses'] = [];
        $payload['skills'] = [];
        $payload['university_id'] = null;
        $this->putJson(self::ENDPOINT, $payload)->assertOk()->assertJsonPath('data.courses', [])->assertJsonPath('data.skills', []);
    }

    public function test_missing_and_invalid_jwt_cannot_read_or_write(): void
    {
        $before = $this->snapshot();
        $parts = explode('.', $this->token());
        $parts[2] = JWT::urlsafeB64Encode(str_repeat('x', 256));
        foreach ([null, 'broken', implode('.', $parts)] as $token) {
            $headers = $token === null ? [] : ['Authorization' => 'Bearer '.$token];
            $this->getJson(self::ENDPOINT, $headers)->assertUnauthorized()->assertJsonPath('error.code', 'UNAUTHENTICATED');
            $this->putJson(self::ENDPOINT, $this->payload(), $headers)->assertUnauthorized();
        }
        $this->assertSame($before, $this->snapshot());
    }

    public function test_ownership_policy_and_attempted_user_selection(): void
    {
        $this->withToken($this->token())->putJson(self::ENDPOINT, $this->payload())->assertOk();
        $profile = AcademicProfile::findOrFail($this->owner);
        $this->assertFalse(Gate::forUser(User::findOrFail($this->other))->allows('view', $profile));
        $this->assertFalse(Gate::forUser(User::findOrFail($this->other))->allows('update', $profile));
        $before = $this->snapshot();
        $this->withToken($this->token($this->other))->putJson(self::ENDPOINT, $this->payload() + ['user_id' => $this->owner])->assertUnprocessable();
        $this->getJson(self::ENDPOINT.'?user_id='.$this->owner)->assertUnprocessable();
        $this->getJson(self::ENDPOINT)->assertOk()->assertJsonPath('data.user_id', $this->other)->assertJsonPath('data.program', null);
        $this->assertSame($before, $this->snapshot());
    }

    public static function invalidInputs(): array
    {
        return [
            'unknown university' => ['university_id', '00000000-0000-4000-8000-000000000001'],
            'invalid university uuid' => ['university_id', 'bad'],
            'unknown course' => ['courses', ['00000000-0000-4000-8000-000000000001']],
            'unknown skill' => ['skills', [['skill_id' => '00000000-0000-4000-8000-000000000001', 'level' => 1]]],
            'semester' => ['semester', 21],
            'visibility' => ['visibility', 'everyone'],
            'mbti' => ['mbti_badge', 'XXXX'],
            'bio length' => ['bio', str_repeat('x', 2001)],
            'protected status' => ['status', 'verified'],
            'protected timestamp' => ['created_at', '2000-01-01'],
            'nested identity' => ['preferences', ['study_mode' => null, 'preferred_language' => null, 'user_id' => 'forged']],
            'invalid preference' => ['preferences', ['study_mode' => 'any', 'preferred_language' => null]],
            'invalid language' => ['preferences', ['study_mode' => null, 'preferred_language' => 'not a tag']],
            'course list shape' => ['courses', ['bad-key' => '00000000-0000-4000-8000-000000000001']],
        ];
    }

    #[DataProvider('invalidInputs')]
    public function test_invalid_input_cannot_change_data(string $field, mixed $value): void
    {
        $before = $this->snapshot();
        $payload = $this->payload();
        $payload[$field] = $value;
        $this->withToken($this->token())->putJson(self::ENDPOINT, $payload)->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR')->assertHeader('Cache-Control', 'no-store, private');
        $this->assertSame($before, $this->snapshot());
    }

    public function test_duplicates_missing_fields_and_foreign_university_courses_are_rejected(): void
    {
        $this->withToken($this->token());
        $before = $this->snapshot();
        $payload = $this->payload();
        $payload['courses'] = [$this->course, strtoupper($this->course)];
        $this->putJson(self::ENDPOINT, $payload)->assertUnprocessable();
        $payload = $this->payload();
        $payload['skills'][] = ['skill_id' => strtoupper($this->skill), 'level' => 4];
        $this->putJson(self::ENDPOINT, $payload)->assertUnprocessable();
        $payload = $this->payload();
        $payload['university_id'] = $this->otherUniversity;
        $this->putJson(self::ENDPOINT, $payload)->assertUnprocessable();
        $payload['university_id'] = null;
        $this->putJson(self::ENDPOINT, $payload)->assertUnprocessable();
        $this->putJson(self::ENDPOINT, ['bio' => 'Incomplete PUT'])->assertUnprocessable();
        $this->assertSame($before, $this->snapshot());
    }

    public function test_late_database_failure_rolls_back_all_tables(): void
    {
        $this->withToken($this->token())->putJson(self::ENDPOINT, $this->payload())->assertOk();
        DB::statement('ALTER TABLE user_skills ADD CONSTRAINT fixture_failure CHECK (level <> 4)');
        $before = $this->snapshot();
        $payload = $this->payload();
        $payload['display_name'] = 'Must roll back';
        $payload['program'] = 'Changed';
        $payload['courses'] = [];
        $payload['preferences']['study_mode'] = 'online';
        $payload['skills'][0]['level'] = 4;
        $response = $this->putJson(self::ENDPOINT, $payload)->assertStatus(503)->assertJsonPath('error.code', 'SERVICE_UNAVAILABLE');
        $response->assertDontSee('fixture_failure')->assertDontSee('SQLSTATE');
        $this->assertSame($before, $this->snapshot());
    }

    public function test_eloquent_relationships_cover_all_tables(): void
    {
        $this->withToken($this->token())->putJson(self::ENDPOINT, $this->payload())->assertOk();
        $user = User::findOrFail($this->owner);
        $this->assertSame($this->university, $user->university->id);
        $this->assertSame($this->owner, $user->academicProfile->user->id);
        $this->assertSame($this->owner, $user->academicPreference->user->id);
        $this->assertSame($this->owner, University::findOrFail($this->university)->users->first()->id);
        $this->assertSame($this->course, $user->university->courses->first()->id);
        $this->assertSame($this->university, Course::findOrFail($this->course)->university->id);
        $this->assertSame($this->owner, Course::findOrFail($this->course)->users->first()->id);
        $this->assertSame($this->owner, Skill::findOrFail($this->skill)->users->first()->id);
        $coursePivot = $user->courses->first()->pivot;
        $this->assertSame($this->owner, $coursePivot->user->id);
        $this->assertNotNull($coursePivot->course);
        $skillPivot = $user->skills->first()->pivot;
        $this->assertSame($this->owner, $skillPivot->user->id);
        $this->assertSame($this->skill, $skillPivot->skill->id);
    }
}
