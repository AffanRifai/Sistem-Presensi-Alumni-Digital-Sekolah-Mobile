# Dokumentasi Presensi Sholat

## Ringkasan

Fitur Presensi Sholat mencatat pelaksanaan sholat siswa menggunakan akun yang sedang login. Jadwal sholat tidak dihitung di Flutter, tetapi diambil Laravel dari API Jadwal Shalat EQuran.id dan disimpan sementara di cache backend.

Alur utama:

1. Siswa membuka menu **Presensi Sholat**.
2. Flutter meminta jadwal dan status hari ini ke Laravel.
3. Laravel mengambil jadwal kota sekolah dari EQuran.id.
4. Siswa mengirim presensi tanpa foto dan tanpa lokasi GPS.
5. Guru hanya melihat pengajuan siswa dari kelas yang diampunya.
6. Guru dapat menyetujui, menolak, memberi catatan opsional, atau memverifikasi seluruh pengajuan yang tampil.

## Arsitektur

```text
Flutter
  -> ApiClient + Bearer Token
Laravel API /api/v1
  -> PrayerAttendanceService
  -> PrayerScheduleService
EQuran.id API Jadwal Shalat

Laravel
  -> tabel prayer_attendances
  -> tabel schools (lokasi jadwal)
```

Flutter tidak mengakses EQuran.id secara langsung. Seluruh validasi waktu, hak akses, duplikasi, dan status presensi dilakukan oleh Laravel.

## Struktur Flutter

```text
lib/features/presensi_sholat/
|-- data/
|   |-- prayer_models.dart
|   `-- prayer_attendance_service.dart
|-- widgets/
|   `-- prayer_progress_card.dart
|-- presensi_sholat_page.dart
|-- prayer_attendance_form_page.dart
|-- teacher_prayer_verification_page.dart
|-- student_prayer_history_page.dart
`-- teacher_prayer_history_page.dart
```

| File | Fungsi |
|---|---|
| `prayer_models.dart` | Enum dan model JSON untuk jadwal, status, verifikasi, serta riwayat. |
| `prayer_attendance_service.dart` | Mengirim request terautentikasi ke endpoint Laravel. |
| `presensi_sholat_page.dart` | Menampilkan jadwal dan status sholat siswa hari ini. |
| `prayer_attendance_form_page.dart` | Konfirmasi submit presensi siswa. |
| `teacher_prayer_verification_page.dart` | Daftar pengajuan dari kelas yang diampu guru dan aksi verifikasi. |
| `student_prayer_history_page.dart` | Riwayat presensi akun siswa yang login. |
| `teacher_prayer_history_page.dart` | Riwayat siswa pada kelas yang dapat diakses guru. |

## Struktur Laravel

```text
app/
|-- Http/Controllers/Api/PrayerAttendanceController.php
|-- Http/Resources/PrayerAttendanceResource.php
|-- Models/PrayerAttendance.php
`-- Services/
    |-- PrayerAttendanceService.php
    `-- PrayerScheduleService.php

database/migrations/
|-- 2026_07_18_000001_add_prayer_location_to_schools_table.php
`-- 2026_07_18_000002_create_prayer_attendances_table.php
```

## Endpoint Laravel

Semua endpoint memakai middleware `auth:sanctum` dan prefix `/api/v1`.

| Method | Endpoint | Role | Fungsi |
|---|---|---|---|
| GET | `/prayer-attendances/today` | student | Jadwal dan status sholat hari ini. |
| POST | `/prayer-attendances` | student | Mengirim presensi satu jenis sholat. |
| GET | `/prayer-attendances/pending` | teacher | Pengajuan dari kelas yang diampu. |
| POST | `/prayer-attendances/{id}/verify` | teacher | Menyetujui/menolak satu pengajuan. |
| POST | `/prayer-attendances/verify-all` | teacher | Memverifikasi beberapa pengajuan. |
| GET | `/prayer-attendances/history` | student, teacher | Riwayat sesuai akses pengguna. |
| GET | `/prayer-attendances/{id}` | student, teacher | Detail presensi sesuai akses pengguna. |

