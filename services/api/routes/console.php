<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Str;

Artisan::command('foundation:check', function () {
    try {
        if (config('database.default') !== 'pgsql') {
            throw new RuntimeException('PostgreSQL must be the configured database.');
        }
        DB::select('SELECT 1 AS foundation_check');
        $this->info('PostgreSQL: connected; SELECT 1 passed.');
        foreach (['default', 'cache'] as $connection) {
            $pong = Redis::connection($connection)->ping();
            if ($pong !== true && strtoupper((string) $pong) !== 'PONG') {
                throw new RuntimeException('Unexpected Redis response.');
            }
            $this->info("Redis {$connection}: PING passed.");
        }
    } catch (Throwable $exception) {
        // Connection exceptions may contain credentials. Report only their type.
        $this->error('Foundation dependency check failed: '.get_class($exception));

        return 1;
    }

    return 0;
})->purpose('Verify configured PostgreSQL and Redis connections without exposing credentials');

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('identity:check-local-user {uuid}', function () {
    if (config('app.env') !== 'local' || config('database.default') !== 'pgsql'
        || config('database.connections.pgsql.host') !== '127.0.0.1'
        || (string) config('database.connections.pgsql.port') !== '5433'
        || ! Str::isUuid($this->argument('uuid'))) {
        $this->error('Requires local PostgreSQL and a valid Supabase UUID.');

        return 1;
    }
    $count = DB::table('users')->where('id', strtolower($this->argument('uuid')))->count();
    $this->info('Matching local user records: '.$count);

    return $count === 1 ? 0 : 1;
})->purpose('Read-only development identity count; never prints credentials');
