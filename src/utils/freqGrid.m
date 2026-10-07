function [U, V] = freqGrid(sizeImg)
% Membuat grid koordinat frekuensi (U, V) relatif terhadap
% pusat spektrum (hasil fftshift)


% ini hampir selalu dipake, jadi dibuat fungsi aja
P = sizeImg(1);   % baris
Q = sizeImg(2);   % kolom

uRange = -floor(Q/2) : (ceil(Q/2) - 1);
vRange = -floor(P/2) : (ceil(P/2) - 1);
[U, V] = meshgrid(uRange, vRange);
end