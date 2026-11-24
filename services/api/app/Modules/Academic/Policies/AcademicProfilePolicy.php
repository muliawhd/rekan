<?php

namespace App\Modules\Academic\Policies;

use App\Modules\Academic\Models\AcademicProfile;
use App\Modules\Identity\Models\User;

final class AcademicProfilePolicy
{
    public function view(User $user, AcademicProfile $profile): bool
    {
        return $user->id === $profile->user_id;
    }

    public function update(User $user, AcademicProfile $profile): bool
    {
        return $this->view($user, $profile);
    }
}
