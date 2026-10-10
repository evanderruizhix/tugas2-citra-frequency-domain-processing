function index = datasetIndex(rootFolder)
% datasetIndex - membaca struktur folder citra uji
%
% rootFolder : folder dataset (default '02_citra_test_images', relatif ke current folder)
% index      : struct array dengan field
%                .folder   : nama subfolder kategori (misal 'E_periodic_noise_restoration')
%                .path     : path subfolder input
%                .files    : cell array nama file citra PNG di input, terurut abjad
%                .refPath  : path subfolder reference ('' kalau tidak ada)
%                .refFiles : cell array nama file citra PNG di reference
%              kosong kalau folder dataset tidak ditemukan

if nargin < 1 || isempty(rootFolder)
    rootFolder = '02_citra_test_images';
end

index = struct('folder', {}, 'path', {}, 'files', {}, 'refPath', {}, 'refFiles', {});

if ~isfolder(rootFolder)
    return;
end

dirs = dir(rootFolder);
dirs = dirs([dirs.isdir]);
dirs = dirs(~ismember({dirs.name}, {'.', '..'}));
[~, urutan] = sort({dirs.name});   % urutkan biar dropdown konsisten
dirs = dirs(urutan);

for d = 1:numel(dirs)
    folderName = dirs(d).name;
    inputPath  = fullfile(rootFolder, folderName, 'input');
    refPath    = fullfile(rootFolder, folderName, 'reference');

    % kategori tanpa subfolder input dilewati
    if ~isfolder(inputPath)
        continue;
    end

    entry = struct();
    entry.folder = folderName;
    entry.path   = inputPath;
    entry.files  = listPng(inputPath);

    if isfolder(refPath)
        entry.refPath  = refPath;
        entry.refFiles = listPng(refPath);
    else
        entry.refPath  = '';
        entry.refFiles = {};
    end

    index(end + 1) = entry; %#ok<AGROW>
end
end

function names = listPng(folder)
files = dir(fullfile(folder, '*.png'));
names = sort({files.name});
end
