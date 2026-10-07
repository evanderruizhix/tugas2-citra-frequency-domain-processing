function H = buildFilter(sizeImg, filterList)
% menyatukan beberapa filter (dari list parameter) jadi
% satu filter gabungan H
%
% INPUT:
%   sizeImg    - [rows, cols], ukuran citra yang sudah di-pad
%   filterList - struct array, representasi 1 filter
%
%     type = 'butterworth':
%       .u0        - posisi horizontal relatif ke pusat ([] -> 0)
%       .v0        - posisi vertikal relatif ke pusat ([] -> 0)
%       .diameter  - diameter area cutoff
%       .isLowPass - true = lowpass, false = highpass
%       .n         - orde filter
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
%     type = 'ideal' / 'gaussian' -- soon
%
% OUTPUT:
%   H - filter gabungan, ukuran sizeImg, nilai 0..1


H = ones(sizeImg);

for i = 1:numel(filterList)
    spec = filterList(i);

    % default u0/v0 
    u0 = getFieldOrDefault(spec, 'u0', 0);
    v0 = getFieldOrDefault(spec, 'v0', 0);

    % pembuatan per filter
    switch lower(spec.type)
        case 'butterworth'
            Hk = butterworthPass(sizeImg, u0, v0, spec.n, spec.diameter, spec.isLowPass);

        % TODO
        case 'ideal'
            error('buildFilter:notImplemented', ...
                ['ILPF/IHPF belum diimplementasikan.']);

        % TODO
        case 'gaussian'
            error('buildFilter:notImplemented', ...
                ['GLPF/GHPF belum diimplementasikan.']);

        % TODO: buat filter bandfilter (ideal, gauss, butterworth) ini
        % terserah mau dipisah per file, atau sbgi parameter dalam 1 fungsi
        % bandpass/reject
        
        case 'band_ideal'
            error('buildFilter:notImplemented', ...
                ['bandreject/bandpass ideal belum diimplementasikan.']);

        case 'notchline'
                breakPos    = getFieldOrDefault(spec, 'breakPos', []);
                breakRadius = getFieldOrDefault(spec, 'breakRadius', []);
                breakBlur   = getFieldOrDefault(spec, 'breakBlur', 0);
                Hk = notchLineFilter(sizeImg, spec.orientation, spec.position, spec.width, spec.blur, spec.isPass, breakPos, breakRadius, breakBlur);

        otherwise
            error('buildFilter:unknownType', ...
                'Masukin nama filter yg bener mas bukan: "%s" (entry ke-%d)', ...
                spec.type, i);
    end

    H = H .* Hk;
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