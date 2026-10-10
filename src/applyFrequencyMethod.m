function [result, methodName, paramText, extra] = applyFrequencyMethod(img, method, params)
% applyFrequencyMethod - titik masuk tunggal semua metode ranah frekuensi
%
% img    : citra grayscale (2D) atau RGB (3D), uint8
% method : 'lowpass' | 'highpass' | 'brightness' | 'notch' | 'motion'
% params : struct field sesuai metode (lihat daftar di bawah)
%
% result     : citra hasil (uint8, dimensi sama dengan img)
% methodName : nama metode yang benar-benar dipakai (untuk log/laporan)
% paramText  : string parameter efektif yang dipakai (untuk log/laporan)
% extra      : struct pelengkap untuk tampilan GUI
%                .H            : filter terpusat yang dipakai ([] kalau tidak ada)
%                .noisePattern : pola noise yang dikurangkan (notch mode pass saja)
%
% Daftar field params per method:
%   lowpass / highpass  .shape .diameter .n
%                       shape 'ideal' | 'gaussian' | 'butterworth' (.n hanya butterworth)
%   brightness          .targetMean            % target rata-rata kecerahan 0..1
%   notch               .filterList .mode .weight
%                       filterList : cell array of struct (lihat buildFilter.m)
%                       mode 'reject' : F .* H
%                       mode 'pass'   : citra - weight * pola noise (subtractNotchPattern.m)
%   motion              .restoration .L .theta .threshold .K
%                       restoration 'inverse' : .threshold (batas minimum |H|)
%                       restoration 'wiener'  : .K (noise-to-signal ratio)
%
% Filter lowpass/highpass/notch dibangun pada ukuran citra ter-pad 2x, jadi
% diameter dan posisi (u, v) memakai koordinat spektrum ter-pad.

if nargin < 2 || isempty(method)
    error('applyFrequencyMethod:metodeKosong', 'Metode belum dipilih.');
end

if ~isstruct(params)
    error('applyFrequencyMethod:paramsBukanStruct', 'Parameter metode harus berupa struct.');
end

extra = struct('H', [], 'noisePattern', []);

switch lower(method)
    case {'lowpass', 'highpass'}
        [result, methodName, paramText, extra] = applyPassFilter(img, lower(method), params, extra);

    case 'brightness'
        [result, methodName, paramText] = applyBrightness(img, params);

    case 'notch'
        [result, methodName, paramText, extra] = applyNotch(img, params, extra);

    case 'motion'
        [result, methodName, paramText, extra] = applyMotionRestoration(img, params, extra);

    otherwise
        error('applyFrequencyMethod:metodeTidakDikenal', 'Metode tidak dikenal: %s', method);
end

% jaga-jaga: keluaran harus sejenis dan seukuran dengan masukan
validateattributes(result, {'uint8'}, {'size', size(img)}, ...
    'applyFrequencyMethod', 'result');
end

% ---------------------------------------------------------------------------
function [result, methodName, paramText, extra] = applyPassFilter(img, method, params, extra)

shape    = lower(getText(params, 'shape', 'gaussian'));
diameter = getScalar(params, 'diameter', []);
if isempty(diameter)
    error('applyFrequencyMethod:paramKurang', 'Filter %s butuh parameter .diameter.', method);
end
checkPositiveScalar(diameter, 'diameter');

isLowPass = strcmp(method, 'lowpass');
entry = struct('type', shape, 'u0', 0, 'v0', 0, ...
    'diameter', diameter, 'isLowPass', isLowPass);
paramText = sprintf('diameter = %g (D0 = %g)', diameter, diameter / 2);

switch shape
    case {'ideal', 'gaussian'}
        % tidak ada parameter tambahan
    case 'butterworth'
        n = getScalar(params, 'n', []);
        if isempty(n)
            error('applyFrequencyMethod:paramKurang', 'Filter Butterworth butuh parameter .n (orde).');
        end
        checkPositiveScalar(n, 'n');
        entry.n = n;
        paramText = sprintf('%s, n = %g', paramText, n);
    otherwise
        error('applyFrequencyMethod:bentukTidakDikenal', ...
            'Bentuk filter tidak dikenal: %s. Pilih ideal, gaussian, atau butterworth.', shape);
end

extra.H = buildFilter(paddedSize(img), entry);
result  = applyFrequencyFilter(img, extra.H);

methodName = sprintf('%s Filter - %s', capitalize(method), capitalize(shape));
end

% ---------------------------------------------------------------------------
function [result, methodName, paramText] = applyBrightness(img, params)

targetMean = getScalar(params, 'targetMean', []);
if isempty(targetMean)
    error('applyFrequencyMethod:paramKurang', 'Brightness butuh parameter .targetMean.');
end
if targetMean <= 0 || targetMean > 1
    error('applyFrequencyMethod:targetLuarBatas', ...
        'Target mean harus di antara 0 dan 1, sekarang %g.', targetMean);
end

result = brightenFrequency(img, targetMean);
methodName = 'Brightness - skala spektrum (alpha global)';
paramText  = sprintf('target mean = %.4f', targetMean);
end

