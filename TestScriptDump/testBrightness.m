clear; clc; close all;
addpath(genpath(pwd));

inputFolder = fullfile('02_citra_test_images', 'D_brightness_frequency', 'input');
refFolder   = fullfile('02_citra_test_images', 'D_brightness_frequency', 'reference');

files = dir(fullfile(inputFolder, '*.png'));

for i = 1:length(files)
    filename = files(i).name;
    
    imgIn = imread(fullfile(inputFolder, filename));
    
    imgResult = brightenFrequency(imgIn, 0.2665);
    
    refFilename = strrep(filename, '_dark.png', '.png');
    refPath = fullfile(refFolder, refFilename);
    hasRef = exist(refPath, 'file');
    
    figure('Name', sprintf('Pengujian: %s', filename), 'NumberTitle', 'off');
    
    subplot(1, 3, 1);
    imshow(imgIn);
    title('Input (Gelap)');
    
    subplot(1, 3, 2);
    imshow(imgResult);
    title('Hasil Pencerahan Frekuensi');
    
    if hasRef
        imgRef = imread(refPath);
        subplot(1, 3, 3);
        imshow(imgRef);
        title('Reference (Acuan)');
    end
end