Contoh submit siswa:

```json
{
  "prayer_type": "dzuhur"
}
```

Contoh verifikasi guru:

```json
{
  "approved": true,
  "note": "Sudah diverifikasi"
}
```

## Model Database

Tabel `prayer_attendances` menyimpan:

- sekolah, kelas, dan siswa;
- jenis sholat dan tanggal presensi;
- waktu jadwal dari EQuran.id;
- waktu siswa mengirim;
- status `pending`, `approved`, `rejected`, `late`, dan status sistem lainnya;
- guru yang memverifikasi, waktu verifikasi, dan catatan opsional.

Constraint unik `student_id + attendance_date + prayer_type` mencegah presensi ganda untuk siswa, tanggal, dan sholat yang sama.

## Jadwal Sholat EQuran.id

Laravel mengirim request bulanan ke:

```text
POST https://equran.id/api/v2/shalat
```

Payload:

```json
{
  "provinsi": "Jawa Barat",
  "kabkota": "Kota Bandung",
  "bulan": 7,
  "tahun": 2026
}
```

Field yang dipakai adalah `subuh`, `dzuhur`, `ashar`, `maghrib`, dan `isya`. Response bulanan di-cache agar aplikasi tidak memanggil layanan eksternal pada setiap pembukaan halaman.

## Konfigurasi Laravel

Tambahkan ke `.env` backend:

```env
EQURAN_PRAYER_URL=https://equran.id/api/v2/shalat
PRAYER_DEFAULT_PROVINCE="Jawa Barat"
PRAYER_DEFAULT_CITY="Kota Bandung"
PRAYER_SCHEDULE_CACHE_HOURS=24
PRAYER_ON_TIME_MINUTES=60
PRAYER_LATE_MINUTES=30
```

Lokasi pada kolom `schools.prayer_province` dan `schools.prayer_city` akan diprioritaskan. Nilai `.env` hanya menjadi fallback ketika lokasi sekolah belum diisi.

Kebijakan waktu default:

- waktu tepat waktu: mulai waktu sholat sampai 60 menit setelahnya;
- toleransi terlambat: 30 menit setelah periode tepat waktu;
- sebelum jadwal: belum dapat presensi;
- setelah toleransi: sesi berakhir.

Nilai durasi dapat diubah melalui `.env` tanpa mengubah kode.

## Instalasi Backend

Jalankan pada project Laravel:

```bash
php artisan migrate
php artisan optimize:clear
```

Untuk production:

```bash
php artisan migrate --force
php artisan optimize:clear
```

Pastikan server hosting dapat melakukan koneksi HTTPS keluar ke `equran.id`.

## Konfigurasi Flutter

`ApiConfig.baseUrl` harus menunjuk ke backend Laravel dan menyertakan `/api/v1`, misalnya:

```text
https://domain-backend.example/api/v1
```

Request Flutter otomatis memakai bearer token dari sesi login melalui `ApiClient`. Tidak diperlukan API key EQuran.id di Flutter.

## Hak Akses

- Siswa hanya dapat melihat dan mengirim presensi miliknya sendiri.
- Guru hanya dapat melihat dan memverifikasi siswa pada kelas yang diampunya.
- ID siswa atau kelas dari Flutter tidak dipercaya sebagai sumber otorisasi.
- Backend menolak pengajuan ganda dan akses lintas kelas.

## Validasi

Backend:

```bash
php artisan test tests/Feature/PrayerAttendanceApiTest.php
```

Flutter:

```bash
flutter test test/features/presensi_sholat/prayer_models_test.dart
dart analyze lib/features/presensi_sholat lib/features/home/home_page.dart
flutter build apk --debug
```

## Catatan Deployment

Perubahan Flutter saja tidak cukup. Endpoint, migration, dan konfigurasi Laravel pada dokumen ini harus ikut di-deploy. Jika backend hosting belum diperbarui, aplikasi akan menerima respons route tidak ditemukan atau tabel belum tersedia.
