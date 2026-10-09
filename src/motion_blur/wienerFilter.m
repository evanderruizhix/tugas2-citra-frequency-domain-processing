function F_hat = wienerFilter(G, H, K)
% Restorasi spektrum citra menggunakan Wiener Filtering
%
% INPUT:
% G     - Spektrum Fourier 2D citra terdegradasi (G(u,v))
% H     - Fungsi transfer degradasi PSF (H(u,v))
% K     - Parameter konstan Noise-to-Signal Ratio (NSR)
%
% OUTPUT:
% F_hat - Spektrum Fourier 2D citra hasil restorasi

if nargin < 3 || isempty(K)
    K = 0.01; 
end

W = conj(H) ./ (abs(H).^2 + K);

F_hat = G .* W;
end