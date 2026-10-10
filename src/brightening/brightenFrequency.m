function imgBright = brightenFrequency(img, targetMean)
% Peningkatan kecerahan citra di ranah frekuensi tanpa mengubah rasio warna RGB
%
% INPUT:
% img        - Citra masukan (Grayscale 2D atau RGB 3D)
% targetMean - Target kecerahan rata-rata [0..1] (default: 0.48)
%
% OUTPUT:
% imgBright  - Citra hasil pencerahan

if nargin < 2 || isempty(targetMean)
    targetMean = 0.48; 
end

isInputUint8 = isa(img, 'uint8');
imgDouble = im2double(img);
[M, N, C] = size(imgDouble);
imgBright = zeros(size(imgDouble));

% Hitung total rata-rata kecerahan awal dari komponen DC seluruh channel
totalDC = 0;
for c = 1:C
    F_temp = fft2(imgDouble(:,:,c));
    totalDC = totalDC + real(F_temp(1,1));
end
currentMean = (totalDC / C) / (M * N);

% Hitung satu nilai alpha global agar rasio R:G:B tidak terdistorsi
if currentMean > 0
    alpha = targetMean / currentMean;
else
    alpha = 1.0;
end

% Terapkan alpha yang sama ke seluruh channel di ranah frekuensi
for c = 1:C
    F = fft2(imgDouble(:,:,c));
    
    % Skaling spektrum dengan alpha global
    G = F * alpha;
    
    res = real(ifft2(G));
    imgBright(:,:,c) = max(0, min(1, res));
end

if isInputUint8
    imgBright = im2uint8(imgBright);
end
end