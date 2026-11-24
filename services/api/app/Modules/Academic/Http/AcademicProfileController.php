<?php

namespace App\Modules\Academic\Http;

use App\Modules\Academic\Models\AcademicPreference;
use App\Modules\Academic\Models\AcademicProfile;
use App\Modules\Academic\Models\Course;
use App\Modules\Identity\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

final class AcademicProfileController
{
    private const PROFILE_FIELDS = ['program', 'semester', 'bio', 'mbti_badge', 'visibility'];

    private const INPUT_FIELDS = ['display_name', 'university_id', 'program', 'semester', 'bio', 'mbti_badge', 'visibility', 'courses', 'skills', 'preferences'];

    public function show(Request $request): JsonResponse
    {
        if ($request->all() !== []) {
            return $this->error($request, 422, 'VALIDATION_ERROR', 'This endpoint accepts no parameters.');
        }
        try {
            return DB::transaction(function () use ($request) {
                $user = User::query()->whereKey($request->user()->id)->sharedLock()->firstOrFail();
                $profile = $this->profile($user);
                Gate::forUser($request->user())->authorize('view', $profile);

                return $this->response($request, $user, $profile);
            });
        } catch (QueryException) {
            return $this->error($request, 503, 'SERVICE_UNAVAILABLE', 'Profile service is temporarily unavailable.');
        }
    }

    public function update(Request $request): JsonResponse
    {
        // Complete PUT: all writable fields must be explicit, including null/empty values.
        $validator = Validator::make($request->all(), [
            'display_name' => ['present', 'nullable', 'string', 'max:100'],
            'university_id' => ['bail', 'present', 'nullable', 'uuid', Rule::exists('universities', 'id')],
            'program' => ['present', 'nullable', 'string', 'max:150'],
            'semester' => ['present', 'nullable', 'integer', 'between:1,20'],
            'bio' => ['present', 'nullable', 'string', 'max:2000'],
            'mbti_badge' => ['present', 'nullable', 'string', 'regex:/^[EI][NS][FT][JP]$/D'],
            'visibility' => ['required', Rule::in(['private', 'university', 'public'])],
            'courses' => ['present', 'array', 'list', 'max:100'],
            'courses.*' => ['bail', 'required', 'uuid', 'distinct:ignore_case', Rule::exists('courses', 'id')],
            'skills' => ['present', 'array', 'list', 'max:100'],
            'skills.*' => ['required', 'array:skill_id,level'],
            'skills.*.skill_id' => ['bail', 'required', 'uuid', 'distinct:ignore_case', Rule::exists('skills', 'id')],
            'skills.*.level' => ['required', 'integer', 'between:1,5'],
            'preferences' => ['required', 'array:study_mode,preferred_language'],
            'preferences.study_mode' => ['present', 'nullable', Rule::in(['online', 'in_person', 'hybrid'])],
            'preferences.preferred_language' => ['present', 'nullable', 'string', 'max:35', 'regex:/^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$/D'],
        ]);
        $validator->after(function ($validator) use ($request) {
            if (array_diff(array_keys($request->all()), self::INPUT_FIELDS)) {
                $validator->errors()->add('body', 'Unknown or protected fields are not accepted.');
            }
        });

        try {
            if ($validator->fails()) {
                return $this->error($request, 422, 'VALIDATION_ERROR', 'Invalid academic profile.', $validator->errors()->toArray());
            }
            $input = $validator->validated();
            $input['university_id'] = $input['university_id'] === null ? null : strtolower($input['university_id']);
            $input['courses'] = array_map('strtolower', $input['courses']);

            return DB::transaction(function () use ($request, $input) {
                // Serialize self-service writes, including relationship replacement.
                $user = User::query()->whereKey($request->user()->id)->lockForUpdate()->firstOrFail();
                $profile = $this->profile($user);
                Gate::forUser($request->user())->authorize('update', $profile);
                // Optional atomic precondition for the development validation client.
                // Ordinary profile edits retain their existing replacement contract.
                if ($request->hasHeader('X-Re-Require-Empty-Profile')) {
                    if ($request->header('X-Re-Require-Empty-Profile') !== 'true') {
                        return $this->error($request, 422, 'VALIDATION_ERROR', 'Invalid empty-profile precondition.');
                    }
                    $current = $this->response($request, $user, $profile)->getData(true)['data'];
                    $empty = $current['visibility'] === 'private'
                        && $current['courses'] === [] && $current['skills'] === [];
                    foreach (['display_name', 'university_id', 'program', 'semester', 'bio', 'mbti_badge'] as $field) {
                        $empty = $empty && $current[$field] === null;
                    }
                    $empty = $empty && $current['preferences']['study_mode'] === null
                        && $current['preferences']['preferred_language'] === null;
                    if (! $empty) {
                        return $this->error($request, 409, 'PROFILE_NOT_EMPTY', 'Existing academic data will not be overwritten.');
                    }
                }
                $courses = Course::query()->whereIn('id', $input['courses'])->sharedLock()->get();
                foreach ($courses as $course) {
                    if ($course->university_id !== null && $course->university_id !== $input['university_id']) {
                        return $this->error($request, 422, 'VALIDATION_ERROR', 'Invalid academic profile.', ['courses' => ['Courses must be global or belong to the selected university.']]);
                    }
                }
                if ($courses->count() !== count($input['courses'])) {
                    return $this->error($request, 409, 'REFERENCE_CONFLICT', 'A catalog reference changed. Reload and retry.');
                }
                $user->display_name = $input['display_name'];
                $user->university_id = $input['university_id'];
                $user->save();
                foreach (self::PROFILE_FIELDS as $field) {
                    $profile->$field = $input[$field];
                }
                $profile->save();
                $preferences = $user->academicPreference ?? new AcademicPreference;
                $preferences->user_id = $user->id;
                $preferences->study_mode = $input['preferences']['study_mode'];
                $preferences->preferred_language = $input['preferences']['preferred_language'];
                $preferences->save();
                $user->courses()->sync($input['courses']);
                $skills = [];
                foreach ($input['skills'] as $skill) {
                    $skills[strtolower($skill['skill_id'])] = ['level' => $skill['level']];
                }
                $user->skills()->sync($skills);
                $user->unsetRelations();

                return $this->response($request, $user, $profile);
            });
        } catch (QueryException $exception) {
            if (in_array((string) $exception->getCode(), ['23503', '23505'], true)) {
                return $this->error($request, 409, 'REFERENCE_CONFLICT', 'A catalog reference changed. Reload and retry.');
            }

            return $this->error($request, 503, 'SERVICE_UNAVAILABLE', 'Profile service is temporarily unavailable.');
        }
    }

