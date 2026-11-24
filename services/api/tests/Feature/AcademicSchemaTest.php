<?php

namespace Tests\Feature;

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

final class AcademicSchemaTest extends TestCase
{
    private bool $transactionStarted = false;

    private string $user;

    private string $university;

    private string $course;

    private string $skill;

    protected function setUp(): void
    {
        parent::setUp();
        if (getenv('ACADEMIC_TEST_POSTGRES') !== '1') {
            $this->markTestSkipped('Set ACADEMIC_TEST_POSTGRES=1 for isolated local PostgreSQL schema tests.');
        }
        $this->assertSame('pgsql', config('database.default'));
        $this->assertSame('127.0.0.1', config('database.connections.pgsql.host'));
        $this->assertSame('5433', (string) config('database.connections.pgsql.port'));
        $this->assertEmpty(config('database.connections.pgsql.url'));
        DB::beginTransaction();
        $this->transactionStarted = true;
        $schema = 'academic_test_'.str_replace('-', '', (string) Str::uuid());
        DB::statement('CREATE SCHEMA '.$schema);
        DB::statement('SET LOCAL search_path TO '.$schema);
        (require database_path('migrations/2026_11_13_000001_create_users_table.php'))->up();
        $this->user = (string) Str::uuid();
        DB::table('users')->insert(['id' => $this->user, 'status' => 'pending']);
        $this->migration()->up();
        $this->university = (string) Str::uuid();
        $this->course = (string) Str::uuid();
        $this->skill = (string) Str::uuid();
        DB::table('universities')->insert(['id' => $this->university, 'name' => 'Fixture University']);
        DB::table('courses')->insert(['id' => $this->course, 'code' => 'CS101', 'name' => 'Fixture Course']);
        DB::table('skills')->insert(['id' => $this->skill, 'normalized_name' => 'dart']);
    }

    protected function tearDown(): void
    {
        if ($this->transactionStarted) {
            DB::rollBack();
        }
        parent::tearDown();
    }

    private function migration(): Migration
    {
        return require database_path('migrations/2026_11_15_000001_create_academic_tables.php');
    }

    public function test_existing_identity_survives_migration_rollback_and_reapply(): void
    {
        $this->assertSame('pending', DB::table('users')->where('id', $this->user)->value('status'));
        $this->assertNull(DB::table('users')->where('id', $this->user)->value('university_id'));
        $this->migration()->down();
        $this->assertSame(1, DB::table('users')->count());
        $this->assertFalse(Schema::hasColumn('users', 'display_name'));
        foreach (['universities', 'academic_profiles', 'courses', 'skills', 'user_skills', 'user_courses', 'academic_preferences'] as $table) {
            $this->assertFalse(Schema::hasTable($table));
        }
        $this->migration()->up();
        $this->assertSame(1, DB::table('users')->count());
    }

    public function test_profile_defaults_pivots_and_user_deletion(): void
    {
        DB::table('users')->where('id', $this->user)->update(['university_id' => $this->university]);
        DB::table('academic_profiles')->insert(['user_id' => $this->user, 'semester' => 20, 'mbti_badge' => 'INTJ']);
        DB::table('academic_preferences')->insert(['user_id' => $this->user]);
        $this->assertNull(DB::table('academic_preferences')->value('study_mode'));
        DB::table('user_courses')->insert(['user_id' => $this->user, 'course_id' => $this->course]);
        DB::table('user_skills')->insert(['user_id' => $this->user, 'skill_id' => $this->skill, 'level' => 5]);
        $this->assertSame('private', DB::table('academic_profiles')->value('visibility'));
        DB::table('users')->where('id', $this->user)->delete();
        foreach (['academic_profiles', 'academic_preferences', 'user_courses', 'user_skills'] as $table) {
            $this->assertSame(0, DB::table($table)->count());
        }
        $this->assertSame(1, DB::table('courses')->count());
        $this->assertSame(1, DB::table('skills')->count());
    }

    public function test_course_codes_are_scoped_to_university_including_global_scope(): void
    {
        DB::table('courses')->insert(['id' => (string) Str::uuid(), 'university_id' => $this->university, 'code' => 'CS101', 'name' => 'Scoped']);
        $this->assertSame(2, DB::table('courses')->count());
        $this->expectException(QueryException::class);
        DB::table('courses')->insert(['id' => (string) Str::uuid(), 'code' => 'CS101', 'name' => 'Duplicate global']);
    }

    public static function invalidRows(): array
    {
        return [
            'study mode' => ['academic_preferences', ['study_mode' => 'anywhere']],
            'language format' => ['academic_preferences', ['preferred_language' => 'not a language']],
            'semester zero' => ['academic_profiles', ['semester' => 0]],
            'semester high' => ['academic_profiles', ['semester' => 21]],
            'visibility' => ['academic_profiles', ['visibility' => 'everyone']],
            'mbti' => ['academic_profiles', ['mbti_badge' => 'XXXX']],
            'foreign user' => ['academic_profiles', ['user_id' => '00000000-0000-4000-8000-000000000001']],
            'level zero' => ['user_skills', ['level' => 0]],
            'level high' => ['user_skills', ['level' => 6]],
            'unknown skill' => ['user_skills', ['skill_id' => '00000000-0000-4000-8000-000000000001']],
            'unknown course' => ['user_courses', ['course_id' => '00000000-0000-4000-8000-000000000001']],
            'unnormalized skill' => ['skills', ['normalized_name' => ' Dart ']],
            'duplicate skill' => ['skills', ['normalized_name' => 'dart']],
            'unnormalized course' => ['courses', ['code' => ' cs101 ']],
            'domains object' => ['universities', ['verified_domains' => '{}']],
        ];
    }

    #[DataProvider('invalidRows')]
    public function test_database_rejects_invalid_rows(string $table, array $overrides): void
    {
        $row = match ($table) {
            'academic_profiles', 'academic_preferences' => ['user_id' => $this->user],
            'user_skills' => ['user_id' => $this->user, 'skill_id' => $this->skill, 'level' => 1],
            'user_courses' => ['user_id' => $this->user, 'course_id' => $this->course],
            'skills' => ['id' => (string) Str::uuid(), 'normalized_name' => 'php'],
            'courses' => ['id' => (string) Str::uuid(), 'name' => 'Fixture', 'code' => 'CS102'],
            'universities' => ['id' => (string) Str::uuid(), 'name' => 'Fixture'],
        };
        $this->expectException(QueryException::class);
        DB::table($table)->insert(array_replace($row, $overrides));
    }

    public static function duplicatePivots(): array
    {
        return [['user_courses'], ['user_skills'], ['academic_profiles'], ['academic_preferences']];
    }

    #[DataProvider('duplicatePivots')]
    public function test_duplicate_user_associations_are_rejected(string $table): void
    {
        $row = ['user_id' => $this->user];
        if ($table === 'user_courses') {
            $row['course_id'] = $this->course;
        } elseif ($table === 'user_skills') {
            $row += ['skill_id' => $this->skill, 'level' => 1];
        }
        DB::table($table)->insert($row);
        $this->expectException(QueryException::class);
        DB::table($table)->insert($row);
    }

    public function test_referenced_catalog_cannot_be_deleted(): void
    {
        DB::table('user_courses')->insert(['user_id' => $this->user, 'course_id' => $this->course]);
        $this->expectException(QueryException::class);
        DB::table('courses')->where('id', $this->course)->delete();
    }
}
