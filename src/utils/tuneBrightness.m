function [best, riwayat] = tuneBrightness(img, ref, epochs, progressFcn)
% mencari target mean brightenFrequency.m yang hasilnya paling dekat dengan
% citra referensi (MSE terkecil = PSNR terbesar), memakai golden-section
% search seperti tunePassFilter.m.
%
% INPUT:
%   img         - citra yang dicerahkan, grayscale (2D) atau RGB (3D), uint8
%   ref         - citra referensi, ukuran dan jumlah kanal sama dengan img
%   epochs      - jumlah langkah penyempitan rentang
%   progressFcn - (opsional) @(fraksi, pesan), dipanggil tiap kandidat;
%                 mengembalikan true kalau pencarian harus dihentikan
%
% OUTPUT:
%   best    - struct kandidat terbaik:
%               .targetMean .mse .psnr
%               .dibatalkan : true kalau dihentikan lewat progressFcn
%   riwayat - semua kandidat yang dicoba, tiap baris [targetMean, mse, psnr]

if nargin < 4, progressFcn = []; end

if ~isequal(size(img), size(ref))
    error('tuneBrightness:ukuranBeda', ...
        'Ukuran/jumlah kanal citra dan referensi harus sama untuk tuning.');
end

T_RANGE = [0.01 1];     % rentang target mean (skala 0..1)

ref = double(ref);
totalEval = epochs + 2;
riwayat = zeros(0, 3);
batal = false;

% golden-section search: dua titik di dalam [a, b] dibandingkan, sisi yang
% lebih jelek dibuang, lalu satu titik baru dicoba
r  = (sqrt(5) - 1) / 2;
a  = T_RANGE(1);
b  = T_RANGE(2);
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
best = struct('targetMean', riwayat(idx, 1), 'mse', riwayat(idx, 2), ...
    'psnr', riwayat(idx, 3), 'dibatalkan', batal);

    % -----------------------------------------------------------------------
    function m = mseAt(t)
        % MSE hasil brightenFrequency (target mean t) terhadap referensi
        t = round(t * 1e4) / 1e4;
        selisih = double(brightenFrequency(img, t)) - ref;
        m = mean(selisih(:).^2);

        riwayat(end + 1, :) = [t, m, 10 * log10(255^2 / max(m, eps))];
        if ~isempty(progressFcn)
            pesan = sprintf('Kandidat %d/%d: target mean = %.4f, PSNR = %.2f dB', ...
                size(riwayat, 1), totalEval, t, riwayat(end, 3));
            batal = batal || progressFcn(min(1, size(riwayat, 1) / totalEval), pesan);
        end
    end
end
