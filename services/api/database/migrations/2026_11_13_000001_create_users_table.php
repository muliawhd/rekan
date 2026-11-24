<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('status', 20)->default('pending');
            $table->timestampsTz();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
