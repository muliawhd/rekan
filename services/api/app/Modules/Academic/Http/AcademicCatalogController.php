<?php

namespace App\Modules\Academic\Http;

use App\Modules\Academic\Models\Course;
use App\Modules\Academic\Models\Skill;
use App\Modules\Academic\Models\University;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

final class AcademicCatalogController
{
    public function universities(Request $request): JsonResponse
    {
        return $this->catalog($request, University::query(), ['id', 'name'], ['name'], 'name', 50);
    }

    public function courses(Request $request): JsonResponse
    {
        return $this->catalog($request, Course::query(), ['id', 'university_id', 'code', 'name'], ['code', 'name'], 'code', 100, true);
    }

    public function skills(Request $request): JsonResponse
    {
        return $this->catalog($request, Skill::query(), ['id', 'normalized_name'], ['normalized_name'], 'normalized_name', 100);
    }

    private function catalog(Request $request, Builder $query, array $fields, array $searchFields, string $order, int $maxIds, bool $courses = false): JsonResponse
    {
        $rules = [
            'q' => ['nullable', 'string', 'max:100'],
            'limit' => ['sometimes', 'required', 'integer', 'between:1,50'],
            'ids' => ['sometimes', 'array', 'list', 'max:'.$maxIds],
            'ids.*' => ['bail', 'required', 'uuid', 'distinct:ignore_case'],
        ];
        if ($courses) {
            $rules['university_id'] = ['bail', 'nullable', 'uuid', Rule::exists('universities', 'id')];
        }
        $validator = Validator::make($request->query(), $rules);
        $validator->after(function ($validator) use ($request, $rules) {
            $hasBody = $request->getContent() !== '' && (! $request->isJson() || $request->json()->all() !== []);
            if (array_diff(array_keys($request->query()), array_keys($rules)) || $hasBody) {
                $validator->errors()->add('query', 'Only supported query parameters are accepted; request bodies are not supported.');
            }
        });

        try {
            if ($validator->fails()) {
                return $this->error($request, 422, 'VALIDATION_ERROR', 'Invalid catalog query.', $validator->errors()->toArray());
            }
            $input = $validator->validated();
            if ($courses && isset($input['university_id'])) {
                $query->where(fn (Builder $scope) => $scope->whereNull('university_id')->orWhere('university_id', strtolower($input['university_id'])));
            }
            if (array_key_exists('ids', $input)) {
                $query->whereIn('id', array_map('strtolower', $input['ids']));
            }
            if (isset($input['q'])) {
                // Treat LIKE metacharacters as literal search text, always bound as values.
                $pattern = '%'.str_replace(['\\', '%', '_'], ['\\\\', '\\%', '\\_'], $input['q']).'%';
                $query->where(function (Builder $search) use ($searchFields, $pattern) {
                    foreach ($searchFields as $field) {
                        $search->orWhere($field, 'ilike', $pattern);
                    }
                });
            }
            $data = $query->select($fields)->orderBy($order)->orderBy('id')->limit($input['limit'] ?? 20)
                ->get()->map(fn ($item) => $item->only($fields))->all();

            return response()->json(['data' => $data, 'request_id' => $request->attributes->get('request_id')]);
        } catch (QueryException) {
            return $this->error($request, 503, 'SERVICE_UNAVAILABLE', 'Catalog service is temporarily unavailable.');
        }
    }

    private function error(Request $request, int $status, string $code, string $message, array $details = []): JsonResponse
    {
        return response()->json(['error' => ['code' => $code, 'message' => $message, 'details' => $details === [] ? (object) [] : $details], 'request_id' => $request->attributes->get('request_id')], $status);
    }
}
