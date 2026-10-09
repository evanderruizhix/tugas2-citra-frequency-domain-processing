function F_hat = inverseFilter(G, H, threshold)
% Restorasi spektrum citra menggunakan Inverse Filtering
%
% INPUT:
% G         - Spektrum Fourier 2D citra terdegradasi (G(u,v))
% H         - Fungsi transfer degradasi PSF (H(u,v))
% threshold - Nilai ambang batas minimum |H| untuk mencegah lonjakan derau
%
% OUTPUT:
% F_hat     - Spektrum Fourier 2D citra hasil restorasi

if nargin < 3 || isempty(threshold)
    threshold = 0.01;
end

H_inv = zeros(size(H));

mask = abs(H) >= threshold;
H_inv(mask) = 1 ./ H(mask);

F_hat = G .* H_inv;
end