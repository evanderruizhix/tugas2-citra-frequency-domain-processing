img = imread("02_citra_test_images/E_periodic_noise_restoration/input/brick_gray_periodic_noise.png")
if size(img, 3) == 3
    img = rgb2gray(img);
end

% pad
[imgPadded, origSize] = padImage2x(img);
fprintf('Ukuran asli : %d x %d\n', origSize(1), origSize(2));
fprintf('Ukuran padded: %d x %d\n\n', size(imgPadded, 1), size(imgPadded, 2));

% findNoisePeaks
padFactor = 1;
peaks = findNoisePeaks(imgPadded, ...
    'ExcludeRadius', 10 * padFactor, ...
    'MinDistance', 8 * padFactor, ...
    'ThresholdStd', 5, ...
    'MaxPeaks', 10, ...
    'Visualize', true);

% cek hasil print
fprintf('Jumlah noise peak terdeteksi: %d\n\n', numel(peaks));
fprintf('%-6s %-10s %-10s %-12s %-10s\n', 'No', 'u', 'v', 'Jarak(D0)', 'Magnitude');
fprintf('%s\n', repmat('-', 1, 50));

for k = 1:numel(peaks)
    fprintf('%-6d %-10d %-10d %-12.2f %-10.2f\n', ...
        k, peaks(k).u, peaks(k).v, peaks(k).distance, peaks(k).magnitude);
end