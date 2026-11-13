<?php

use App\Modules\Shared\Http\Controllers\HealthController;
use Illuminate\Support\Facades\Route;

Route::get('/v1/health', HealthController::class)->name('health');
Route::get('/health', HealthController::class)->name('health.alias');
