function imgResult = subtractNotchPattern(imgOriginal, imgPadded, Hpass, origSize, weight)
% implementasi "optimum notch filtering" dipakai  ketika filter yang dibangun buildFilter.m berupa notch PASS (isPass=true)
%
% INPUT:
%   imgOriginal - citra asli SEBELUM di-pad (grayscale)
%   imgPadded   - citra yang sudah di-pad (buat fft2)
%   Hpass       - mask notch PASS hasil buildFilter.m 
%   origSize    - [rows, cols] ukuran citra asli, buat crop balik
%   weight      - (opsional) skalar 0..1, seberapa besar pola noise
%                 dikurangkan.
%
% OUTPUT:
%   imgResult - citra hasil (uint8), ukuran origSize


if nargin < 5
    weight = 1;
end

F = fft2(double(imgPadded));
F = fftshift(F);
Fnoise = F .* Hpass;

noisePattern = ifft2(ifftshift(Fnoise));
noisePattern = real(noisePattern);
noisePattern = noisePattern(1:origSize(1), 1:origSize(2));  % crop balik

imgResult = double(imgOriginal) - weight * noisePattern;

imgResult = max(0, min(255, imgResult));
imgResult = uint8(imgResult);
end