% ---------------------------------------------------------------------------
function [result, methodName, paramText, extra] = applyNotch(img, params, extra)

filterList = getValue(params, 'filterList', {});
mode       = lower(getText(params, 'mode', 'reject'));
weight     = getScalar(params, 'weight', 1);

if isempty(filterList)
    error('applyFrequencyMethod:filterKosong', ...
        'Belum ada filter. Tambah minimal satu filter lewat "Add Filter".');
end

switch mode
    case 'reject'
        extra.H = buildFilter(paddedSize(img), filterList, 'reject');
        result  = applyFrequencyFilter(img, extra.H);
        methodName = 'Notch/Band Filter - reject';
        paramText  = describeFilterList(filterList);

    case 'pass'
        if weight < 0
            error('applyFrequencyMethod:weightNegatif', 'Weight tidak boleh negatif.');
        end
        extra.H = buildFilter(paddedSize(img), filterList, 'pass');

        % pola noise diambil lewat notch pass, lalu dikurangkan dari citra
        [imgPadded, origSize] = padImage2x(img);
        result = zeros(size(img), 'uint8');
        extra.noisePattern = zeros(size(img));
        for c = 1:size(img, 3)
            [result(:, :, c), extra.noisePattern(:, :, c)] = subtractNotchPattern( ...
                img(:, :, c), imgPadded(:, :, c), extra.H, origSize, weight);
        end
        methodName = 'Notch/Band Filter - pass (pola noise dikurangkan)';
        paramText  = sprintf('weight = %g; %s', weight, describeFilterList(filterList));

    otherwise
        error('applyFrequencyMethod:modeTidakDikenal', ...
            'Mode notch tidak dikenal: %s. Pilih reject atau pass.', mode);
end
end

% ---------------------------------------------------------------------------
function [result, methodName, paramText, extra] = applyMotionRestoration(img, params, extra)

restoration = lower(getText(params, 'restoration', 'wiener'));
L     = getScalar(params, 'L', []);
theta = getScalar(params, 'theta', []);
if isempty(L) || isempty(theta)
    error('applyFrequencyMethod:paramKurang', ...
        'Restorasi motion blur butuh parameter .L (panjang) dan .theta (sudut).');
end
checkPositiveScalar(L, 'L');

imgDouble = im2double(img);
[M, N, C] = size(imgDouble);
H = motionBlurPSF([M, N], L, theta);

switch restoration
    case 'inverse'
        threshold = getScalar(params, 'threshold', 0.01);
        checkPositiveScalar(threshold, 'threshold');
        restoreFcn = @(G) inverseFilter(G, H, threshold);
        methodName = 'Motion Blur Restoration - inverse filtering';
        paramText  = sprintf('L = %g, theta = %g, threshold = %g', L, theta, threshold);

    case 'wiener'
        K = getScalar(params, 'K', 0.01);
        if K < 0
            error('applyFrequencyMethod:kNegatif', 'K (NSR) tidak boleh negatif.');
        end
        restoreFcn = @(G) wienerFilter(G, H, K);
        methodName = 'Motion Blur Restoration - Wiener filtering';
        paramText  = sprintf('L = %g, theta = %g, K = %g', L, theta, K);

    otherwise
        error('applyFrequencyMethod:restorasiTidakDikenal', ...
            'Metode restorasi tidak dikenal: %s. Pilih inverse atau wiener.', restoration);
end

restored = zeros(M, N, C);
for c = 1:C
    G = fft2(imgDouble(:, :, c));
    res = real(ifft2(restoreFcn(G)));
    restored(:, :, c) = max(0, min(1, res));
end

result  = im2uint8(restored);
extra.H = fftshift(H);     % motionBlurPSF tidak ter-shift, dipusatkan untuk tampilan
end

% ---------------------------------------------------------------------------
% helper

function sz = paddedSize(img)
% ukuran citra setelah padImage2x
sz = 2 * [size(img, 1), size(img, 2)];
end

function t = describeFilterList(filterList)
% ringkasan isi filterList, misal "butterworth x4, notchline x1"
types = cellfun(@(s) lower(s.type), filterList, 'UniformOutput', false);
[names, ~, idx] = unique(types, 'stable');
parts = cell(1, numel(names));
for k = 1:numel(names)
    parts{k} = sprintf('%s x%d', names{k}, sum(idx == k));
end
t = strjoin(parts, ', ');
end

function t = capitalize(t)
t(1) = upper(t(1));
end

function v = getValue(s, name, default)
if isfield(s, name) && ~isempty(s.(name))
    v = s.(name);
else
    v = default;
end
end

function v = getScalar(s, name, default)
if ~isfield(s, name) || isempty(s.(name))
    v = default;
    return;
end
v = s.(name);
validateattributes(v, {'numeric'}, {'finite', 'scalar'}, 'applyFrequencyMethod', name);
end

function v = getText(s, name, default)
if ~isfield(s, name) || isempty(s.(name))
    v = default;
    return;
end
v = char(s.(name));
end

function checkPositiveScalar(v, name)
validateattributes(v, {'numeric'}, {'positive', 'finite', 'scalar'}, ...
    'applyFrequencyMethod', name);
end
