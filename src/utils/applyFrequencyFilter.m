function imgResult = applyFrequencyFilter(img, H)
% menerapkan filter H ke citra di ranah frekuensi:
% pad 2x -> fft2 -> fftshift -> kali H -> balik -> crop -> uint8
%
% INPUT:
%   img - citra grayscale (2D) atau RGB (3D), skala 0..255.
%         RGB diproses per kanal supaya hasil tetap berwarna
%   H   - filter 2D terpusat (hasil buildFilter.m), ukurannya harus
%         sama dengan citra yang sudah di-pad: [2*rows, 2*cols]
%
% OUTPUT:
%   imgResult - citra hasil (uint8), ukuran sama dengan img

[imgPadded, origSize] = padImage2x(img);
sizePad = [size(imgPadded, 1), size(imgPadded, 2)];

if ~isequal(size(H), sizePad)
    error('applyFrequencyFilter:ukuranBeda', ...
        'Ukuran H (%dx%d) harus sama dengan citra ter-pad (%dx%d).', ...
        size(H, 1), size(H, 2), sizePad(1), sizePad(2));
end

imgResult = zeros(size(img));

for c = 1:size(img, 3)
    F = fft2(double(imgPadded(:, :, c)));
    F = fftshift(F);
    G = F .* H;

    g = real(ifft2(ifftshift(G)));
    imgResult(:, :, c) = g(1:origSize(1), 1:origSize(2));   % crop balik
end

imgResult = max(0, min(255, imgResult));
imgResult = uint8(imgResult);
end
