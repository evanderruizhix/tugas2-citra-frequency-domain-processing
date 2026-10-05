function H = buildFilter(sizeImg, filterList)
% menyatukan beberapa filter (dari list parameter) jadi
% satu filter gabungan H


H = ones(sizeImg);

for i = 1:numel(filterList)
    spec = filterList(i);

    % default u0/v0 
    if ~isfield(spec, 'u0') || isempty(spec.u0)
        u0 = 0;
    else
        u0 = spec.u0;
    end
    if ~isfield(spec, 'v0') || isempty(spec.v0)
        v0 = 0;
    else
        v0 = spec.v0;
    end

    % pembuatan per filter
    switch lower(spec.type)
        case 'butterworth'
            Hk = butterworthPass(sizeImg, u0, v0, spec.n, spec.diameter, spec.isLowPass);

        % TODO
        case 'ideal'
            error('buildFilter:notImplemented', ...
                ['ILPF/IHPF belum diimplementasikan.']);

        % TODO
        case 'gaussian'
            error('buildFilter:notImplemented', ...
                ['GLPF/GHPF belum diimplementasikan.']);

        % TODO: buat filter notch reject pass (horizon/vertical line)
        % case....
        % karena ada notch pass, jangan lupa implemen pengurangan antar
        % image

        otherwise
            error('buildFilter:unknownType', ...
                'Masukin nama filter yg bener mas bukan: "%s" (entry ke-%d)', ...
                spec.type, i);
    end

    H = H .* Hk;
end
end