<?php

namespace App\Modules\Academic\Models;

use App\Modules\Identity\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\Pivot;

final class UserCourse extends Pivot
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $guarded = ['*'];

    protected $table = 'user_courses';

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function course(): BelongsTo
    {
        return $this->belongsTo(Course::class);
    }
}
