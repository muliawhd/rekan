<?php

namespace Tests\Feature;

use Database\Seeders\DevelopmentAcademicCatalogSeeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Ramsey\Uuid\Uuid;
use RuntimeException;
use Tests\TestCase;

final class DevelopmentAcademicCatalogSeederTest extends TestCase
{
    private bool $transactionStarted = false;

    protected function setUp(): void
    {
        parent::setUp();
        if (getenv('ACADEMIC_TEST_POSTGRES') !== '1') {
            $this->markTestSkipped('Requires isolated local PostgreSQL.');
        }
        $this->assertSame('pgsql', config('database.default'));
        $this->assertSame('127.0.0.1', DB::connection()->getConfig('host'));
        $this->assertSame('5433', (string) DB::connection()->getConfig('port'));
        $this->assertSame('rekan_local', DB::connection()->getDatabaseName());
        $this->assertEmpty(DB::connection()->getConfig('url'));
        DB::beginTransaction();
        $this->transactionStarted = true;
        $schema = 'seed_test_'.str_replace('-', '', (string) Str::uuid());
        DB::statement('CREATE SCHEMA '.$schema);
        DB::statement('SET LOCAL search_path TO '.$schema);
        (require database_path('migrations/2026_11_13_000001_create_users_table.php'))->up();
        (require database_path('migrations/2026_11_15_000001_create_academic_tables.php'))->up();
        // Simulate local only after isolation; the real environment stays unchanged.
        $this->app['env'] = 'local';
        config(['app.env' => 'local']);
    }

    protected function tearDown(): void
    {
        if ($this->transactionStarted) {
            DB::rollBack();
        }
        parent::tearDown();
    }

    private function snapshot(): array
    {
        $result = [];
        foreach (['universities', 'courses', 'skills', 'users', 'academic_profiles', 'academic_preferences', 'user_courses', 'user_skills'] as $table) {
            $result[$table] = DB::table($table)->get()->map(fn ($row) => json_encode($row))->sort()->values()->all();
        }

        return $result;
    }

    public function test_dataset_is_global_complete_and_idempotent_with_user_preservation(): void
    {
        $user = (string) Str::uuid();
        DB::table('users')->insert(['id' => $user, 'display_name' => 'Preserve me']);
        DB::table('academic_profiles')->insert(['user_id' => $user, 'bio' => 'Preserve profile']);
        $before = $this->snapshot();
        $this->seed(DevelopmentAcademicCatalogSeeder::class);
        $this->assertEqualsCanonicalizing(DevelopmentAcademicCatalogSeeder::UNIVERSITIES, DB::table('universities')->pluck('name')->all());
        $this->assertEqualsCanonicalizing(array_values(DevelopmentAcademicCatalogSeeder::COURSES), DB::table('courses')->pluck('name')->all());
        $this->assertEqualsCanonicalizing(DevelopmentAcademicCatalogSeeder::SKILLS, DB::table('skills')->pluck('normalized_name')->all());
        $this->assertSame(0, DB::table('courses')->whereNotNull('university_id')->count());
        $this->assertSame(0, DB::table('universities')->whereRaw("verified_domains <> '[]'::jsonb")->count());
        $after = $this->snapshot();
        foreach (array_diff(array_keys($before), ['universities', 'courses', 'skills']) as $table) {
            $this->assertSame($before[$table], $after[$table]);
        }
        $this->seed(DevelopmentAcademicCatalogSeeder::class);
        $this->assertSame($after, $this->snapshot());
    }

    public function test_existing_natural_keys_and_metadata_are_never_overwritten(): void
    {
        DB::table('universities')->insert(['id' => (string) Str::uuid(), 'name' => ' TELKOM UNIVERSITY ', 'verified_domains' => '["preserve.invalid"]']);
        DB::table('courses')->insert(['id' => (string) Str::uuid(), 'code' => 'DEV-ALG', 'name' => 'Existing curated name']);
        DB::table('courses')->insert(['id' => (string) Str::uuid(), 'code' => 'EXISTING', 'name' => 'Struktur Data']);
        DB::table('skills')->insert(['id' => (string) Str::uuid(), 'normalized_name' => 'java']);
        $before = $this->snapshot();
        $this->seed(DevelopmentAcademicCatalogSeeder::class);
        $after = $this->snapshot();
        foreach ($before as $table => $rows) {
            foreach ($rows as $row) {
                $this->assertContains($row, $after[$table]);
            }
        }
        $this->assertSame(4, DB::table('universities')->count());
        $this->assertSame(8, DB::table('courses')->count());
        $this->assertSame(10, DB::table('skills')->count());
    }

    public function test_non_local_environments_are_refused_even_with_force(): void
    {
        $before = $this->snapshot();
        foreach (['production', 'staging', 'testing'] as $environment) {
            $this->app['env'] = $environment;
            config(['app.env' => $environment]);
            try {
                $this->artisan('db:seed', ['--class' => DevelopmentAcademicCatalogSeeder::class, '--force' => true])->run();
                $this->fail('Non-local seed must be rejected.');
            } catch (RuntimeException $exception) {
                $this->assertStringContainsString('requires local PostgreSQL', $exception->getMessage());
            }
            $this->assertSame($before, $this->snapshot());
        }
    }

    public function test_uuid_collision_rolls_back_prior_inserts(): void
    {
        $id = (string) Uuid::uuid5(Uuid::NAMESPACE_URL, 'urn:rekan:development-catalog:v1:skills:web development');
        DB::table('skills')->insert(['id' => $id, 'normalized_name' => 'unrelated preserved record']);
        $before = $this->snapshot();
        try {
            $this->seed(DevelopmentAcademicCatalogSeeder::class);
            $this->fail('Collision must fail closed.');
        } catch (RuntimeException $exception) {
            $this->assertStringContainsString('UUID collision', $exception->getMessage());
        }
        $this->assertSame($before, $this->snapshot());
    }
}
