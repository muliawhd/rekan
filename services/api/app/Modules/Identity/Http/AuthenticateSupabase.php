<?php

namespace App\Modules\Identity\Http;

use App\Modules\Identity\Models\User;
use App\Modules\Identity\VerifySupabaseToken;
use Closure;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;
use Throwable;
use UnexpectedValueException;

final class AuthenticateSupabase
{
    public function __construct(private VerifySupabaseToken $verifier) {}

    public function handle(Request $request, Closure $next): Response
    {
        $requestId = (string) Str::uuid();
        $request->attributes->set('request_id', $requestId);
        try {
            $limitKey = 'identity:ip:'.hash('sha256', $request->ip() ?? 'unknown');
            if (RateLimiter::tooManyAttempts($limitKey, 60)) {
                return $this->error(429, 'RATE_LIMITED', 'Too many requests.', $requestId)
                    ->header('Retry-After', (string) RateLimiter::availableIn($limitKey));
            }
            RateLimiter::hit($limitKey, 60);
            $authorization = $request->header('Authorization', '');
            if (! preg_match('/^Bearer ([^\s]+)$/iD', $authorization, $match)) {
                throw new UnexpectedValueException('Missing token.');
            }
            $subject = $this->verifier->subject($match[1]);
        } catch (UnexpectedValueException) {
            return $this->error(401, 'UNAUTHENTICATED', 'A valid access token is required.', $requestId)
                ->header('WWW-Authenticate', 'Bearer');
        } catch (Throwable) {
            return $this->error(503, 'AUTH_UNAVAILABLE', 'Authentication is temporarily unavailable.', $requestId);
        }

        try {
            // Primary-key uniqueness plus createOrFirst's conflict recovery makes
            // concurrent provisioning idempotent, without updating existing data.
            $user = User::query()->firstOrCreate(['id' => $subject]);
            if (! in_array($user->status, ['pending', 'verified'], true)) {
                return $this->error(403, 'FORBIDDEN', 'Access denied.', $requestId);
            }
        } catch (Throwable) {
            return $this->error(503, 'SERVICE_UNAVAILABLE', 'Account service is temporarily unavailable.', $requestId);
        }
        $request->setUserResolver(fn () => $user);
        try {
            $response = $next($request);
        } catch (AuthorizationException) {
            return $this->error(403, 'FORBIDDEN', 'Access denied.', $requestId);
        }

        $response->headers->set('X-Request-ID', $requestId);
        $response->headers->set('Cache-Control', 'no-store');

        return $response;
    }

    private function error(int $status, string $code, string $message, string $requestId): JsonResponse
    {
        return response()->json([
            'error' => ['code' => $code, 'message' => $message, 'details' => (object) []],
            'request_id' => $requestId,
        ], $status, ['X-Request-ID' => $requestId, 'Cache-Control' => 'no-store']);
    }
}
