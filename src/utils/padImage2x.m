function [imgPadded, origSize] = padImage2x(img)
% melakukan zero-padding pada citra menjadi 2x lipat ukuran
%
% INPUT:
% img
%
% OUTPUT:
% imgPadded - citra hasil padding, ukuran (2*rows x 2*cols [x channel])
% origSize  - [rows, cols] ukuran asli, dipakai untuk crop balik.
%             mgResult = imgFiltered(1:origSize(1), 1:origSize(2));

[rows, cols, channels] = size(img);
origSize = [rows, cols];

paddedRows = rows * 2;
paddedCols = cols * 2;

imgPadded = zeros(paddedRows, paddedCols, channels, 'like', img);
imgPadded(1:rows, 1:cols, :) = img;
end