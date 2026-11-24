<?php

namespace App\Modules\Academic\Models;

use App\Modules\Identity\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

final class Course extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $guarded = ['*'];

    public function university(): BelongsTo
    {
        return $this->belongsTo(University::class);
    }

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'user_courses')->using(UserCourse::class)->withTimestamps();
    }
}
