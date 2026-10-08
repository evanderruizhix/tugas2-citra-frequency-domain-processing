function peaks = findNoisePeaks(img, varargin)
% mendeteksi titik-titik noise periodik pada spektrum
%
% INPUT:
% img
%
% OUTPUT:
% peaks - struct array, tiap elemen punya field:
% .row, .col       : koordinat piksel (fftshift)
% .u, .v           : koordinat relatif terhadap pusat
% .distance        : radius dari pusat
% .magnitude       : nilai magnitude/log-scale di titik itu
    
    % list parameter name
    p = inputParser;
    addParameter(p, 'ExcludeRadius', 20);
    addParameter(p, 'MinDistance', 16);
    addParameter(p, 'MaxPeaks', 10);
    addParameter(p, 'ThresholdStd', 3);
    parse(p, varargin{:});
    opt = p.Results;

    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    img = double(img);

    % hitung spectrum
    F = fft2(img);
    F = fftshift(F);
    mag = log(abs(F) + 1);

    [rows, cols] = size(mag);
    centerRow = floor(rows/2) + 1;
    centerCol = floor(cols/2) + 1;

    % exclude area pusat
    [X, Y] = meshgrid(1:cols, 1:rows);
    distFromCenter = sqrt((X - centerCol).^2 + (Y - centerRow).^2);
    validMask = distFromCenter > opt.ExcludeRadius; %element wise 1 atau 0

    % atur threshold
    magValid = mag(validMask);
    threshold = mean(magValid) + opt.ThresholdStd * std(magValid);

    % cari local maxima di atas threshold
    localMax = imregionalmax(mag);
    candidateMask = localMax & validMask & (mag > threshold);

    [candRows, candCols] = find(candidateMask);
    candVals = mag(candidateMask);

    if isempty(candRows)
        peaks = struct('row', {}, 'col', {}, 'u', {}, 'v', {}, ...
                        'distance', {}, 'magnitude', {});
        warning('Tidak ada noise peak terdeteksi. Turunkan ThresholdStd.');
        return;
    end

    % sort dari nilai magnitude tertinggi (biar ntar berpasangan urutan noise peak-nya)
    [candVals, sortIdx] = sort(candVals, 'descend');
    candRows = candRows(sortIdx);
    candCols = candCols(sortIdx);

    % buang titik yg terlalu berdekatan (NMS)
    selectedRows = [];
    selectedCols = [];
    selectedVals = [];

    for i = 1:length(candRows)
        if length(selectedRows) >= opt.MaxPeaks % cek udh melebihi peaks yg mau kita ambil
            break;
        end
        r = candRows(i);
        c = candCols(i);
        if isempty(selectedRows)
            tooClose = false;
        else
            d = sqrt((selectedRows - r).^2 + (selectedCols - c).^2);
            tooClose = any(d < opt.MinDistance);
        end

        % matiin warning "array growing inside a loop"
        if ~tooClose
            selectedRows(end+1, 1) = r;             %#ok<AGROW>
            selectedCols(end+1, 1) = c;             %#ok<AGROW>
            selectedVals(end+1, 1) = candVals(i);   %#ok<AGROW>
        end
    end

    % output struct
    n = length(selectedRows);
    peaks = struct('row', cell(1, n), 'col', cell(1, n), ...
                    'u', cell(1, n), 'v', cell(1, n), ...
                    'distance', cell(1, n), 'magnitude', cell(1, n));

    for i = 1:n
        peaks(i).row = selectedRows(i);
        peaks(i).col = selectedCols(i);
        peaks(i).u = selectedCols(i) - centerCol;   % posisi horizontal relatif
        peaks(i).v = selectedRows(i) - centerRow;   % posisi vertikal relatif
        peaks(i).distance = sqrt(peaks(i).u^2 + peaks(i).v^2);
        peaks(i).magnitude = selectedVals(i);
    end;
end