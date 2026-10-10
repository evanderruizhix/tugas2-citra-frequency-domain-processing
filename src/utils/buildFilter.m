function H = buildFilter(sizeImg, filterList, combineMode)
% menyatukan beberapa filter (dari list parameter) jadi
% satu filter gabungan H
%
% INPUT:
%   sizeImg     - [rows, cols], ukuran citra yang sudah di-pad
%   filterList  - struct array ATAU cell array of struct, tiap elemen
%                 representasi 1 filter (cell dipakai kalau tipe filternya
%                 campur dan field-nya beda-beda)
%   combineMode - (opsional) cara menyatukan filter, default 'reject':
%                   'reject' -> H = H1 .* H2 .* ...
%                               tiap filter MEREDAM areanya (notch reject)
%                   'pass'   -> H = 1 - (1-H1) .* (1-H2) .* ...
%                               tiap filter MELOLOSKAN areanya (notch pass),
%                               hasilnya sama dengan 1 - H versi reject
%
%     semua type titik/pita:
%       .u0        - posisi horizontal relatif ke pusat ([] -> 0)
%       .v0        - posisi vertikal relatif ke pusat ([] -> 0)
%       .diameter  - diameter area cutoff (pita: diameter cincin)
%
%     type = 'ideal' / 'gaussian' / 'butterworth':
%       .isLowPass - true = lowpass, false = highpass
%       .n         - orde filter (butterworth saja)
%
%     type = 'band_ideal' / 'band_gaussian' / 'band_butterworth':
%       .width      - lebar pita
%       .isBandPass - true = bandpass, false = bandreject
%       .n          - orde filter (band_butterworth saja)
%
%     type = 'notchline' (garis horizontal/vertikal):
%       .orientation  - 'vertical' atau 'horizontal'
%       .position     - posisi garis (lihat notchLineFilter.m)
%       .width        - lebar garis
%       .blur         - 0 = tegas, >0 = buram (n = 1/blur)
%       .isPass       - true = pass, false = reject
%       .breakPos     - (opsional, [] kalau tidak dipakai)
%       .breakRadius  - (opsional, [] / 0 kalau tidak dipakai)
%       .breakBlur    - (opsional, default 0 kalau tidak diisi)
%
%     .isLowPass / .isBandPass / .isPass boleh tidak diisi, default-nya
%     mengikuti combineMode ('pass' -> true, 'reject' -> false).
%
% OUTPUT:
%   H - filter gabungan, ukuran sizeImg, nilai 0..1

if nargin < 3 || isempty(combineMode)
    combineMode = 'reject';
end

switch lower(combineMode)
    case 'reject'
        isPassMode = false;
    case 'pass'
        isPassMode = true;
    otherwise
        error('buildFilter:unknownMode', ...
            'combineMode harus ''reject'' atau ''pass'', bukan "%s"', combineMode);
end

% Hreject = hasil kali bagian yang "diredam" tiap filter
Hreject = ones(sizeImg);

for i = 1:numel(filterList)
    if iscell(filterList)
        spec = filterList{i};
    else
        spec = filterList(i);
    end

    % default u0/v0
    u0 = getFieldOrDefault(spec, 'u0', 0);
    v0 = getFieldOrDefault(spec, 'v0', 0);

    % pembuatan per filter
    switch lower(spec.type)
        case 'ideal'
            isLowPass = getFieldOrDefault(spec, 'isLowPass', isPassMode);
            Hk = idealPass(sizeImg, u0, v0, spec.diameter, isLowPass);

        case 'gaussian'
            isLowPass = getFieldOrDefault(spec, 'isLowPass', isPassMode);
            Hk = gaussianPass(sizeImg, u0, v0, spec.diameter, isLowPass);

        case 'butterworth'
            isLowPass = getFieldOrDefault(spec, 'isLowPass', isPassMode);
            Hk = butterworthPass(sizeImg, u0, v0, spec.n, spec.diameter, isLowPass);

        case 'band_ideal'
            isBandPass = getFieldOrDefault(spec, 'isBandPass', isPassMode);
            Hk = bandIdeal(sizeImg, u0, v0, spec.diameter, spec.width, isBandPass);

        case 'band_gaussian'
            isBandPass = getFieldOrDefault(spec, 'isBandPass', isPassMode);
            Hk = bandGaussian(sizeImg, u0, v0, spec.diameter, spec.width, isBandPass);

        case 'band_butterworth'
            isBandPass = getFieldOrDefault(spec, 'isBandPass', isPassMode);
            Hk = bandButterworth(sizeImg, u0, v0, spec.diameter, spec.width, spec.n, isBandPass);

        case 'notchline'
            isPass      = getFieldOrDefault(spec, 'isPass', isPassMode);
            breakPos    = getFieldOrDefault(spec, 'breakPos', []);
            breakRadius = getFieldOrDefault(spec, 'breakRadius', []);
            breakBlur   = getFieldOrDefault(spec, 'breakBlur', 0);
            Hk = notchLineFilter(sizeImg, spec.orientation, spec.position, spec.width, spec.blur, isPass, breakPos, breakRadius, breakBlur);

        otherwise
            error('buildFilter:unknownType', ...
                'Masukin nama filter yg bener mas bukan: "%s" (entry ke-%d)', ...
                spec.type, i);
    end

    if isPassMode
        Hreject = Hreject .* (1 - Hk);   % gabungan (union) area yang diloloskan
    else
        Hreject = Hreject .* Hk;         % irisan area yang lolos
    end
end

if isPassMode
    H = 1 - Hreject;
else
    H = Hreject;
end
end


% supaya field opsional di filterList tidak wajib diisi user/GUI.
function val = getFieldOrDefault(s, fieldName, defaultVal)
if isfield(s, fieldName) && ~isempty(s.(fieldName))
    val = s.(fieldName);
else
    val = defaultVal;
end
end
