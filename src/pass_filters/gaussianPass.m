function H = gaussianPass(sizeImg, u0, v0, diameter, isLowPass)
% filter Gaussian (lowpass/highpass) berpusat di titik (u0, v0)
% relatif terhadap tengah spektrum.
%
% OUTPUT:
% H - filter 2D (nilai 0..1), ukuran sizeImg

if isempty(u0), u0 = 0; end
if isempty(v0), v0 = 0; end

[U, V] = freqGrid(sizeImg);

D = sqrt((U - u0).^2 + (V - v0).^2);
D0 = diameter / 2;

lowpass = exp(-(D.^2) ./ (2 * (D0^2) + eps));

if isLowPass
    H = lowpass;
else
    H = 1 - lowpass;
end
end