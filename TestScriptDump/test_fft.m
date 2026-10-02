f = zeros(6); f(1:3,1:3) = [1 2 3; 4 5 6; 7 8 9];
F = fft2(f);
abs(F)             
abs(fftshift(F))  

%konvolusi 1D
real(ifft(fft([1 2 3 4]) .* fft([1 1], 4)))          % [5 3 5 7]
real(ifft(fft([1 2 3 4 0 0 0 0]) .* fft([1 1], 8)))  % [1 3 5 7 4 0 0 0]