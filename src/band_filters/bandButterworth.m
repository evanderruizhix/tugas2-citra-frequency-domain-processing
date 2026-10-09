function H = bandButterworth(sizeImg, u0, v0, diameter, width, n, isBandPass)
% filter pita Butterworth (band reject/pass), cincin radial berpusat
% di (u0, v0)
%
% OUTPUT:
% H - filter 2D (nilai 0..1), ukuran sizeImg

if isempty(u0), u0 = 0; end
if isempty(v0), v0 = 0; end

[U, V] = freqGrid(sizeImg);

D = sqrt((U - u0).^2 + (V - v0).^2);
D0 = diameter / 2;
W = width;

num = D .* W;
denom = D.^2 - D0^2;

% Hindari pembagian dengan nol ketika D = D0
denom(denom == 0) = eps;

% Rumus Butterworth Bandreject
bandreject = 1 ./ (1 + (num ./ denom).^(2 * n));

if isBandPass
    H = 1 - bandreject; % Bandpass
else
    H = bandreject;     % Bandreject
end
end