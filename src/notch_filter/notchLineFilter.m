function H = notchLineFilter(sizeImg, orientation, position, width, blur, isPass, breakPos, breakRadius, breakBlur)
% Membuat filter berbentuk garis (horizontal/vertikal) bisa pass atau reject, 
% dengan tepi tegas (ideal) atau buram (Butterworth-style). 
% Opsional: garis bisa diputus oleh satu lingkaran di titik tertentu.
%
% INPUT:
%   sizeImg     - [rows, cols]
%   orientation - 'vertical' atau 'horizontal'
%   position    - lokasi garis, relatif terhadap pusat spektrum:
%                   'vertical'   -> posisi di sumbu U (horizontal)
%                   'horizontal' -> posisi di sumbu V (vertikal)
%   width       - lebar garis (total)
%   blur        - 0   -> tepi garis tegas (ideal, hard-edge)
%                 > 0 -> tepi garis buram, n = 1/blur (makin besar blur, makin landai)
%   isPass      - true  -> PASS 
%                 false -> REJECT 
%
% INPUT OPSIONAL (garis terputus):
%   breakPos    - posisi pusat lingkaran pemutus, di sumbu BEBAS garis:
%                   garis vertikal   -> breakPos ini posisi di V
%                   garis horizontal -> breakPos ini posisi di U
%                 Kosongkan [] atau tidak usah diisi kalau tidak perlu.
%   breakRadius - radius lingkaran pemutus
%   breakBlur   - 0   -> tepi lingkaran pemutus tegas
%                 > 0 -> tepi lingkaran pemutus buram
%
% OUTPUT:
%   H - filter 2D (nilai 0..1), ukuran sizeImg


if nargin < 7, breakPos = []; end
if nargin < 8, breakRadius = []; end
if nargin < 9, breakBlur = 0; end


[U, V] = freqGrid(sizeImg);

% jarak tegak lurus ke garis
switch lower(orientation)
    case 'vertical'
        D = abs(U - position); % misal --> .. 3 2 1 | 1 2 3
    case 'horizontal'
        D = abs(V - position);
    otherwise
        error('notchLineFilter:badOrientation', ...
            'orientation harus ''vertical'' atau ''horizontal'', bukan "%s"', orientation);
end

D0 = width / 2; % lebar setengah

% bentuk transisi: ideal (blur=0) atau butterworth (blur>0)
if blur == 0
    passShape = double(D <= D0);   % nilai 1 di dalam garis 
else
    n = 1 / blur;
    D0safe = D0;
    D0safe(D0safe == 0) = eps;
    passShape = 1 ./ (1 + (D ./ D0safe).^(2 * n));   % nilai 1 di garis, gradasi ke 0
end

if isPass
    H = passShape;         
    baseline = 0;
else
    H = 1 - passShape;     
    baseline = 1;
end

% memutus garis dengan lingkaran
if ~isempty(breakPos) && ~isempty(breakRadius) && breakRadius > 0
    switch lower(orientation)
        case 'vertical'
            % pusat lingkaran: (u=position, v=breakPos)
            Dcircle = sqrt((U - position).^2 + (V - breakPos).^2);
        case 'horizontal'
            % pusat lingkaran: (u=breakPos, v=position)
            Dcircle = sqrt((U - breakPos).^2 + (V - position).^2);
    end

    if breakBlur == 0
        restoreShape = double(Dcircle <= breakRadius);
    else
        nBreak = 1 / breakBlur;
        restoreShape = 1 ./ (1 + (Dcircle ./ breakRadius).^(2 * nBreak));
    end

    H = H .* (1 - restoreShape) + baseline .* restoreShape;
end
end