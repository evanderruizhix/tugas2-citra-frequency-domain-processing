function H = motionBlurPSF(sizeImg, L, theta)
% Pembentukan fungsi transfer degradasi / PSF Motion Blur H(u,v)
%
% INPUT:
% sizeImg - Ukuran matriks citra [baris, kolom]
% L       - Panjang pergerakan piksel (motion length)
% theta   - Sudut arah pergerakan dalam derajat (motion angle)
%
% OUTPUT:
% H       - Matriks 2D fungsi degradasi H(u,v)

if isempty(L) || L == 0, L = 1; end
if isempty(theta), theta = 0; end

[U, V] = freqGrid(sizeImg);
thetaRad = theta * pi / 180;

Delta = (U / sizeImg(1)) * L * cos(thetaRad) + (V / sizeImg(2)) * L * sin(thetaRad);

% Sinc manual: sin(pi*x) / (pi*x)
sincVal = ones(size(Delta));
mask = (Delta ~= 0);
sincVal(mask) = sin(pi * Delta(mask)) ./ (pi * Delta(mask));

H = sincVal .* exp(-1i * pi * Delta);

H = ifftshift(H);
end