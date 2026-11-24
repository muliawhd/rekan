<?php

namespace App\Modules\Academic\Models;

use App\Modules\Identity\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

final class Skill extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $guarded = ['*'];

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'user_skills')->using(UserSkill::class)->withPivot('level')->withTimestamps();
    }
}
