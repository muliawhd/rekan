<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            throw new RuntimeException('The academic schema requires PostgreSQL.');
        }

        Schema::create('universities', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name', 200);
            $table->jsonb('verified_domains')->default('[]');
            $table->timestampsTz();
        });
        DB::statement("ALTER TABLE universities ADD CONSTRAINT universities_domains_array CHECK (jsonb_typeof(verified_domains) = 'array')");

        Schema::table('users', function (Blueprint $table) {
            $table->string('display_name', 100)->nullable();
            $table->foreignUuid('university_id')->nullable()->constrained()->restrictOnDelete();
            $table->index('university_id');
        });

        Schema::create('academic_profiles', function (Blueprint $table) {
            $table->foreignUuid('user_id')->primary()->constrained()->cascadeOnDelete();
            $table->string('program', 150)->nullable();
            $table->smallInteger('semester')->nullable();
            $table->string('bio', 2000)->nullable();
            $table->string('mbti_badge', 4)->nullable();
            $table->string('visibility', 20)->default('private');
            $table->timestampsTz();
        });
        DB::statement("ALTER TABLE academic_profiles ADD CONSTRAINT academic_profiles_semester_range CHECK (semester BETWEEN 1 AND 20), ADD CONSTRAINT academic_profiles_visibility_values CHECK (visibility IN ('private', 'university', 'public')), ADD CONSTRAINT academic_profiles_mbti_values CHECK (mbti_badge ~ '^[EI][NS][FT][JP]$')");

        Schema::create('courses', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('university_id')->nullable()->constrained()->restrictOnDelete();
            $table->string('code', 40);
            $table->string('name', 200);
            $table->timestampsTz();
            $table->unique(['university_id', 'code']);
        });
        DB::statement('CREATE UNIQUE INDEX courses_global_code_unique ON courses (code) WHERE university_id IS NULL');
        DB::statement('ALTER TABLE courses ADD CONSTRAINT courses_code_canonical CHECK (code = upper(btrim(code)) AND length(code) > 0)');

        Schema::create('skills', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('normalized_name', 100)->unique();
            $table->timestampsTz();
        });
        DB::statement('ALTER TABLE skills ADD CONSTRAINT skills_name_canonical CHECK (normalized_name = lower(btrim(normalized_name)) AND length(normalized_name) > 0)');

        Schema::create('user_skills', function (Blueprint $table) {
            $table->foreignUuid('user_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('skill_id')->constrained()->restrictOnDelete();
            $table->smallInteger('level');
            $table->timestampsTz();
            $table->primary(['user_id', 'skill_id']);
            $table->index('skill_id');
        });
        DB::statement('ALTER TABLE user_skills ADD CONSTRAINT user_skills_level_range CHECK (level BETWEEN 1 AND 5)');

        Schema::create('user_courses', function (Blueprint $table) {
            $table->foreignUuid('user_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('course_id')->constrained()->restrictOnDelete();
            $table->timestampsTz();
            $table->primary(['user_id', 'course_id']);
            $table->index('course_id');
        });

        Schema::create('academic_preferences', function (Blueprint $table) {
            $table->foreignUuid('user_id')->primary()->constrained()->cascadeOnDelete();
            $table->string('study_mode', 20)->nullable();
            $table->string('preferred_language', 35)->nullable();
            $table->timestampsTz();
        });
        DB::statement("ALTER TABLE academic_preferences ADD CONSTRAINT academic_preferences_mode_values CHECK (study_mode IN ('online', 'in_person', 'hybrid')), ADD CONSTRAINT academic_preferences_language_format CHECK (preferred_language ~ '^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$')");
    }

    public function down(): void
    {
        Schema::dropIfExists('academic_preferences');
        Schema::dropIfExists('user_courses');
        Schema::dropIfExists('user_skills');
        Schema::dropIfExists('skills');
        Schema::dropIfExists('courses');
        Schema::dropIfExists('academic_profiles');
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['university_id']);
            $table->dropIndex(['university_id']);
            $table->dropColumn(['display_name', 'university_id']);
        });
        Schema::dropIfExists('universities');
    }
};
