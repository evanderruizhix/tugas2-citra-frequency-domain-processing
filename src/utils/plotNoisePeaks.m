function plotNoisePeaks(ax, mag, peaks)
% menampilkan spektrum magnitude beserta noise peak
% yang terdeteksi, dengan SUMBU dalam koordinat U,V 
%
% awalnya dari visualize findNoisePeaks.m dipindah ke sini biar bisa
% ditempel ke GUI
%
%   plotNoisePeaks(ax, mag, peaks)   % ax: axes/UIAxes tujuan
%   plotNoisePeaks([], mag, peaks)   % [] -> bikin figure baru 
%
% INPUT:
%   ax    - handle axes tujuan
%   mag   - citra magnitude spectrum (log-scale), output kedua dari
%           findNoisePeaks.m
%   peaks - struct array hasil findNoisePeaks.m
%
%
% CARA PAKAI (ditempel ke GUI, App Designer):
%   [peaks, mag] = findNoisePeaks(img, 'ThresholdStd', 6);
%   plotNoisePeaks(app.UIAxesSpectrum, mag, peaks);

if isempty(ax)
    figure('Name', 'Deteksi Noise Peaks');
    ax = axes;
end

[U, V] = freqGrid(size(mag));
uRange = U(1, :);
vRange = V(:, 1);

% imagesc dengan XData/YData custom -> sumbu plot & data cursor
% otomatis dalam koordinat U,V
imagesc(ax, uRange, vRange, mag);
colormap(ax, gray);
axis(ax, 'image');
hold(ax, 'on');

n = numel(peaks);
if n > 0
    peakU = [peaks.u];
    peakV = [peaks.v];
    plot(ax, peakU, peakV, 'ro', 'MarkerSize', 10, 'LineWidth', 1.5);

    % nomor urut di samping lingkaran, sama dengan kolom "No" di tabel peaks
    for k = 1:n
        text(ax, peakU(k), peakV(k), sprintf('  %d', k), ...
            'Color', 'y', 'FontSize', 10, 'FontWeight', 'bold', ...
            'VerticalAlignment', 'bottom');
    end
end

plot(ax, 0, 0, 'g+', 'MarkerSize', 12, 'LineWidth', 1.5);   % pusat/DC

xlabel(ax, 'u');
ylabel(ax, 'v');
title(ax, sprintf('%d noise peak terdeteksi (hijau = pusat/DC)', n));
hold(ax, 'off');
end