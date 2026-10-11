function [best, riwayat] = tuneMotionRestoration(img, ref, restoration, L, theta, epochs, progressFcn)
% mencari parameter restorasi motion blur (K untuk Wiener, threshold untuk
% inverse) yang hasilnya paling dekat dengan citra referensi (MSE terkecil =
% PSNR terbesar). L dan theta tidak dicari: keduanya parameter blur yang
% sudah diketahui. Memakai golden-section search seperti tunePassFilter.m,
% tapi pada skala log10 karena K/threshold merentang beberapa orde.
%
% INPUT:
%   img         - citra blur, grayscale (2D) atau RGB (3D), uint8
%   ref         - citra referensi, ukuran dan jumlah kanal sama dengan img
%   restoration - 'wiener' atau 'inverse'
%   L, theta    - panjang dan sudut motion blur (lihat motionBlurPSF.m)
%   epochs      - jumlah langkah penyempitan rentang
%   progressFcn - (opsional) @(fraksi, pesan), dipanggil tiap kandidat;
%                 mengembalikan true kalau pencarian harus dihentikan
%
% OUTPUT:
%   best    - struct kandidat terbaik:
%               .value : K (wiener) atau threshold (inverse)
%               .mse .psnr
%               .dibatalkan : true kalau dihentikan lewat progressFcn
%   riwayat - semua kandidat yang dicoba, tiap baris [value, mse, psnr]

if nargin < 7, progressFcn = []; end

if ~isequal(size(img), size(ref))
    error('tuneMotionRestoration:ukuranBeda', ...
        'Ukuran/jumlah kanal citra dan referensi harus sama untuk tuning.');
end

% rentang pencarian dalam log10
switch lower(restoration)
    case 'wiener'
        logRange = [-5 0];      % K = 0.00001 .. 1
        restoreFcn = @(G, H, x) wienerFilter(G, H, x);
        nama = 'K';
    case 'inverse'
        logRange = [-4 0];      % threshold = 0.0001 .. 1
        restoreFcn = @(G, H, x) inverseFilter(G, H, x);
        nama = 'threshold';
    otherwise
        error('tuneMotionRestoration:restorasiTidakDikenal', ...
            'Metode restorasi tidak dikenal: %s. Pilih inverse atau wiener.', restoration);
end

% spektrum citra dan PSF cukup dihitung sekali
imgDouble = im2double(img);
[M, N, C] = size(imgDouble);
H = motionBlurPSF([M, N], L, theta);
G = cell(1, C);
for c = 1:C
    G{c} = fft2(imgDouble(:, :, c));
end

ref = double(ref);
totalEval = epochs + 2;
riwayat = zeros(0, 3);
batal = false;

% golden-section search: dua titik di dalam [a, b] dibandingkan, sisi yang
% lebih jelek dibuang, lalu satu titik baru dicoba
r  = (sqrt(5) - 1) / 2;
a  = logRange(1);
b  = logRange(2);
x1 = b - r * (b - a);   f1 = mseAt(x1);
x2 = a + r * (b - a);   f2 = mseAt(x2);

for langkah = 1:epochs
    if batal, break; end
    if f1 <= f2
        b = x2;  x2 = x1;  f2 = f1;
        x1 = b - r * (b - a);   f1 = mseAt(x1);
    else
        a = x1;  x1 = x2;  f1 = f2;
        x2 = a + r * (b - a);   f2 = mseAt(x2);
    end
end

% terbaik diambil dari semua kandidat yang pernah dicoba
[~, idx] = min(riwayat(:, 2));
best = struct('value', riwayat(idx, 1), 'mse', riwayat(idx, 2), ...
    'psnr', riwayat(idx, 3), 'dibatalkan', batal);

    % -----------------------------------------------------------------------
    function m = mseAt(logValue)
        % MSE hasil restorasi terhadap referensi; nilai dibulatkan 3 angka
        % penting supaya yang muncul di field sama dengan yang dihitung
        value = str2double(sprintf('%.3g', 10^logValue));

        se = 0;
        for k = 1:C
            res = real(ifft2(restoreFcn(G{k}, H, value)));
            res = double(im2uint8(max(0, min(1, res))));    % sama dengan applyFrequencyMethod
            selisih = res - ref(:, :, k);
            se = se + sum(selisih(:).^2);
        end
        m = se / numel(ref);

        riwayat(end + 1, :) = [value, m, 10 * log10(255^2 / max(m, eps))];
        if ~isempty(progressFcn)
            pesan = sprintf('Kandidat %d/%d: %s = %g, PSNR = %.2f dB', ...
                size(riwayat, 1), totalEval, nama, value, riwayat(end, 3));
            batal = batal || progressFcn(min(1, size(riwayat, 1) / totalEval), pesan);
        end
    end
end
