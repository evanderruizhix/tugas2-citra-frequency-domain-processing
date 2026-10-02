clear; clc; close all;

I = im2double(imread('cameraman.tif'));

LEN = 15;
% K = ones(1, LEN) / LEN;
K = eye(LEN) / LEN;

disp('Kernel PSF:');
disp(K);
fprintf('Jumlah isi kernel = %.2f\n', sum(K(:)));
blurred = imfilter(I, K, 'conv', 'replicate');

figure;
subplot(1, 2, 1); imshow(I);       title('Citra asli');
subplot(1, 2, 2); imshow(blurred); title(sprintf('Motion blur (LEN = %d)', LEN));