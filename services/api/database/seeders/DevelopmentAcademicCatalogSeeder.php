<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Ramsey\Uuid\Uuid;
use RuntimeException;

/** Development fixtures only; no verified institution metadata or course affiliations. */
final class DevelopmentAcademicCatalogSeeder extends Seeder
{
    public const UNIVERSITIES = ['Telkom University', 'Universitas Indonesia', 'Institut Teknologi Bandung', 'Universitas Gadjah Mada'];

    public const COURSES = [
        'DEV-ALG' => 'Algoritma dan Pemrograman',
        'DEV-STR' => 'Struktur Data',
        'DEV-DB' => 'Basis Data',
        'DEV-NET' => 'Jaringan Komputer',
        'DEV-SE' => 'Rekayasa Perangkat Lunak',
        'DEV-IS' => 'Sistem Informasi',
        'DEV-AI' => 'Kecerdasan Buatan',
        'DEV-STAT' => 'Statistika',
    ];

    public const SKILLS = ['java', 'python', 'sql', 'flutter', 'ui/ux design', 'data analysis', 'machine learning', 'public speaking', 'project management', 'web development'];

    public function run(): void
    {
        $db = DB::connection();
        // Inspect the actual connection: --database must not bypass the guard.
        if (! app()->environment('local') || config('app.env') !== 'local'
            || $db->getDriverName() !== 'pgsql' || $db->getConfig('host') !== '127.0.0.1'
            || (string) $db->getConfig('port') !== '5433' || $db->getDatabaseName() !== 'rekan_local'
            || ! empty($db->getConfig('url'))) {
            throw new RuntimeException('Development catalog seeding requires local PostgreSQL at 127.0.0.1:5433/rekan_local without a DB URL.');
        }
        $counts = $db->transaction(function () use ($db) {
            // Universities have no unique name index. Serialize catalog writers;
            // ordinary SELECT readers remain unblocked.
            $db->statement('LOCK TABLE universities, courses, skills IN SHARE ROW EXCLUSIVE MODE');
            $counts = ['universities' => 0, 'courses' => 0, 'skills' => 0];
            $rows = [];
            foreach (self::UNIVERSITIES as $name) {
                $rows[] = ['universities', 'name', $name, ['name' => $name, 'verified_domains' => '[]']];
            }
            foreach (self::COURSES as $code => $name) {
                $rows[] = ['courses', 'name', $name, ['university_id' => null, 'code' => $code, 'name' => $name]];
            }
            foreach (self::SKILLS as $name) {
                $rows[] = ['skills', 'normalized_name', $name, ['normalized_name' => $name]];
            }
            foreach ($rows as [$table, $column, $name, $attributes]) {
                $id = (string) Uuid::uuid5(Uuid::NAMESPACE_URL, 'urn:rekan:development-catalog:v1:'.$table.':'.strtolower($name));
                $existing = $db->table($table);
                if ($table === 'courses') {
                    $existing->whereNull('university_id');
                }
                $existing->where(function ($query) use ($column, $name, $attributes, $table) {
                    $query->whereRaw('lower(btrim('.$column.')) = ?', [strtolower($name)]);
                    if ($table === 'courses') {
                        $query->orWhere('code', $attributes['code']);
                    }
                });
                // Never update even empty metadata or existing timestamps.
                if ($existing->exists()) {
                    continue;
                }
                if ($db->table($table)->where('id', $id)->exists()) {
                    throw new RuntimeException('Development fixture UUID collision; no catalog changes committed.');
                }
                $db->table($table)->insert(['id' => $id] + $attributes + ['created_at' => now(), 'updated_at' => now()]);
                $counts[$table]++;
            }

            return $counts;
        });
        $this->command?->info('Development fixtures inserted: '.json_encode($counts));
    }
}
