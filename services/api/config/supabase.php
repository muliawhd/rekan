<?php

// Server-side Supabase Auth verification configuration.
// No secret/service-role key is required to verify public JWKS signatures.
return [
    'url' => env('SUPABASE_URL'),
    'jwt_issuer' => env('SUPABASE_JWT_ISSUER'),
    'jwks_url' => env('SUPABASE_JWKS_URL'),
    'jwt_audience' => env('SUPABASE_JWT_AUDIENCE', 'authenticated'),
    // Optional trusted CA bundle path for PHP installations without system CAs.
    'ca_bundle' => env('SUPABASE_CA_BUNDLE'),
];
