# Tugas 2 IF4073 Pemrosesan Citra Digital: Pemrosesan Citra dalam Ranah Frekuensi

Aplikasi berbasis MATLAB untuk memproses citra pada ranah frekuensi: penapisan low-pass dan high-pass, peningkatan kecerahan, restorasi derau periodik, dan restorasi motion blur. Seluruh fungsi transfer H(u,v) dan model degradasi dibangkitkan sendiri. MATLAB hanya dipakai untuk transformasi Fourier (`fft2`, `ifft2`, `fftshift`, `ifftshift`) dan operasi matriks.

Anggota kelompok:

| NIM | Nama |
| --- | --- |
| 13523104 | Muhammad Zahran Ramadhan Ardiana |
| 18223064 | Ahmad Evander Ruizhi Xavier |

## Deskripsi Singkat Program

Program mengimplementasikan lima metode sesuai spesifikasi tugas, seluruhnya dalam satu GUI (`FrequencyDomainApp`):

| Metode | Varian | Implementasi |
| --- | --- | --- |
| Image smoothing / blurring (low-pass) | ILPF, GLPF, BLPF | `src/pass_filters/` |
| High-pass filtering | IHPF, GHPF, BHPF | `src/pass_filters/` |
| Peningkatan kecerahan | Skala seluruh spektrum dengan satu faktor alpha dari komponen DC | `src/brightening/` |
| Restorasi derau periodik | Notch titik, notch garis, band-reject/band-pass Ideal, Gaussian, Butterworth | `src/notch_filter/`, `src/band_filters/`, `src/utils/` |
| Restorasi motion blur | PSF motion blur, inverse filtering, Wiener filtering | `src/motion_blur/` |

Semua metode memakai alur yang sama: citra di-pad 2x dengan zero-padding, `fft2`, `fftshift`, dikali H(u,v), `ifftshift`, `ifft2`, lalu dipotong ke ukuran semula. Restorasi motion blur memakai PSF pada ukuran citra asli tanpa padding. Citra grayscale dan berwarna (RGB) didukung; citra berwarna diproses per kanal.

Fitur GUI:

- Pemilihan citra uji resmi (beserta citra referensi) atau berkas citra lain lewat "Dari File...".
- Parameter filter dan model degradasi dapat diubah lewat GUI, dengan preview H(u,v) pada tab Filter H sebelum diterapkan.
- Tab Utama menampilkan citra masukan, hasil, referensi, spektrum Fourier ketiganya, tabel noise peaks, serta log langkah dengan PSNR dan MSE terhadap referensi.
- Tab Noise Peaks mendeteksi peak derau periodik pada spektrum, dan hasilnya dapat diisikan ke filter notch lewat tombol "Dari Peaks".
- Filter builder untuk notch/band: beberapa filter (Ideal, Gaussian, Butterworth, Band, Notch Line) digabung dalam mode reject atau pass.
- Tombol Tune mencari parameter terbaik terhadap citra referensi dengan golden-section search (diameter dan orde, target mean, K atau threshold).
- Langkah dapat dirantai, dengan Undo (hingga 20 langkah) dan Reset.

## Struktur Folder

```
FrequencyDomainApp.m          GUI dan titik masuk program
gui/
    AppState.m                kelas handle penyimpan state dan komponen GUI
    datasetIndex.m            pembaca struktur folder citra uji
src/
    applyFrequencyMethod.m    titik masuk semua metode (lowpass, highpass, brightness, notch, motion)
    pass_filters/             idealPass, gaussianPass, butterworthPass
    band_filters/             bandIdeal, bandGaussian, bandButterworth
    brightening/              brightenFrequency
    notch_filter/             notchLineFilter
    motion_blur/              motionBlurPSF, inverseFilter, wienerFilter
    utils/                    freqGrid, padImage2x, applyFrequencyFilter, buildFilter,
                              subtractNotchPattern, findNoisePeaks, plotNoisePeaks,
                              tunePassFilter, tuneBrightness, tuneMotionRestoration
02_citra_test_images/         citra uji resmi (kelompok B sampai F)
TestScriptDump/               skrip eksplorasi dan pengujian selama pengembangan
```

## Dependensi

- MATLAB R2025a atau lebih baru (teruji pada R2026a). Versi minimum ditentukan oleh properti `Theme` pada `uifigure` yang dipakai GUI.
- Image Processing Toolbox (`imregionalmax`, `rgb2gray`, `imshow`, `im2double`, `im2uint8`).

Fungsi penapisan dan restorasi bawaan MATLAB (`imgaussfilt`, `imfilter`, `fspecial`, `imsharpen`, `deconvwnr`, `wiener2`) tidak dipakai pada implementasi utama. Satu-satunya pemakaian ada di skrip eksplorasi `TestScriptDump/`.

## Tata Cara Menjalankan Program

1. Buka MATLAB, lalu arahkan *Current Folder* ke folder repositori ini (folder yang berisi `FrequencyDomainApp.m`).
2. Jalankan GUI:

   ```matlab
   FrequencyDomainApp
   ```

   Fungsi ini menambahkan `src/` dan `gui/` ke path secara otomatis dan membaca citra uji dari `02_citra_test_images/` relatif terhadap lokasi `FrequencyDomainApp.m`.
3. Di panel kiri, pilih kategori dan citra, lalu tekan **Muat Citra**.
4. Pilih metode, atur parameternya, lalu tekan **Terapkan**.

Penggunaan tiap metode:

| Metode | Parameter | Catatan |
| --- | --- | --- |
| Lowpass / Highpass | Bentuk (Ideal, Gaussian, Butterworth), diameter, orde n | Diameter memakai koordinat spektrum ter-pad 2x. Orde n hanya untuk Butterworth. |
| Brightness | Target mean (0 sampai 1) | Seluruh spektrum dikali alpha = target / rata-rata sekarang. |
| Notch / Band | Mode (reject atau pass), weight, daftar filter | Tekan **Find Noise Peaks**, lalu **Find**, dan pakai **Dari Peaks** pada card filter titik. Weight hanya untuk mode pass. |
| Motion Blur | Restorasi (Wiener atau Inverse), L, theta, K atau threshold | L dan theta terisi otomatis dari nama berkas (`_L19_A20`). |

Tekan **Tune** untuk mencari parameter terbaik terhadap citra referensi (hanya tersedia jika citra memiliki referensi). Hasil tuning hanya diisikan ke field parameter dan baru diterapkan setelah **Terapkan** ditekan.

## Data Uji

Citra uji berada di `02_citra_test_images/`:

| Folder | Bagian tugas |
| --- | --- |
| `B_smoothing_blurring_frequency` | Image smoothing / blurring |
| `C_high_pass_filtering_frequency` | High-pass filtering (tanpa referensi) |
| `D_brightness_frequency` | Peningkatan kecerahan |
| `E_periodic_noise_restoration` | Restorasi derau periodik |
| `F_motion_blur_restoration` | Restorasi motion blur |

Citra referensi dicocokkan otomatis dari subfolder `reference/` dengan nama berkas yang menjadi awalan nama citra masukan (misalnya `brick_gray_periodic_noise.png` dengan `brick_gray.png`).