    private function profile(User $user): AcademicProfile
    {
        $profile = $user->academicProfile ?? new AcademicProfile;
        $profile->user_id = $user->id;

        return $profile;
    }

    private function response(Request $request, User $user, AcademicProfile $profile): JsonResponse
    {
        $preferences = $user->academicPreference;
        // Explicit projection excludes status, internal timestamps and catalog metadata.
        $data = ['user_id' => $user->id, 'display_name' => $user->display_name, 'university_id' => $user->university_id];
        foreach (self::PROFILE_FIELDS as $field) {
            $data[$field] = $profile->$field;
        }
        $data['courses'] = $user->courses()->orderBy('courses.id')->pluck('courses.id')->all();
        $data['skills'] = $user->skills()->orderBy('skills.id')->get()->map(fn ($skill) => ['skill_id' => $skill->id, 'level' => $skill->pivot->level])->all();
        $data['preferences'] = ['study_mode' => $preferences?->study_mode, 'preferred_language' => $preferences?->preferred_language];

        return response()->json(['data' => $data, 'request_id' => $request->attributes->get('request_id')]);
    }

    private function error(Request $request, int $status, string $code, string $message, array $details = []): JsonResponse
    {
        return response()->json(['error' => ['code' => $code, 'message' => $message, 'details' => $details === [] ? (object) [] : $details], 'request_id' => $request->attributes->get('request_id')], $status);
    }
}
