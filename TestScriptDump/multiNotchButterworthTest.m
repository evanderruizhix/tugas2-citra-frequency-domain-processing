% Test visualisasi filter gabungan

imgPath = '02_citra_test_images/E_periodic_noise_restoration/input/brick_gray_periodic_noise.png';
img = imread(imgPath);
if size(img, 3) == 3
    img = rgb2gray(img);
end

% padding lewat utils
[imgPadded, origSize] = padImage2x(img);
sizeImg = size(imgPadded);

% simulasi list filter (1)
% entry 1: lowpass global, berpusat di tengah (u0=v0=0/kosong)
filterList(1) = struct('type', 'butterworth','u0', [], 'v0', [],'diameter', 160, 'n', 2, 'isLowPass', true);
% entry 2 & 3: dua titik highpass 
filterList(2) = struct('type', 'butterworth','u0', 40, 'v0', 25, 'diameter', 16, 'n', 4, 'isLowPass', false);
filterList(3) = struct('type', 'butterworth', 'u0', -40, 'v0', -25, 'diameter', 16, 'n', 4, 'isLowPass', false);
% gabungin filter
H = buildFilter(sizeImg, filterList);


% simulasi list filter (2)
% kalau dari hasil fineNoisePeakTest
%      -72        31         78.39        15.17     
%      72         -31        78.39        15.17  
filterListEnhance(1) = struct('type', 'butterworth','u0', -72, 'v0', 31,'diameter', 20, 'n', 4, 'isLowPass', false);
filterListEnhance(2) = struct('type', 'butterworth','u0', 72, 'v0', -31, 'diameter', 20, 'n', 4, 'isLowPass', false);
% gabungin filter
H_enhance = buildFilter(sizeImg, filterListEnhance);



% test hasil, visualisasi
figure('Name', 'Filter Gabungan');
imagesc(H); colormap(gray); axis image; colorbar;
title('Filter H hasil buildFilter (putih=lolos, hitam=diredam)');

figure('Name', 'Filter Gabungan buat enhance');
imagesc(H_enhance); colormap(gray); axis image; colorbar;
title('Filter H hasil buildFilter (putih=lolos, hitam=diredam)');

% di terapkan ke citra
F = fft2(double(imgPadded));
F = fftshift(F);
Fcleaned = F .* H_enhance;

imgResult = ifft2(ifftshift(Fcleaned));
imgResult = real(imgResult);
imgResult = imgResult(1:origSize(1), 1:origSize(2));  % crop balik
imgResult = uint8(imgResult);

figure('Name', 'Sebelum vs Sesudah');
subplot(1, 2, 1); imshow(img); title('Sebelum');
subplot(1, 2, 2); imshow(imgResult); title('Sesudah buildFilter');