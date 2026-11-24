<?php

namespace App\Modules\Identity;

use Firebase\JWT\JWT;
use Illuminate\Support\Str;
use Throwable;
use UnexpectedValueException;

final class VerifySupabaseToken
{
    public function __construct(private Jwks $jwks) {}

    public function subject(string $token): string
    {
        // Header fields are untrusted hints used only for bounded key selection.
        if (strlen($token) > 16384 || ! preg_match('/^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/D', $token)) {
            throw new UnexpectedValueException('Invalid token.');
        }
        try {
            $header = json_decode(JWT::urlsafeB64Decode(explode('.', $token)[0]), true, 16, JSON_THROW_ON_ERROR);
        } catch (Throwable) {
            throw new UnexpectedValueException('Invalid token.');
        }
        if (! is_array($header) || ! in_array($header['alg'] ?? null, ['RS256', 'ES256'], true)
            || ! is_string($header['kid'] ?? null) || strlen($header['kid']) > 128 || $header['kid'] === ''
            || isset($header['crit']) || isset($header['jku']) || isset($header['jwk']) || isset($header['x5u'])) {
            throw new UnexpectedValueException('Invalid token.');
        }
        $keys = $this->jwks->keys($header['kid']);
        try {
            $claims = JWT::decode($token, $keys);
            $audience = $claims->aud ?? null;
            $audiences = is_array($audience) ? $audience : [$audience];
            if (($claims->iss ?? null) !== config('supabase.jwt_issuer')
                || config('supabase.jwt_issuer') !== config('supabase.url').'/auth/v1'
                || config('supabase.jwt_audience') !== 'authenticated'
                || ! in_array('authenticated', $audiences, true)
                || ! is_int($claims->exp ?? null) || $claims->exp <= time()
                || ! is_string($claims->sub ?? null) || ! Str::isUuid($claims->sub)
                || strtolower($claims->sub) === '00000000-0000-0000-0000-000000000000'
                || ($claims->role ?? null) !== 'authenticated') {
                throw new UnexpectedValueException('Invalid claims.');
            }

            return strtolower($claims->sub);
        } catch (Throwable) {
            throw new UnexpectedValueException('Invalid token.');
        }
    }
}
