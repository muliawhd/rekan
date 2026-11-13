<?php

// Supabase owns identity. Do not enable Laravel password/session authentication.
// JWT verification and domain users belong to the next implementation phase.
return [
    'defaults' => ['guard' => null, 'passwords' => null],
    'guards' => [],
    'providers' => [],
    'passwords' => [],
];
