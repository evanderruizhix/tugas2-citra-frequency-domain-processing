function H = bandGaussian(sizeImg, u0, v0, diameter, width, isBandPass)
% filter pita Gaussian (band reject/pass), cincin radial berpusat di
% (u0, v0), transisi paling halus.
%
% OUTPUT:
% H - filter 2D (nilai 0..1), ukuran sizeImg

if isempty(u0), u0 = 0; end
if isempty(v0), v0 = 0; end

[U, V] = freqGrid(sizeImg);

D = sqrt((U - u0).^2 + (V - v0).^2);
D0 = diameter / 2;
W = width;

denom = D .* W;
denom(denom == 0) = eps;

% Rumus Gaussian Bandpass
bandpass = exp(-(((D.^2 - D0^2) ./ denom).^2));

if isBandPass
    H = bandpass;
else
    H = 1 - bandpass; % Bandreject
end
end