function H = motionBlurPSF(sizeImg, L, theta)
% Pembentukan fungsi transfer degradasi / PSF Motion Blur H(u,v)
%
% INPUT:
% sizeImg - Ukuran matriks citra [baris, kolom]
% L       - Panjang pergerakan piksel (motion length)
% theta   - Sudut arah pergerakan dalam derajat (motion angle)
%
% OUTPUT:
% H       - Matriks 2D fungsi degradasi H(u,v), TIDAK ter-shift (DC di
%           pojok kiri atas), langsung bisa dikali dengan fft2(citra)
%
% Kernel blur dianggap terpusat, jadi H murni sinc tanpa faktor fase
% exp(-j*pi*Delta). Faktor fase itu menggeser hasil restorasi ~L/2 piksel.

if isempty(L) || L == 0, L = 1; end
if isempty(theta), theta = 0; end

[U, V] = freqGrid(sizeImg);
thetaRad = theta * pi / 180;

% di freqGrid, U = frekuensi horizontal (sepanjang kolom) dan V = vertikal
% (sepanjang baris), jadi U dibagi jumlah kolom dan V dibagi jumlah baris
Delta = (U / sizeImg(2)) * L * cos(thetaRad) + (V / sizeImg(1)) * L * sin(thetaRad);

% Sinc manual: sin(pi*x) / (pi*x)
sincVal = ones(size(Delta));
mask = (Delta ~= 0);
sincVal(mask) = sin(pi * Delta(mask)) ./ (pi * Delta(mask));

H = ifftshift(sincVal);
end
