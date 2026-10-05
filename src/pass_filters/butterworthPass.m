function H = butterworthPass(sizeImg, u0, v0, n, diameter, isLowPass)
% filter berpusat di titik (u0, v0) relatif terhadap tengah spektrum.
%
% OUTPUT:
% H - filter 2D (nilai 0..1), ukuran sizeImg

if isempty(u0)
    u0 = 0;
end
if isempty(v0)
    v0 = 0;
end

rows = sizeImg(1);
cols = sizeImg(2);
centerRow = floor(rows/2) + 1;
centerCol = floor(cols/2) + 1;

% cari aman kalau lupa padding
[X, Y] = meshgrid(1:cols, 1:rows);
U = X - centerCol;
V = Y - centerRow;

D = sqrt((U - u0).^2 + (V - v0).^2);
D(D == 0) = eps; 

D0 = diameter / 2;

lowpass = 1 ./ (1 + (D ./ D0).^(2 * n));

if isLowPass
    H = lowpass;
else
    H = 1 - lowpass;
end
end
