<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;
use Mockery;
use RuntimeException;
use Tests\TestCase;

final class FoundationCheckTest extends TestCase
{
    public function test_checks_both_redis_connections_after_postgresql(): void
    {
        config(['database.default' => 'pgsql']);
        DB::shouldReceive('select')->once()->with('SELECT 1 AS foundation_check')->andReturn([]);
        foreach (['default', 'cache'] as $name) {
            $connection = Mockery::mock();
            $connection->shouldReceive('ping')->once()->andReturn('PONG');
            Redis::shouldReceive('connection')->once()->with($name)->andReturn($connection);
        }

        $this->artisan('foundation:check')->assertExitCode(0);
    }

    public function test_dependency_failure_returns_nonzero_without_leaking_exception_message(): void
    {
        config(['database.default' => 'pgsql']);
        DB::shouldReceive('select')->once()->andThrow(new RuntimeException('secret-password'));
        Redis::shouldReceive('connection')->never();

        $this->artisan('foundation:check')
            ->expectsOutput('Foundation dependency check failed: RuntimeException')
            ->doesntExpectOutputToContain('secret-password')
            ->assertExitCode(1);
    }
}
