<?php

namespace App\Modules\Identity;

use Firebase\JWT\JWK;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;

final class Jwks
{
    public function keys(string $kid): array
    {
        $url = config('supabase.jwks_url');
        $root = config('supabase.url');
        if (! is_string($root) || ! preg_match('~^https://[a-z0-9]+\.supabase\.co$~D', $root)
            || $url !== $root.'/auth/v1/.well-known/jwks.json') {
            throw new RuntimeException('Invalid identity configuration.');
        }
        $cacheKey = 'identity:jwks:'.hash('sha256', $url);
        $keys = Cache::get($cacheKey);
        if (is_array($keys) && isset($keys[$kid])) {
            return $keys;
        }

        // A project-wide atomic cooldown bounds unknown-kid traffic and rotation
        // refreshes. Never use stale keys after their five-minute cache expiry.
        if (! Cache::add($cacheKey.':refresh', true, 30)) {
            if (is_array($keys)) {
                return $keys;
            }
            throw new RuntimeException('Identity keys temporarily unavailable.');
        }
        $response = Http::acceptJson()->connectTimeout(2)->timeout(5)
            ->withOptions([
                'allow_redirects' => false,
                'verify' => config('supabase.ca_bundle') ?: true,
            ])->get($url);
        if (! $response->successful() || strlen($response->body()) > 65536) {
            throw new RuntimeException('Identity keys unavailable.');
        }
        $document = $response->json();
        if (! is_array($document) || ! isset($document['keys']) || ! is_array($document['keys'])
            || count($document['keys']) > 20) {
            throw new RuntimeException('Invalid identity key set.');
        }
        $keys = [];
        foreach ($document['keys'] as $key) {
            if (! is_array($key) || ! is_string($key['kid'] ?? null)
                || ! in_array($key['alg'] ?? null, ['RS256', 'ES256'], true)
                || ($key['kty'] ?? null) !== ($key['alg'] === 'RS256' ? 'RSA' : 'EC')
                || ($key['use'] ?? 'sig') !== 'sig'
                || (isset($key['key_ops']) && (! is_array($key['key_ops']) || ! in_array('verify', $key['key_ops'], true)))) {
                continue;
            }
            if (isset($keys[$key['kid']])) {
                throw new RuntimeException('Ambiguous identity key set.');
            }
            try {
                $parsed = JWK::parseKey($key);
            } catch (\Throwable) {
                throw new RuntimeException('Invalid identity key.');
            }
            if ($parsed !== null) {
                $keys[$key['kid']] = $parsed;
            }
        }
        if ($keys === []) {
            throw new RuntimeException('No supported identity signing keys.');
        }
        Cache::put($cacheKey, $keys, 300);

        return $keys;
    }
}
