<?php

use App\Modules\Academic\Http\AcademicCatalogController;
use App\Modules\Academic\Http\AcademicProfileController;
use App\Modules\Identity\Http\AuthenticateSupabase;
use App\Modules\Identity\Http\MeController;
use App\Modules\Shared\Http\Controllers\HealthController;
use Illuminate\Support\Facades\Route;

Route::get('/v1/health', HealthController::class)->name('health');
Route::get('/health', HealthController::class)->name('health.alias');

Route::get('/v1/me', MeController::class)
    ->middleware(AuthenticateSupabase::class)->name('me');

Route::middleware(AuthenticateSupabase::class)->group(function () {
    Route::get('/v1/universities', [AcademicCatalogController::class, 'universities'])->name('catalog.universities');
    Route::get('/v1/courses', [AcademicCatalogController::class, 'courses'])->name('catalog.courses');
    Route::get('/v1/skills', [AcademicCatalogController::class, 'skills'])->name('catalog.skills');
    Route::get('/v1/me/academic-profile', [AcademicProfileController::class, 'show'])->name('academic-profile.show');
    Route::put('/v1/me/academic-profile', [AcademicProfileController::class, 'update'])->name('academic-profile.update');
});
