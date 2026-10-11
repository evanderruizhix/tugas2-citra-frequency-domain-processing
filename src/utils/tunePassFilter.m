function [best, riwayat] = tunePassFilter(img, ref, method, shape, epochs, nStart, progressFcn)
% mencari diameter (dan orde n untuk Butterworth) filter lowpass/highpass
% yang hasilnya paling dekat dengan citra referensi (MSE terkecil = PSNR
% terbesar), memakai golden-section search: rentang dipersempit tiap epoch
% ke arah kandidat yang lebih bagus.
%
% INPUT:
%   img         - citra yang difilter, grayscale (2D) atau RGB (3D), skala 0..255
%   ref         - citra referensi, ukuran dan jumlah kanal sama dengan img
%   method      - 'lowpass' atau 'highpass'
%   shape       - 'ideal' | 'gaussian' | 'butterworth'
%   epochs      - jumlah langkah penyempitan rentang per pencarian
%   nStart      - (opsional) orde n awal Butterworth, default 2
%   progressFcn - (opsional) @(fraksi, pesan), dipanggil tiap kandidat;
%                 mengembalikan true kalau pencarian harus dihentikan
%
% OUTPUT:
%   best    - struct kandidat terbaik:
%               .diameter .n .mse .psnr
%               .dibatalkan : true kalau dihentikan lewat progressFcn
%   riwayat - semua kandidat yang dicoba, tiap baris [diameter, n, mse, psnr]
%
% Butterworth: diameter dan n dicari bergantian (2 putaran), n dibatasi
% di 0.5..2.5. Diameter memakai koordinat spektrum ter-pad 2x, sama dengan
% applyFrequencyFilter.m, jadi PSNR di sini sama dengan PSNR setelah
% filter benar-benar diterapkan.

if nargin < 6 || isempty(nStart), nStart = 2; end
if nargin < 7, progressFcn = []; end

if ~isequal(size(img), size(ref))
    error('tunePassFilter:ukuranBeda', ...
        'Ukuran/jumlah kanal citra dan referensi harus sama untuk tuning.');
end

N_RANGE = [0.5 2.5];      % batas orde Butterworth

isLowPass = strcmpi(method, 'lowpass');
isButter  = strcmpi(shape, 'butterworth');
ref = double(ref);

% FFT citra ter-pad cukup dihitung sekali, tiap kandidat hanya ganti H
[imgPadded, origSize] = padImage2x(img);
sizePad = [size(imgPadded, 1), size(imgPadded, 2)];
nKanal  = size(img, 3);
F = cell(1, nKanal);
for c = 1:nKanal
    F{c} = fftshift(fft2(double(imgPadded(:, :, c))));
end

dRange = [1, round(sqrt(sum(sizePad.^2)))];   % sampai diagonal spektrum
nNow   = min(N_RANGE(2), max(N_RANGE(1), nStart));

if isButter
    nSearch = 4;        % diameter, n, diameter, n
else
    nSearch = 1;
end
totalEval = nSearch * (epochs + 2);
riwayat = zeros(0, 4);
batal = false;

dNow = golden(@(d) mseAt(d, nNow), dRange(1), dRange(2));
if isButter
    nNow = golden(@(n) mseAt(dNow, n), N_RANGE(1), N_RANGE(2));
    dNow = golden(@(d) mseAt(d, nNow), dRange(1), dRange(2));
    golden(@(n) mseAt(dNow, n), N_RANGE(1), N_RANGE(2));
end

% terbaik diambil dari semua kandidat yang pernah dicoba
[~, idx] = min(riwayat(:, 3));
best = struct('diameter', riwayat(idx, 1), 'n', riwayat(idx, 2), ...
    'mse', riwayat(idx, 3), 'psnr', riwayat(idx, 4), 'dibatalkan', batal);

    % -----------------------------------------------------------------------
    function m = mseAt(d, n)
        % MSE hasil filter (diameter d, orde n) terhadap referensi
        d = max(1, round(d));
        n = round(n * 100) / 100;

        entry = struct('type', lower(shape), 'u0', 0, 'v0', 0, ...
            'diameter', d, 'n', n, 'isLowPass', isLowPass);
        H = buildFilter(sizePad, entry);

        se = 0;
        for k = 1:nKanal
            g = real(ifft2(ifftshift(F{k} .* H)));
            g = g(1:origSize(1), 1:origSize(2));
            g = double(uint8(max(0, min(255, g))));     % sama dengan applyFrequencyFilter
            selisih = g - ref(:, :, k);
            se = se + sum(selisih(:).^2);
        end
        m = se / numel(ref);

        riwayat(end + 1, :) = [d, n, m, 10 * log10(255^2 / max(m, eps))];
        if ~isempty(progressFcn)
            pesan = sprintf('Kandidat %d/%d: D = %d, n = %.2f, PSNR = %.2f dB', ...
                size(riwayat, 1), totalEval, d, n, riwayat(end, 4));
            batal = batal || progressFcn(min(1, size(riwayat, 1) / totalEval), pesan);
        end
    end

    % -----------------------------------------------------------------------
    function x = golden(f, a, b)
        % golden-section search: dua titik di dalam [a, b] dibandingkan,
        % sisi yang lebih jelek dibuang, lalu satu titik baru dicoba
        r  = (sqrt(5) - 1) / 2;
        x1 = b - r * (b - a);   f1 = f(x1);
        x2 = a + r * (b - a);   f2 = f(x2);

        for langkah = 1:epochs
            if batal, break; end
            if f1 <= f2
                b = x2;  x2 = x1;  f2 = f1;
                x1 = b - r * (b - a);   f1 = f(x1);
            else
                a = x1;  x1 = x2;  f1 = f2;
                x2 = a + r * (b - a);   f2 = f(x2);
            end
        end

        if f1 <= f2
            x = x1;
        else
            x = x2;
        end
    end
end
