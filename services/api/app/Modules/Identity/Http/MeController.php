<?php

namespace App\Modules\Identity\Http;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class MeController
{
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'data' => ['id' => $user->id, 'status' => $user->status, 'created_at' => $user->created_at->toISOString()],
            'request_id' => $request->attributes->get('request_id'),
        ]);
    }
}
