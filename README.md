# Medical Fluid Analyzer

Aplikasi Flutter untuk menampilkan dan menyimpan hasil analisis cairan medis (Glucose, Protein, Salinity), dengan koneksi USB serial ke ESP32 di Android.

## Unduh & pasang (Android)

### Opsi 1 — File APK siap pasang

Setelah proyek di-build, file instalasi ada di:

```
dist/MedicalFluidAnalyzer-v1.0.0.apk
```

**Cara pasang di HP:**

1. Salin file `.apk` ke ponsel (USB, Google Drive, WhatsApp, dll.).
2. Buka file APK di ponsel.
3. Izinkan **Install unknown apps** untuk aplikasi/file manager yang dipakai (jika diminta).
4. Tap **Install** → buka **Medical Fluid Analyzer**.

> APK release default ditandatangani dengan debug key (cukup untuk demo, sideload, dan tugas). Untuk Google Play Store, buat keystore release (lihat di bawah).

### Opsi 2 — Build APK sendiri

Di Windows (PowerShell), dari folder proyek:

```powershell
.\build.ps1
```

Perintah di atas menjalankan `flutter build apk --release` dan menyalin hasil ke folder `dist/`.

Tanpa skrip:

```powershell
flutter pub get
flutter build apk --release
```

Output asli Flutter: `build/app/outputs/flutter-apk/app-release.apk`

### Opsi 3 — Bagikan lewat GitHub Releases

1. Push proyek ke GitHub.
2. Jalankan `.\build.ps1` secara lokal.
3. Di repo GitHub: **Releases** → **Create a new release** → unggah `dist/MedicalFluidAnalyzer-v1.0.0.apk`.
4. Pengguna unduh APK dari halaman Release.

## Menjalankan untuk pengembangan

```powershell
.\run.ps1
```

Atau: `flutter run` (pilih perangkat Android).

## Fitur

- Pilih parameter: Glucose, Protein, Salinity
- Status: Rendah / Normal / Tinggi
- Riwayat pengukuran (SQLite)
- Export CSV
- USB serial (Android + OTG) — JSON dari ESP32, baud **115200**
- Simulasi pembacaan (tanpa hardware)

### Format data ESP32

```json
{"parameter":"Glucose","value":85.5}
```

`parameter` harus: `Glucose`, `Protein`, atau `Salinity`.

## Signing untuk Play Store (opsional)

1. Buat keystore:

   ```bash
   keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Salin `android/key.properties.example` → `android/key.properties` dan isi password/path.
3. Build ulang: `.\build.ps1`

File `key.properties` dan `*.jks` tidak ikut git (lihat `.gitignore`).

## Persyaratan

- Flutter SDK 3.x
- **Android SDK** (via [Android Studio](https://developer.android.com/studio)) — wajib untuk mem-build APK
- Setelah install SDK: `flutter doctor --android-licenses` lalu `flutter doctor` harus hijau untuk Android
- HP Android dengan **USB OTG** (untuk koneksi ESP32)

Jika `.\build.ps1` gagal dengan pesan *No Android SDK found*, install Android Studio terlebih dahulu.

## ID aplikasi

`id.hmj.medical_fluid_analyzer` — versi di `pubspec.yaml` (`version: 1.0.0+1`).
