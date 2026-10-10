% Test visualisasi filter gabungan

imgPath = '02_citra_test_images/E_periodic_noise_restoration/input/brick_gray_periodic_noise.png';
img = imread(imgPath);
if size(img, 3) == 3
    img = rgb2gray(img);
end

% padding lewat utils
[imgPadded, origSize] = padImage2x(img);
sizeImg = size(imgPadded);

% simulasi list filter (2)
% kalau dari hasil fineNoisePeakTest
%      -72        31         78.39        15.17
%      72         -31        78.39        15.17
filterListEnhance(1) = struct('type', 'butterworth','u0', -72, 'v0', 31,'diameter', 20, 'n', 30, 'isLowPass', false);
filterListEnhance(2) = struct('type', 'butterworth','u0', 72, 'v0', -31,'diameter', 20, 'n', 4, 'isLowPass', false);
H_enhance = buildFilter(sizeImg, filterListEnhance);

% test hasil, visualisasi
figure('Name', 'Filter Gabungan buat enhance');
imagesc(H_enhance); colormap(gray); axis image; colorbar; clim([0 1]);
title('Filter H hasil buildFilter (putih=lolos, hitam=diredam)');

% di terapkan ke citra
F = fft2(double(imgPadded));
F = fftshift(F);
Fcleaned = F .* H_enhance;

imgResult = ifft2(ifftshift(Fcleaned));
imgResult = real(imgResult);
imgResult = imgResult(1:origSize(1), 1:origSize(2));  % crop balik
imgResult = uint8(imgResult);

% --- visualisasi spektrum: pakai imagesc+colormap gray
figure('Name', 'Sebelum vs Sesudah - Butterworth titik');
subplot(2, 3, 1);
imagesc(log(abs(F)+1)); colormap(gray); axis image;
title('Fourier');

subplot(2, 3, 2); imshow(H_enhance); title('filter');

subplot(2, 3, 3);
imagesc(log(abs(Fcleaned)+1)); colormap(gray); axis image;
title('Masked Fourier');

subplot(2, 3, 4); imshow(img); title('Sebelum');
subplot(2, 3, 5); imshow(imgResult); title('Sesudah buildFilter');


% ================================================================

imgPath2 = '02_citra_test_images/E_periodic_noise_restoration/input/hubble_color_periodic_noise.png';
img2 = imread(imgPath2);
if size(img2, 3) == 3
    img2 = rgb2gray(img2);
end

[img2Padded, origSize2] = padImage2x(img2);
sizeImg2 = size(img2Padded);

% --- cek dulu spektrumnya SEBELUM nentuin parameter notch ---
F2 = fftshift(fft2(double(img2Padded)));

figure('Name', 'Cek spektrum sebelum notch (hubble)');
imagesc(log(abs(F2)+1)); colormap(gray); axis image; colorbar;
title('Spektrum citra ber-noise vertikal -- cari garis terang di v≈0');

filterListDenoise(1) = struct('type', 'notchline', ...
    'orientation', 'horizontal', 'position', 0, 'width', 8, ...
    'blur', 0, 'isPass', true, ...
    'breakPos', 0, 'breakRadius', 20, 'breakBlur', 0.2);

H_denoise = buildFilter(sizeImg2, filterListDenoise);

Fcleaned2 = F2 .* H_denoise;
imgResult2 = ifft2(ifftshift(Fcleaned2));
imgResult2 = real(imgResult2);
imgResult2 = imgResult2(1:origSize2(1), 1:origSize2(2));
imgResult2 = uint8(imgResult2);

[imResMinPass, noisePattern] = subtractNotchPattern(img2, img2Padded, H_denoise, origSize2);

figure('Name', 'Notch Line Horizontal - Sebelum vs Sesudah');

subplot(2, 3, 1);
imagesc(log(abs(F2)+1)); colormap(gray); axis image;
title('Fourier (hubble)');

subplot(2, 3, 2);
imagesc(H_denoise); colormap(gray); axis image; clim([0 1]);
title('Filter H (notch horizontal, diputus di DC)');

subplot(2, 3, 3);
imagesc(log(abs(Fcleaned2)+1)); colormap(gray); axis image;
title('Masked Fourier');

noisePatternDisplay = uint8(mat2gray(noisePattern) * 255);

subplot(2, 3, 4); imshow(imResMinPass);
subplot(2, 3, 5); imshow(img2); title('Sebelum');
subplot(2, 3, 6); imshow(noisePatternDisplay); title('Sesudah notch line');