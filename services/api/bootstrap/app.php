<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Authentication and authorization are introduced in the identity phase.
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Only the public liveness endpoint is exposed in this phase.
    })->create();
