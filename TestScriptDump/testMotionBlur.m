clear; clc; close all;

% Pilih citra uji
imgPath = fullfile('02_citra_test_images', 'F_motion_blur_restoration', 'input', 'astronaut_color_motion_L19_A20_gaussian_noise.png');
L = 19; 
theta = 20;

% Baca citra dan ubah ke double
img = imread(imgPath);
imgDouble = im2double(img);
[M, N, C] = size(imgDouble);

% Variasi Parameter untuk Diuji
thresholds = [0.005, 0.02, 0.1]; % variasi threshold
Ks = [0.0001, 0.005, 0.05];     % variasi NSR / K

% Hitung PSF/H(u,v) untuk ukuran citra
H = motionBlurPSF([M, N], L, theta);

imgInverse = zeros(M, N, C, 3);
imgWiener = zeros(M, N, C, 3);

% Inverse Filtering
for i = 1:3
    thresh = thresholds(i);
    for c = 1:C
        G = fft2(imgDouble(:,:,c));
        F_hat_inv = inverseFilter(G, H, thresh);
        res_inv = real(ifft2(F_hat_inv));
        imgInverse(:,:,c,i) = max(0, min(1, res_inv)); % Clamping [0, 1]
    end
end

% Wiener Filtering
for i = 1:3
    kVal = Ks(i);
    for c = 1:C
        G = fft2(imgDouble(:,:,c));
        F_hat_wie = wienerFilter(G, H, kVal);
        res_wie = real(ifft2(F_hat_wie));
        imgWiener(:,:,c,i) = max(0, min(1, res_wie)); % Clamping [0, 1]
    end
end

% FIGURE 1: Inverse Filtering
figure('Name', 'Restorasi Motion Blur - Inverse Filtering', 'NumberTitle', 'off');

subplot(2,2,1);
imshow(img);
title(sprintf('Citra Input (Buram)\nL=%d, \\theta=%d°', L, theta));

for i = 1:3
    subplot(2,2, i+1);
    imshow(imgInverse(:,:,:,i));
    title(sprintf('Inverse Filtering\nThreshold = %.3f', thresholds(i)));
end

% FIGURE 2: Wiener Filtering
figure('Name', 'Restorasi Motion Blur - Wiener Filtering', 'NumberTitle', 'off');

subplot(2,2,1);
imshow(img);
title(sprintf('Citra Input (Buram)\nL=%d, \\theta=%d°', L, theta));

for i = 1:3
    subplot(2,2, i+1);
    imshow(imgWiener(:,:,:,i));
    title(sprintf('Wiener Filtering\nK = %.4f', Ks(i)));
end