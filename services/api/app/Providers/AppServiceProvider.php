<?php

namespace App\Providers;

use App\Modules\Academic\Models\AcademicProfile;
use App\Modules\Academic\Policies\AcademicProfilePolicy;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // Remove framework-merged password/session defaults. Identity is resolved
        // exclusively by verified Supabase middleware, not a Laravel login guard.
        config(['auth.guards' => [], 'auth.providers' => [], 'auth.passwords' => []]);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::policy(AcademicProfile::class, AcademicProfilePolicy::class);
    }
}
