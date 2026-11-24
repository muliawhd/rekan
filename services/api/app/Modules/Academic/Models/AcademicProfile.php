<?php

namespace App\Modules\Academic\Models;

use App\Modules\Identity\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

final class AcademicProfile extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $guarded = ['*'];

    protected $primaryKey = 'user_id';

    protected $attributes = ['visibility' => 'private'];

    protected function casts(): array
    {
        return ['semester' => 'integer'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
