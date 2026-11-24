<?php

namespace App\Modules\Academic\Models;

use App\Modules\Identity\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\Pivot;

final class UserSkill extends Pivot
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $guarded = ['*'];

    protected $fillable = ['level'];

    protected $table = 'user_skills';

    protected function casts(): array
    {
        return ['level' => 'integer'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function skill(): BelongsTo
    {
        return $this->belongsTo(Skill::class);
    }
}
