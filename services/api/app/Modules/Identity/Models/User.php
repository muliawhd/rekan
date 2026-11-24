<?php

namespace App\Modules\Identity\Models;

use App\Modules\Academic\Models\AcademicPreference;
use App\Modules\Academic\Models\AcademicProfile;
use App\Modules\Academic\Models\Course;
use App\Modules\Academic\Models\Skill;
use App\Modules\Academic\Models\University;
use App\Modules\Academic\Models\UserCourse;
use App\Modules\Academic\Models\UserSkill;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

final class User extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = ['id'];

    protected $attributes = ['status' => 'pending'];

    public function university(): BelongsTo
    {
        return $this->belongsTo(University::class);
    }

    public function academicProfile(): HasOne
    {
        return $this->hasOne(AcademicProfile::class);
    }

    public function academicPreference(): HasOne
    {
        return $this->hasOne(AcademicPreference::class);
    }

    public function courses(): BelongsToMany
    {
        return $this->belongsToMany(Course::class, 'user_courses')->using(UserCourse::class)->withTimestamps();
    }

    public function skills(): BelongsToMany
    {
        return $this->belongsToMany(Skill::class, 'user_skills')->using(UserSkill::class)->withPivot('level')->withTimestamps();
    }
}
