%freqDomainViewer.m
%menampilkan tiap gambar di folder input berpasangan dengan magnitude spectrum (frequency domain)
folderPath = '02_citra_test_images/E_periodic_noise_restoration/input';
files = dir(fullfile(folderPath, '*.png'));

for i = 1:length(files)
    filename = fullfile(folderPath, files(i).name);
    img = imread(filename);

    %ubah ke grayscale dulu untuk FFT
    if size(img, 3) == 3
        imgGray = rgb2gray(img);
    else
        imgGray = img;
    end

    %hitung FFT, shift ke tengah, ambil magnitude, log-scale
    F = fft2(double(imgGray));
    F = fftshift(F);
    magnitude = log(abs(F) + 1);

    
    figure('Name', files(i).name, 'NumberTitle', 'off');

    subplot(1, 2, 1);
    imshow(img);
    title(['Citra Asli: ', files(i).name], 'Interpreter', 'none');

    subplot(1, 2, 2);
    imagesc(magnitude);
    colormap(gca, gray);
    axis image;
    title('Magnitude Spectrum');
end