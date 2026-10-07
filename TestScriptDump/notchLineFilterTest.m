% test_notchLineFilter.m
% Visualisasi notchLineFilter.m: bandingkan reject/pass, tegas/buram,
% dan garis yang diputus lingkaran.

clear; clc; close all;

sizeImg = [400, 400];   % ukuran contoh, bebas (simulasi citra ter-pad)

% 1. Vertikal, REJECT, tegas (ideal)
H1 = notchLineFilter(sizeImg, 'vertical', 60, 20, 0, false);

% 2. Vertikal, REJECT, buram (blur=0.5 -> n=2)
H2 = notchLineFilter(sizeImg, 'vertical', 60, 20, 0.5, false);

% 3. Horizontal, PASS, tegas (ideal)
H3 = notchLineFilter(sizeImg, 'horizontal', -40, 20, 0, true);

% 4. Horizontal, PASS, buram
H4 = notchLineFilter(sizeImg, 'horizontal', -40, 20, 0.5, true);

% 5. Vertikal REJECT, tegas, DIPUTUS lingkaran di v=0 radius 40
H5 = notchLineFilter(sizeImg, 'vertical', 60, 20, 0, false, 0, 40, 2);

% 6. Horizontal PASS, tegas, DIPUTUS lingkaran di u=0 radius 40
H6 = notchLineFilter(sizeImg, 'horizontal', -40, 20, 0, true, 0, 40);

figure('Name', 'notchLineFilter - perbandingan');

subplot(2,3,1); imagesc(H1); axis image; colormap(gray); clim([0 1]);
title('Vertikal, Reject, Tegas');

subplot(2,3,2); imagesc(H2); axis image; colormap(gray); clim([0 1]);
title('Vertikal, Reject, Blur 0.5');

subplot(2,3,3); imagesc(H5); axis image; colormap(gray); clim([0 1]);
title('Vertikal, Reject, Tegas, Diputus');

subplot(2,3,4); imagesc(H3); axis image; colormap(gray); clim([0 1]);
title('Horizontal, Pass, Tegas');

subplot(2,3,5); imagesc(H4); axis image; colormap(gray); clim([0 1]);
title('Horizontal, Pass, Blur 0.5');

subplot(2,3,6); imagesc(H6); axis image; colormap(gray); clim([0 1]);
title('Horizontal, Pass, Tegas, Diputus');