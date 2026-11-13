<?php

namespace App\Modules\Shared\Http\Controllers;

use Illuminate\Http\JsonResponse;

final class HealthController
{
    public function __invoke(): JsonResponse
    {
        // Liveness only: never expose versions, credentials, or dependency details.
        return response()->json(['status' => 'ok']);
    }
}
