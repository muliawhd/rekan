<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Authentication and authorization are introduced in the identity phase.
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(function (AccessDeniedHttpException $exception, Request $request) {
            if ($request->attributes->has('request_id')) {
                return response()->json([
                    'error' => ['code' => 'FORBIDDEN', 'message' => 'Access denied.', 'details' => (object) []],
                    'request_id' => $request->attributes->get('request_id'),
                ], 403);
            }
        });
    })->create();
