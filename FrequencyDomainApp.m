function app = FrequencyDomainApp()
% FrequencyDomainApp - GUI pemrosesan citra di ranah frekuensi

rootFolder = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(rootFolder, 'src')));
addpath(fullfile(rootFolder, 'gui'));

app = initApp(rootFolder);

% dipanggil tanpa output: jangan cetak isi app ke command window
if nargout == 0
    clear app;
end
end

% ===========================================================================
% Pembangunan UI
% ===========================================================================

function app = initApp(rootFolder)

% ---- struktur utama -------------------------------------------------------
app = AppState();

app.DatasetIdx = datasetIndex(fullfile(rootFolder, '02_citra_test_images'));
app.NotchCards = struct('type', {}, 'rows', {});

% placeholder panel parameter per metode; diisi oleh buildPassPanel dkk
app.Panels = struct('pass', [], 'brightness', [], 'notch', [], 'motion', []);

% ukuran figure menyesuaikan layar supaya tidak terpotong di layar kecil
layar = get(groot, 'ScreenSize');
lebar  = min(1360, layar(3) - 60);
tinggi = min(800,  layar(4) - 110);

app.Figure = uifigure( ...
    'Name',             'Pemrosesan Citra Ranah Frekuensi - IF4073', ...
    'Position',         [30 50 lebar tinggi], ...
    'Theme',            'light', ...
    'Color',            [0.94 0.94 0.94], ...
    'AutoResizeChildren', false, ...
    'Visible',          'off', ...
    'CloseRequestFcn',  @(src, ~) closeApp(src));

% ---- pembagian: panel kontrol kiri + area tampilan kanan ----
% Gunakan panel dengan posisi manual agar bisa di-resize dengan drag divider
app.LeftPanel  = uipanel(app.Figure, ...
    'Title', '', ...
    'BorderType', 'none', ...
    'BackgroundColor', [0.96 0.96 0.96], ...
    'Units', 'normalized');

app.RightPanel = uipanel(app.Figure, ...
    'Title', '', ...
    'BorderType', 'none', ...
    'BackgroundColor', [0.94 0.94 0.94], ...
    'Units', 'normalized');

% ---- divider pemisah ----
app.Divider = uipanel(app.Figure, ...
    'Title', '', ...
    'BorderType', 'none', ...
    'BackgroundColor', [0.7 0.7 0.7], ...
    'Units', 'normalized');

% Atur posisi awal panel dan divider
updatePanelPositions(app);

% ---- bangun isi panel kiri dan kanan ----
buildLeftPanel(app);
buildRightPanel(app);

onFolderChanged(app);
onMethodChanged(app);
refreshAll(app);

% ---- setup mouse callbacks untuk drag divider ----
setupDividerCallbacks(app);

% figure dibuat visible setelah semua komponen siap supaya tidak berkedip
app.Figure.Visible = 'on';
end

% ---------------------------------------------------------------------------
function app = buildLeftPanel(app)

p = uigridlayout(app.LeftPanel, [10 1]);
p.RowHeight = {22, 26, 96, 28, 18, 28, 22, 26, '1x', 30};
p.RowSpacing = 4;
p.Padding = [8 8 8 8];
p.BackgroundColor = [0.96 0.96 0.96];

% --- 1. pilih citra ---------------------------------------------------------
uilabel(p, 'Text', '1. PILIH CITRA', 'FontWeight', 'bold', ...
    'FontColor', [0.15 0.25 0.45]);

app.FolderBox = uidropdown(p, ...
    'Items',     {app.DatasetIdx.folder}, ...
    'Tooltip',   'Kategori citra uji (subfolder 02_citra_test_images)', ...
    'BackgroundColor', 'w');
app.FolderBox.ValueChangedFcn = @(~, ~) onFolderChanged(app);

app.ImageBox = uilistbox(p, ...
    'Items',     {}, ...
    'Tooltip',   'Citra di subfolder input kategori terpilih');
app.ImageBox.Multiselect = 'off';

loadRow = uigridlayout(p, [1 2]);
loadRow.ColumnWidth = {'1x', 110};
loadRow.Padding = [0 0 0 0];
loadRow.BackgroundColor = [0.96 0.96 0.96];
uibutton(loadRow, 'Text', 'Muat Citra', ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.30 0.50 0.75], ...
    'FontColor', 'w', ...
    'ButtonPushedFcn', @(~, ~) loadSelectedImage(app));
uibutton(loadRow, 'Text', 'Dari File...', ...
    'BackgroundColor', [0.85 0.85 0.85], ...
    'Tooltip', 'Buka file citra di luar dataset (tanpa citra referensi)', ...
    'ButtonPushedFcn', @(~, ~) onOpenImageFile(app));

app.InfoLabel = uilabel(p, 'Text', 'Belum ada citra dimuat.', ...
    'HorizontalAlignment', 'left', 'FontSize', 10, ...
    'FontColor', [0.2 0.2 0.2]);

app.PeaksButton = uibutton(p, 'Text', 'Find Noise Peaks', ...
    'BackgroundColor', [0.95 0.85 0.55], ...
    'Tooltip', 'Buka tab Noise Peaks untuk mendeteksi titik noise periodik pada spektrum', ...
    'Enable', 'off', ...
    'ButtonPushedFcn', @(~, ~) onOpenPeaksTab(app));

% --- 2. pilih metode -------------------------------------------------------
uilabel(p, 'Text', '2. METODE', 'FontWeight', 'bold', ...
    'FontColor', [0.15 0.25 0.45]);

app.MethodBox = uidropdown(p, ...
    'Items', {'Lowpass Filter (Smoothing)', ...
              'Highpass Filter', ...
              'Brightness', ...
              'Notch / Band Filter (Periodic Noise)', ...
              'Motion Blur Restoration'}, ...
    'ItemsData', {'lowpass', 'highpass', 'brightness', 'notch', 'motion'}, ...
    'Value', 'lowpass', ...
    'BackgroundColor', 'w');
app.MethodBox.ValueChangedFcn = @(~, ~) onMethodChanged(app);

% --- panel parameter per metode (hanya satu terlihat) -----------------------
app.ParamStack = uigridlayout(p, [4 1]);
app.ParamStack.RowHeight = {'1x', '1x', '1x', '1x'};
app.ParamStack.RowSpacing = 0;
app.ParamStack.Padding = [0 0 0 0];
app.ParamStack.BackgroundColor = [0.96 0.96 0.96];

app = buildPassPanel(app);
app = buildBrightnessPanel(app);
app = buildNotchPanel(app);
app = buildMotionPanel(app);

% --- 3. aksi ---------------------------------------------------------------
actionRow = uigridlayout(p, [1 3]);
actionRow.ColumnWidth = {'1x', '1x', '1x'};
actionRow.ColumnSpacing = 6;
actionRow.Padding = [0 0 0 0];
actionRow.BackgroundColor = [0.96 0.96 0.96];

uibutton(actionRow, 'Text', 'Terapkan', ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.20 0.55 0.35], ...
    'FontColor', 'w', ...
    'Tooltip', 'Terapkan metode ke hasil terakhir (atau citra masukan kalau belum ada hasil)', ...
    'ButtonPushedFcn', @(~, ~) onApply(app));
app.UndoButton = uibutton(actionRow, 'Text', 'Undo', ...
    'BackgroundColor', [0.85 0.85 0.85], ...
    'Tooltip', 'Batalkan langkah terakhir (Terapkan atau Reset)', ...
    'Enable', 'off', ...
    'ButtonPushedFcn', @(~, ~) onUndo(app));
uibutton(actionRow, 'Text', 'Reset', ...
    'BackgroundColor', [0.85 0.85 0.85], ...
    'Tooltip', 'Buang semua langkah, kembali ke citra masukan', ...
    'ButtonPushedFcn', @(~, ~) onReset(app));
end

% ---------------------------------------------------------------------------
function app = buildPassPanel(app)
% panel bersama untuk Lowpass dan Highpass (parameternya sama)

pnl = uipanel(app.ParamStack, 'Title', '', 'BorderType', 'line', ...
    'BackgroundColor', [0.99 0.99 0.99]);
pnl.Layout.Row = 1;
app.Panels.pass = pnl;

g = uigridlayout(pnl, [4 2]);
g.RowHeight   = {26, 26, 26, '1x'};
g.ColumnWidth = {110, '1x'};
g.RowSpacing  = 8;
g.ColumnSpacing = 6;
g.Padding = [10 10 10 10];
g.BackgroundColor = [0.99 0.99 0.99];

uilabel(g, 'Text', 'Bentuk');
app.PassShape = uidropdown(g, ...
    'Items', {'Ideal', 'Gaussian', 'Butterworth'}, ...
    'ItemsData', {'ideal', 'gaussian', 'butterworth'}, ...
    'Value', 'gaussian', ...
    'BackgroundColor', 'w');
app.PassShape.ValueChangedFcn = @(~, ~) onPassFieldChanged(app);

uilabel(g, 'Text', 'Diameter');
app.PassDiameter = uispinner(g, 'Value', 120, 'Limits', [1 Inf], 'Step', 5, ...
    'Tooltip', 'Diameter area cutoff di spektrum ter-pad (D0 = diameter / 2)');
app.PassDiameter.ValueChangedFcn = @(~, ~) refreshFilterPreview(app);

uilabel(g, 'Text', 'Orde n');
app.PassOrder = uispinner(g, 'Value', 2, 'Limits', [1 Inf], 'Step', 1, ...
    'Tooltip', 'Orde Butterworth: makin besar makin tajam (mendekati ideal)');
app.PassOrder.ValueChangedFcn = @(~, ~) refreshFilterPreview(app);

hint = uilabel(g, 'Text', ['Filter berpusat di tengah spektrum. Diameter memakai ' ...
    'koordinat spektrum citra yang sudah di-pad 2x, sama dengan sumbu u,v di ' ...
    'tab Utama. Lihat bentuknya di tab Filter H.'], ...
    'WordWrap', 'on', 'FontSize', 10, 'FontColor', [0.3 0.3 0.3], ...
    'VerticalAlignment', 'top');
hint.Layout.Row = 4;
hint.Layout.Column = [1 2];
end

% ---------------------------------------------------------------------------
function app = buildBrightnessPanel(app)

pnl = uipanel(app.ParamStack, 'Title', '', 'BorderType', 'line', ...
    'BackgroundColor', [0.99 0.99 0.99]);
pnl.Layout.Row = 2;
app.Panels.brightness = pnl;

g = uigridlayout(pnl, [2 2]);
g.RowHeight   = {26, '1x'};
g.ColumnWidth = {110, '1x'};
g.RowSpacing  = 8;
g.ColumnSpacing = 6;
g.Padding = [10 10 10 10];
g.BackgroundColor = [0.99 0.99 0.99];

uilabel(g, 'Text', 'Target mean');
app.TargetMean = uispinner(g, 'Value', 0.48, 'Limits', [0.01 1], 'Step', 0.02, ...
    'Tooltip', 'Rata-rata kecerahan citra hasil, skala 0..1');

hint = uilabel(g, 'Text', ['Seluruh spektrum dikali satu alpha = target mean / ' ...
    'rata-rata sekarang (dihitung dari komponen DC), jadi rasio R:G:B tidak berubah.'], ...
    'WordWrap', 'on', 'FontSize', 10, 'FontColor', [0.3 0.3 0.3], ...
    'VerticalAlignment', 'top');
hint.Layout.Row = 2;
hint.Layout.Column = [1 2];
end

% ---------------------------------------------------------------------------
function app = buildNotchPanel(app)
% filter builder: beberapa filter (card per tipe) disatukan lewat buildFilter.m

pnl = uipanel(app.ParamStack, 'Title', '', 'BorderType', 'line', ...
    'BackgroundColor', [0.99 0.99 0.99]);
pnl.Layout.Row = 3;
app.Panels.notch = pnl;

g = uigridlayout(pnl, [3 1]);
g.RowHeight = {26, 26, '1x'};
g.RowSpacing = 6;
g.Padding = [6 6 6 6];
g.BackgroundColor = [0.99 0.99 0.99];

% --- mode gabungan: satu switch untuk seluruh filter ------------------------
modeRow = uigridlayout(g, [1 4]);
modeRow.ColumnWidth = {34, '1x', 44, 74};
modeRow.ColumnSpacing = 4;
modeRow.Padding = [0 0 0 0];
modeRow.BackgroundColor = [0.99 0.99 0.99];

uilabel(modeRow, 'Text', 'Mode');
app.NotchMode = uidropdown(modeRow, ...
    'Items', {'Reject (F x H)', 'Pass (kurangi pola noise)'}, ...
    'ItemsData', {'reject', 'pass'}, ...
    'Value', 'reject', ...
    'BackgroundColor', 'w', ...
    'Tooltip', ['Reject: tiap filter meredam areanya, hasil = F x H. ' ...
                'Pass: tiap filter meloloskan areanya (H = 1 - H reject), pola noise ' ...
                'yang lolos dikurangkan dari citra.']);
app.NotchMode.ValueChangedFcn = @(~, ~) onNotchModeChanged(app);

uilabel(modeRow, 'Text', 'Weight', 'HorizontalAlignment', 'right');
app.NotchWeight = uispinner(modeRow, 'Value', 1, 'Limits', [0 Inf], 'Step', 0.05, ...
    'Enable', 'off', ...
    'Tooltip', 'Mode pass: hasil = citra - weight x pola noise');

% --- tambah card filter ----------------------------------------------------
catalog = filterCatalog();
addRow = uigridlayout(g, [1 2]);
addRow.ColumnWidth = {'1x', 100};
addRow.ColumnSpacing = 4;
addRow.Padding = [0 0 0 0];
addRow.BackgroundColor = [0.99 0.99 0.99];

app.NotchTypeBox = uidropdown(addRow, ...
    'Items', {catalog.label}, ...
    'ItemsData', {catalog.type}, ...
    'Value', 'butterworth', ...
    'BackgroundColor', 'w', ...
    'Tooltip', 'Tipe filter yang ditambahkan (sama dengan type di buildFilter.m)');
uibutton(addRow, 'Text', '+ Add Filter', ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.75 0.85 0.95], ...
    'Tooltip', 'Buat card untuk tipe terpilih. Baris filter ditambah lewat tombol Add di card.', ...
    'ButtonPushedFcn', @(~, ~) onAddCard(app));

% --- daftar card (bisa di-scroll) -------------------------------------------
app.CardHost = uigridlayout(g, [1 1]);
app.CardHost.ColumnWidth = {'1x'};
app.CardHost.RowSpacing = 6;
app.CardHost.Padding = [2 2 2 2];
app.CardHost.Scrollable = 'on';
app.CardHost.BackgroundColor = [0.99 0.99 0.99];

renderNotchCards(app);
end

% ---------------------------------------------------------------------------
function app = buildMotionPanel(app)

pnl = uipanel(app.ParamStack, 'Title', '', 'BorderType', 'line', ...
    'BackgroundColor', [0.99 0.99 0.99]);
pnl.Layout.Row = 4;
app.Panels.motion = pnl;

g = uigridlayout(pnl, [5 2]);
g.RowHeight   = {26, 26, 26, 26, '1x'};
g.ColumnWidth = {110, '1x'};
g.RowSpacing  = 8;
g.ColumnSpacing = 6;
g.Padding = [10 10 10 10];
g.BackgroundColor = [0.99 0.99 0.99];

uilabel(g, 'Text', 'Restorasi');
app.MotionMethod = uidropdown(g, ...
    'Items', {'Wiener filtering', 'Inverse filtering'}, ...
    'ItemsData', {'wiener', 'inverse'}, ...
    'Value', 'wiener', ...
    'BackgroundColor', 'w');
app.MotionMethod.ValueChangedFcn = @(~, ~) updateMotionFields(app);

uilabel(g, 'Text', 'Panjang L');
app.MotionL = uispinner(g, 'Value', 15, 'Limits', [1 Inf], 'Step', 1, ...
    'Tooltip', 'Panjang pergerakan (piksel). Terisi otomatis kalau nama file memuat _L..');
app.MotionL.ValueChangedFcn = @(~, ~) refreshFilterPreview(app);

uilabel(g, 'Text', 'Sudut theta');
app.MotionTheta = uispinner(g, 'Value', 0, 'Limits', [-180 180], 'Step', 1, ...
    'Tooltip', 'Sudut arah pergerakan (derajat). Terisi otomatis kalau nama file memuat _A..');
app.MotionTheta.ValueChangedFcn = @(~, ~) refreshFilterPreview(app);

% satu sel untuk parameter: field yang tampil bergantung pada metode restorasi
app.MotionParamLabel = uilabel(g, 'Text', 'K (NSR)');
paramCell = uigridlayout(g, [1 1]);
paramCell.Padding = [0 0 0 0];
paramCell.BackgroundColor = [0.99 0.99 0.99];
app.MotionK = uieditfield(paramCell, 'numeric', 'Value', 0.01, ...
    'Limits', [0 Inf], 'ValueDisplayFormat', '%g', ...
    'Tooltip', 'Wiener: perkiraan noise-to-signal ratio. Makin besar makin halus, makin kecil makin tajam tapi noise naik.');
app.MotionK.Layout.Row = 1;
app.MotionK.Layout.Column = 1;
app.MotionThreshold = uieditfield(paramCell, 'numeric', 'Value', 0.01, ...
    'Limits', [0 Inf], 'LowerLimitInclusive', 'off', 'ValueDisplayFormat', '%g', ...
    'Tooltip', 'Inverse: |H| di bawah ambang ini tidak dibalik supaya noise tidak meledak.');
app.MotionThreshold.Layout.Row = 1;
app.MotionThreshold.Layout.Column = 1;

hint = uilabel(g, 'Text', ['PSF dibentuk dari L dan theta (motionBlurPSF.m) pada ukuran ' ...
    'citra asli, tanpa padding. |H| bisa dilihat di tab Filter H.'], ...
    'WordWrap', 'on', 'FontSize', 10, 'FontColor', [0.3 0.3 0.3], ...
    'VerticalAlignment', 'top');
hint.Layout.Row = 5;
hint.Layout.Column = [1 2];
end

% ---------------------------------------------------------------------------
function app = buildRightPanel(app)

host = uigridlayout(app.RightPanel, [1 1]);
host.Padding = [0 0 0 0];
host.BackgroundColor = [0.94 0.94 0.94];

app.TabGroup  = uitabgroup(host);
app.MainTab   = uitab(app.TabGroup, 'Title', 'Utama');
app.FilterTab = uitab(app.TabGroup, 'Title', 'Filter H');

buildMainTab(app);
buildFilterTab(app);
% tab Noise Peaks baru dibuat saat tombol Find Noise Peaks ditekan (buildPeaksTab)
end

% ---------------------------------------------------------------------------
function app = buildMainTab(app)

g = uigridlayout(app.MainTab, [3 3]);
g.ColumnWidth = {'1x', '1x', '1x'};
g.RowHeight   = {'1x', '1x', 170};
g.RowSpacing  = 6;
g.ColumnSpacing = 6;
g.Padding = [6 6 6 6];
g.BackgroundColor = [0.94 0.94 0.94];

% baris 1: citra sebelum | sesudah | referensi
app.AxImageIn  = makeImageAxes(app, makeDisplayPanel(g, 'CITRA MASUKAN',   1, 1));
app.AxImageOut = makeImageAxes(app, makeDisplayPanel(g, 'CITRA HASIL',     1, 2));
app.AxImageRef = makeImageAxes(app, makeDisplayPanel(g, 'CITRA REFERENSI', 1, 3));

% baris 2: spektrum Fourier ketiganya (citra di-pad 2x, sumbu u,v)
app.AxSpecIn  = makeSpectrumAxes(app, makeDisplayPanel(g, 'SPEKTRUM FOURIER - MASUKAN',   2, 1));
app.AxSpecOut = makeSpectrumAxes(app, makeDisplayPanel(g, 'SPEKTRUM FOURIER - HASIL',     2, 2));
app.AxSpecRef = makeSpectrumAxes(app, makeDisplayPanel(g, 'SPEKTRUM FOURIER - REFERENSI', 2, 3));

% baris 3: daftar peaks + log. Grid sendiri supaya tabel peaks punya lebar
% tetap yang cukup untuk kelima kolomnya, tidak ikut sepertiga lebar tab
bottom = uigridlayout(g, [1 2]);
bottom.Layout.Row = 3;
bottom.Layout.Column = [1 3];
bottom.ColumnWidth = {370, '1x'};
bottom.ColumnSpacing = 6;
bottom.Padding = [0 0 0 0];
bottom.BackgroundColor = [0.94 0.94 0.94];

peaksPanel = makeDisplayPanel(bottom, 'NOISE PEAKS', 1, 1);
peaksPanel.Tooltip = 'Hasil Find Noise Peaks. Koordinat u,v sama dengan sumbu spektrum.';
app.PeaksTableMain = makePeaksTable(peaksPanel);

logPanel = makeDisplayPanel(bottom, 'LANGKAH, PARAMETER & KUALITAS', 1, 2);
logPanel.Tooltip = '';
inner = uigridlayout(logPanel, [1 1]);
inner.Padding = [0 2 0 2];
inner.BackgroundColor = 'w';
app.LogText = uitextarea(inner, ...
    'Value', {'Muat citra dulu, lalu pilih metode.'}, ...
    'Editable', 'off', 'FontSize', 10, ...
    'BackgroundColor', [1 1 1]);
end

% ---------------------------------------------------------------------------
function app = buildFilterTab(app)

g = uigridlayout(app.FilterTab, [3 2]);
g.ColumnWidth = {'1x', '1x'};
g.RowHeight   = {20, '1x', 200};
g.RowSpacing  = 6;
g.ColumnSpacing = 6;
g.Padding = [6 6 6 6];
g.BackgroundColor = [0.94 0.94 0.94];

app.FilterStatus = uilabel(g, 'Text', '', 'FontSize', 11, ...
    'FontColor', [0.2 0.2 0.2]);
app.FilterStatus.Layout.Row = 1;
app.FilterStatus.Layout.Column = [1 2];

% baris 2: H dan spektrum yang sudah dikali H
app.AxFilterH    = makeSpectrumAxes(app, makeDisplayPanel(g, 'FILTER H', 2, 1));
app.AxFilterSpec = makeSpectrumAxes(app, makeDisplayPanel(g, 'SPEKTRUM SETELAH FILTER', 2, 2));

% baris 3: daftar peaks + pola noise mode pass
peaksPanel = makeDisplayPanel(g, 'NOISE PEAKS', 3, 1);
peaksPanel.Tooltip = 'Hasil Find Noise Peaks. Lingkaran merah di gambar H menandai posisinya.';
app.PeaksTableFilter = makePeaksTable(peaksPanel);

app.AxNoise = makeImageAxes(app, makeDisplayPanel(g, ...
    'POLA NOISE YANG DIKURANGKAN (mode pass, setelah Terapkan)', 3, 2));
end

% ---------------------------------------------------------------------------
function app = buildPeaksTab(app)

app.PeaksTab = uitab(app.TabGroup, 'Title', 'Noise Peaks');

g = uigridlayout(app.PeaksTab, [1 3]);
g.ColumnWidth = {210, '1x', 370};
g.ColumnSpacing = 6;
g.Padding = [6 6 6 6];
g.BackgroundColor = [0.94 0.94 0.94];

% --- kolom 1: parameter findNoisePeaks --------------------------------------
formPanel = makeDisplayPanel(g, 'PARAMETER DETEKSI', 1, 1);
formPanel.Tooltip = '';

f = uigridlayout(formPanel, [6 2]);
f.RowHeight   = {26, 26, 26, 26, 30, '1x'};
f.ColumnWidth = {100, '1x'};
f.RowSpacing  = 8;
f.ColumnSpacing = 6;
f.Padding = [8 8 8 8];
f.BackgroundColor = 'w';

% nilai awal sama dengan default findNoisePeaks.m
uilabel(f, 'Text', 'Exclude Radius');
app.PeakExclude = uispinner(f, 'Value', 20, 'Limits', [0 Inf], 'Step', 1, ...
    'Tooltip', 'Radius area pusat (sekitar DC) yang tidak ikut dicari');

uilabel(f, 'Text', 'Min Distance');
app.PeakMinDist = uispinner(f, 'Value', 16, 'Limits', [0 Inf], 'Step', 1, ...
    'Tooltip', 'Jarak minimum antar peak; kandidat yang lebih dekat dari ini dibuang');

uilabel(f, 'Text', 'Max Peaks');
app.PeakMax = uispinner(f, 'Value', 10, 'Limits', [1 Inf], 'Step', 1, ...
    'RoundFractionalValues', 'on', ...
    'Tooltip', 'Jumlah peak terbanyak yang diambil (magnitude tertinggi dulu)');

uilabel(f, 'Text', 'Threshold Std');
app.PeakThresh = uispinner(f, 'Value', 3, 'Limits', [0 Inf], 'Step', 0.5, ...
    'Tooltip', 'Ambang = rata-rata + ThresholdStd x simpangan baku magnitude');

btn = uibutton(f, 'Text', 'Find', ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.20 0.55 0.35], ...
    'FontColor', 'w', ...
    'ButtonPushedFcn', @(~, ~) onFindPeaks(app));
btn.Layout.Column = [1 2];

app.PeakStatus = uilabel(f, 'Text', 'Isi parameter lalu tekan Find.', ...
    'WordWrap', 'on', 'FontSize', 10, 'FontColor', [0.3 0.3 0.3], ...
    'VerticalAlignment', 'top');
app.PeakStatus.Layout.Column = [1 2];

% --- kolom 2: spektrum dengan peaks dilingkari ------------------------------
app.AxPeaks = makeSpectrumAxes(app, makeDisplayPanel(g, ...
    'SPEKTRUM CITRA KERJA (di-pad 2x) + NOISE PEAKS', 1, 2));

% --- kolom 3: daftar peaks -------------------------------------------------
tblPanel = makeDisplayPanel(g, 'DAFTAR NOISE PEAKS', 1, 3);
tblPanel.Tooltip = 'Nomor baris sama dengan nomor kuning di samping lingkaran pada spektrum.';
app.PeaksTableTab = makePeaksTable(tblPanel);
end

% ---------------------------------------------------------------------------
function pnl = makeDisplayPanel(parent, title, row, col)
pnl = uipanel(parent, 'Title', title, 'FontSize', 10, ...
    'FontWeight', 'bold', ...
    'BorderType', 'line', 'BackgroundColor', 'w', ...
    'Tooltip', 'Klik kanan pada gambar lalu pilih "Salin gambar" untuk menyalinnya ke clipboard');
pnl.Layout.Row = row;
pnl.Layout.Column = col;
end

% ---------------------------------------------------------------------------
function ax = makeImageAxes(app, parent)
% axes biasa dengan posisi eksplisit supaya citra mengisi panel
ax = axes('Parent', parent);
ax.Position = [0.02, 0.02, 0.96, 0.96];
ax.Visible = 'off';
attachCopyMenu(app, ax);
end

function ax = makeSpectrumAxes(app, parent)
% uiaxes di dalam grid supaya label sumbu u,v tidak terpotong
lay = uigridlayout(parent, [1 1]);
lay.Padding = [2 2 2 2];
lay.BackgroundColor = 'w';
ax = uiaxes(lay);
ax.Layout.Row = 1;
ax.Layout.Column = 1;
hideAxes(ax);
attachCopyMenu(app, ax);
end

function tbl = makePeaksTable(parent)
% tabel peaks; isinya sama di tab Utama, Filter H, dan Noise Peaks
lay = uigridlayout(parent, [1 1]);
lay.Padding = [0 0 0 0];
lay.BackgroundColor = 'w';
tbl = uitable(lay, ...
    'ColumnName', {'No', 'u', 'v', 'Jarak (D0)', 'Magnitude'}, ...
    'ColumnFormat', {'numeric', 'numeric', 'numeric', 'bank', 'bank'}, ...
    'ColumnWidth', {30, '2x', '2x', '3x', '3x'}, ...
    'RowName', {}, ...
    'Data', zeros(0, 5), ...
    'FontSize', 10, ...
    'BackgroundColor', 'w');
end

function attachCopyMenu(app, ax)
% menu klik kanan "Salin gambar" untuk axes citra/spektrum
cm = uicontextmenu(app.Figure);
uimenu(cm, 'Text', 'Salin gambar', ...
    'MenuSelectedFcn', @(~, ~) onCopyAxes(app, ax));
ax.ContextMenu = cm;
end

% ===========================================================================
% Filter builder (card per tipe filter)
% ===========================================================================

function catalog = filterCatalog()
% daftar tipe filter di builder beserta input tiap barisnya. Nama field sama
% dengan field filterList di buildFilter.m, jadi baris bisa langsung dikirim.
%   .fields     : nama field per input (urut tampil)
%   .labels     : teks di depan tiap spinner
%   .defaults   : nilai awal baris baru
%   .steps      : langkah panah spinner
%   .lows       : batas bawah nilai
%   .split      : jumlah input di baris pertama, sisanya turun ke baris kedua
%   .line2Label : teks di depan baris kedua
%   .isPoint    : true = filter titik, bisa diisi dari hasil Find Noise Peaks
point    = {'u0', 'v0', 'diameter'};
pointLbl = {'u', 'v', 'D'};
band     = {'u0', 'v0', 'diameter', 'width'};
bandLbl  = {'u', 'v', 'D', 'W'};
lineFld  = {'position', 'width', 'blur', 'breakPos', 'breakRadius', 'breakBlur'};
lineLbl  = {'pos', 'lebar', 'blur', 'pos', 'radius', 'blur'};

catalog = [ ...
    makeType('ideal',            'Ideal',            point,         pointLbl,        [0 0 20],       [1 1 2],     [-Inf -Inf 1],     3, '',       true)
    makeType('gaussian',         'Gaussian',         point,         pointLbl,        [0 0 20],       [1 1 2],     [-Inf -Inf 1],     3, '',       true)
    makeType('butterworth',      'Butterworth',      [point {'n'}], [pointLbl {'n'}], [0 0 20 2],    [1 1 2 1],   [-Inf -Inf 1 1],   4, '',       true)
    makeType('band_ideal',       'Band Ideal',       band,          bandLbl,         [0 0 100 10],   [1 1 2 1],   [-Inf -Inf 1 1],   3, '',       false)
    makeType('band_gaussian',    'Band Gaussian',    band,          bandLbl,         [0 0 100 10],   [1 1 2 1],   [-Inf -Inf 1 1],   3, '',       false)
    makeType('band_butterworth', 'Band Butterworth', [band {'n'}],  [bandLbl {'n'}], [0 0 100 10 2], [1 1 2 1 1], [-Inf -Inf 1 1 1], 3, '',       false)
    makeType('notchline',        'Notch Line',       lineFld,       lineLbl,         [0 8 0 0 0 0],  [1 1 0.1 1 1 0.1], [-Inf 0 0 -Inf 0 0], 3, 'putus:', false)];
end

function t = makeType(type, label, fields, labels, defaults, steps, lows, split, line2Label, isPoint)
t = struct('type', type, 'label', label, 'fields', {fields}, 'labels', {labels}, ...
    'defaults', defaults, 'steps', steps, 'lows', lows, 'split', split, ...
    'line2Label', line2Label, 'isPoint', isPoint);
end

function info = catalogEntry(type)
catalog = filterCatalog();
info = catalog(strcmp({catalog.type}, type));
end

function tip = fieldTooltip(name)
switch name
    case 'u0',          tip = 'Posisi horizontal pusat filter, relatif ke tengah spektrum (kolom u di tabel peaks)';
    case 'v0',          tip = 'Posisi vertikal pusat filter, relatif ke tengah spektrum (kolom v di tabel peaks)';
    case 'diameter',    tip = 'Diameter area filter (D0 = D / 2). Untuk filter pita: diameter cincin';
    case 'n',           tip = 'Orde Butterworth: makin besar makin tajam';
    case 'width',       tip = 'Lebar pita / lebar garis';
    case 'position',    tip = 'Posisi garis: horizontal = di sumbu v, vertical = di sumbu u';
    case 'blur',        tip = '0 = tepi garis tegas, > 0 = tepi buram (n = 1 / blur)';
    case 'breakPos',    tip = 'Pusat lingkaran pemutus garis di sumbu bebas garis';
    case 'breakRadius', tip = 'Radius lingkaran pemutus garis (0 = garis tidak diputus)';
    case 'breakBlur',   tip = '0 = tepi lingkaran pemutus tegas, > 0 = buram';
    otherwise,          tip = '';
end
end

function row = defaultRow(info)
% baris baru dengan nilai awal dari katalog
row = struct();
for k = 1:numel(info.fields)
    row.(info.fields{k}) = info.defaults(k);
end
if strcmp(info.type, 'notchline')
    row.orientation = 'horizontal';
end
end

function list = cardsToFilterList(app)
% ubah model card jadi filterList (cell array of struct) untuk buildFilter.m.
% Flag pass/reject tidak diisi: mengikuti mode gabungan yang dipilih.
list = {};
for c = 1:numel(app.NotchCards)
    rows = app.NotchCards(c).rows;
    for r = 1:numel(rows)
        spec = rows(r);
        spec.type = app.NotchCards(c).type;
        list{end + 1} = spec; %#ok<AGROW>
    end
end
end

% ---------------------------------------------------------------------------
function renderNotchCards(app)
% gambar ulang semua card dari model app.NotchCards. Dipanggil hanya saat
% struktur berubah (tambah/hapus); perubahan nilai cukup mengubah model.
delete(app.CardHost.Children);

n = numel(app.NotchCards);
if n == 0
    app.CardHost.RowHeight = {60};
    uilabel(app.CardHost, ...
        'Text', ['Belum ada filter. Pilih tipe lalu tekan "+ Add Filter", ' ...
                 'kemudian tambah baris lewat tombol Add di card.'], ...
        'WordWrap', 'on', 'FontSize', 10, 'FontColor', [0.4 0.4 0.4], ...
        'VerticalAlignment', 'top');
    return;
end

app.CardHost.RowHeight = repmat({30}, 1, n);
heights = cell(1, n);
for c = 1:n
    heights{c} = makeCard(app, c, catalogEntry(app.NotchCards(c).type));
end
app.CardHost.RowHeight = heights;
end

function tinggi = makeCard(app, c, info)
% satu card = header (nama tipe + tombol) dan satu baris input per filter
rows   = app.NotchCards(c).rows;
nRows  = numel(rows);
nLines = 1 + (info.split < numel(info.fields));
rowH   = nLines * 24 + (nLines - 1) * 2;
tinggi = 12 + 24 + nRows * (rowH + 4) + 6;     % padding + header + baris + border

pnl = uipanel(app.CardHost, 'Title', '', 'BorderType', 'line', ...
    'BackgroundColor', 'w');
pnl.Layout.Row = c;
pnl.Layout.Column = 1;

g = uigridlayout(pnl, [1 + nRows, 1]);
g.RowHeight = [{24}, repmat({rowH}, 1, nRows)];
g.RowSpacing = 4;
g.Padding = [6 6 6 6];
g.BackgroundColor = 'w';

% --- header ---
if info.isPoint
    widths = {'1x', 54, 80, 54};
else
    widths = {'1x', 54, 54};
end
head = uigridlayout(g, [1 numel(widths)]);
head.Layout.Row = 1;
head.ColumnWidth = widths;
head.ColumnSpacing = 4;
head.Padding = [0 0 0 0];
head.BackgroundColor = 'w';

uilabel(head, 'Text', sprintf('%s (%d)', info.label, nRows), ...
    'FontWeight', 'bold', 'FontColor', [0.15 0.25 0.45]);
uibutton(head, 'Text', '+ Add', ...
    'BackgroundColor', [0.75 0.85 0.95], ...
    'Tooltip', 'Tambah satu baris filter di card ini', ...
    'ButtonPushedFcn', @(~, ~) onAddRow(app, c));
if info.isPoint
    uibutton(head, 'Text', 'Dari Peaks', ...
        'BackgroundColor', [0.95 0.85 0.55], ...
        'Tooltip', 'Buat satu baris untuk tiap noise peak hasil Find Noise Peaks', ...
        'ButtonPushedFcn', @(~, ~) onFillFromPeaks(app, c));
end
uibutton(head, 'Text', 'Hapus', ...
    'BackgroundColor', [0.95 0.75 0.75], ...
    'Tooltip', 'Hapus card ini beserta semua barisnya', ...
    'ButtonPushedFcn', @(~, ~) onDeleteCard(app, c));

% --- baris filter ---
for r = 1:nRows
    makeRow(app, g, c, r, info);
end
end

function makeRow(app, parent, c, r, info)
% satu baris input filter: label + spinner per field, tombol hapus di ujung
row     = app.NotchCards(c).rows(r);
nFields = numel(info.fields);
nLines  = 1 + (info.split < nFields);
isLine  = strcmp(info.type, 'notchline');

host = uigridlayout(parent, [nLines 1]);
host.Layout.Row = r + 1;
host.RowHeight = repmat({24}, 1, nLines);
host.RowSpacing = 2;
host.Padding = [0 0 0 0];
host.BackgroundColor = 'w';

% --- baris pertama ---
first  = 1:info.split;
widths = [repmat({'fit', '1x'}, 1, numel(first)), {24}];
if isLine
    widths = [{88}, widths];
end
line1 = makeRowLine(host, widths);

if isLine
    dd = uidropdown(line1, 'Items', {'horizontal', 'vertical'}, ...
        'Value', row.orientation, 'BackgroundColor', 'w', ...
        'Tooltip', 'Arah garis notch');
    dd.ValueChangedFcn = @(src, ~) onRowFieldChanged(app, c, r, 'orientation', src.Value);
end
for k = first
    addRowField(app, line1, c, r, info, k, row);
end
uibutton(line1, 'Text', 'x', 'FontWeight', 'bold', ...
    'FontColor', [0.7 0.1 0.1], ...
    'Tooltip', 'Hapus baris ini', ...
    'ButtonPushedFcn', @(~, ~) onDeleteRow(app, c, r));

% --- baris kedua (kalau input tidak muat sebaris) ---
if nLines == 2
    rest   = (info.split + 1):nFields;
    widths = [{40}, repmat({'fit', '1x'}, 1, numel(rest)), {24}];
    line2  = makeRowLine(host, widths);
    uilabel(line2, 'Text', info.line2Label, 'FontSize', 10, ...
        'FontColor', [0.4 0.4 0.4]);
    for k = rest
        addRowField(app, line2, c, r, info, k, row);
    end
end
end

function g = makeRowLine(parent, widths)
g = uigridlayout(parent, [1 numel(widths)]);
g.ColumnWidth = widths;
g.ColumnSpacing = 3;
g.Padding = [0 0 0 0];
g.BackgroundColor = 'w';
end

function addRowField(app, parent, c, r, info, k, row)
name = info.fields{k};
uilabel(parent, 'Text', info.labels{k}, 'HorizontalAlignment', 'right');
sp = uispinner(parent, 'Value', row.(name), 'Step', info.steps(k), ...
    'Limits', [info.lows(k) Inf], 'Tooltip', fieldTooltip(name));
% ValueChanging ikut dipasang supaya preview H berubah selama panah ditahan
sp.ValueChangedFcn  = @(~, evt) onRowFieldChanged(app, c, r, name, evt.Value);
sp.ValueChangingFcn = @(~, evt) onRowFieldChanged(app, c, r, name, evt.Value);
end

% ===========================================================================
% Callback
% ===========================================================================

function onFolderChanged(app)
k = find(strcmp({app.DatasetIdx.folder}, app.FolderBox.Value), 1);
if isempty(k), return; end
app.ImageBox.Items = app.DatasetIdx(k).files;
if ~isempty(app.DatasetIdx(k).files)
    app.ImageBox.Value = app.DatasetIdx(k).files{1};
end
end

function loadSelectedImage(app)
k = find(strcmp({app.DatasetIdx.folder}, app.FolderBox.Value), 1);
file = app.ImageBox.Value;
if isempty(k) || isempty(file)
    uialert(app.Figure, ['Tidak ada citra dataset yang terpilih. Pastikan folder ' ...
        '02_citra_test_images ada, atau pakai "Dari File...".'], 'Citra tidak bisa dimuat');
    return;
end

try
    img = imread(fullfile(app.DatasetIdx(k).path, file));
    [ref, refName] = readReference(app.DatasetIdx(k), file);
catch ex
    uialert(app.Figure, sprintf('Gagal membaca citra:\n%s', ex.message), ...
        'Citra tidak bisa dimuat');
    return;
end

setLoadedImage(app, img, ref, file, refName);
end

function onOpenImageFile(app)
% Buka dialog untuk memilih citra dari file eksternal
[fileName, pathName] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff', ...
    'File citra (*.png, *.jpg, *.bmp, *.tif)'; '*.*', 'Semua file'}, ...
    'Pilih citra');
figure(app.Figure);     % uigetfile memindahkan fokus dari uifigure

if isequal(fileName, 0), return; end   % pengguna membatalkan

try
    img = imread(fullfile(pathName, fileName));
catch ex
    uialert(app.Figure, sprintf('Gagal membaca citra:\n%s', ex.message), ...
        'Citra tidak bisa dimuat');
    return;
end

setLoadedImage(app, img, [], fileName, '');
end

function setLoadedImage(app, img, ref, fileName, refName)
% pasang citra baru sebagai masukan dan kosongkan semua hasil sebelumnya
app.Original  = toUint8Image(img);
app.Reference = toUint8Image(ref);
app.Result    = [];
app.Steps     = {};
app.Peaks     = [];
app.NoisePattern = [];
resetHistory(app);

fillMotionFromName(app, fileName);

if size(app.Original, 3) == 3
    jenis = 'RGB';
else
    jenis = 'Abu-abu';
end
info = sprintf('%s %dx%d', jenis, size(app.Original, 1), size(app.Original, 2));
if ~isempty(refName)
    info = sprintf('%s | referensi: %s', info, refName);
else
    info = sprintf('%s | tanpa referensi', info);
end
app.InfoLabel.Text = info;
app.InfoLabel.Tooltip = sprintf('%s (%s)', fileName, info);
app.PeaksButton.Enable = 'on';

if ~isempty(app.PeakStatus) && isvalid(app.PeakStatus)
    app.PeakStatus.Text = 'Citra baru dimuat. Tekan Find untuk mendeteksi peaks.';
end

updateWorkingSpectrum(app);
refreshAll(app);
end

function [ref, refName] = readReference(entry, file)
% referensi = file di subfolder reference yang namanya menjadi awalan nama
% citra masukan, misal brick_gray_periodic_noise.png -> brick_gray.png
ref = [];
refName = '';
[~, base] = fileparts(file);

panjang = 0;
for k = 1:numel(entry.refFiles)
    [~, refBase] = fileparts(entry.refFiles{k});
    if startsWith(base, refBase) && numel(refBase) > panjang
        refName = entry.refFiles{k};
        panjang = numel(refBase);
    end
end

if ~isempty(refName)
    ref = imread(fullfile(entry.refPath, refName));
end
end

function img = toUint8Image(img)
% samakan semua citra ke uint8 grayscale/RGB supaya pipeline konsisten
if isempty(img), return; end
if size(img, 3) > 3
    img = img(:, :, 1:3);       % buang kanal alpha
end
if ~isa(img, 'uint8')
    img = im2uint8(img);
end
end

function fillMotionFromName(app, fileName)
% nama file kategori motion blur memuat parameternya, misal ..._motion_L19_A20.png
tok = regexp(fileName, '_L(\d+)_A(-?\d+)', 'tokens', 'once');
if isempty(tok), return; end
app.MotionL.Value     = str2double(tok{1});
app.MotionTheta.Value = str2double(tok{2});
end

function onMethodChanged(app)
method = app.MethodBox.Value;

app.Panels.pass.Visible       = any(strcmp(method, {'lowpass', 'highpass'}));
app.Panels.brightness.Visible = strcmp(method, 'brightness');
app.Panels.notch.Visible      = strcmp(method, 'notch');
app.Panels.motion.Visible     = strcmp(method, 'motion');

% uigridlayout tetap mengalokasikan tinggi untuk baris yang komponennya
% disembunyikan, jadi baris panel non-aktif dilipat supaya panel yang aktif
% mendapat seluruh ruang (penting untuk daftar card notch).
names = fieldnames(app.Panels);
for k = 1:numel(names)
    setPanelRowVisible(app, names{k}, app.Panels.(names{k}).Visible);
end

% tampilkan field yang relevan untuk metode terpilih
updatePassFields(app);
updateMotionFields(app);
refreshFilterPreview(app);
end

function onPassFieldChanged(app)
updatePassFields(app);
refreshFilterPreview(app);
end

function updatePassFields(app)
% orde n hanya dipakai filter Butterworth
app.PassOrder.Enable = strcmp(app.PassShape.Value, 'butterworth');
end

function updateMotionFields(app)
isWiener = strcmp(app.MotionMethod.Value, 'wiener');
app.MotionK.Visible         = isWiener;
app.MotionThreshold.Visible = ~isWiener;
if isWiener
    app.MotionParamLabel.Text = 'K (NSR)';
else
    app.MotionParamLabel.Text = 'Threshold |H|';
end
end

function onNotchModeChanged(app)
% weight hanya dipakai mode pass (citra - weight x pola noise)
app.NotchWeight.Enable = strcmp(app.NotchMode.Value, 'pass');
refreshFilterPreview(app);
end

% ---------------------------------------------------------------------------
% Filter builder
% ---------------------------------------------------------------------------

function onAddCard(app)
% satu card per tipe; card baru masih kosong, baris ditambah lewat tombol Add
type = app.NotchTypeBox.Value;
if any(strcmp({app.NotchCards.type}, type))
    uialert(app.Figure, ['Card untuk tipe ini sudah ada. Tambah baris filter ' ...
        'lewat tombol "+ Add" di card tersebut.'], 'Add Filter', 'Icon', 'info');
    return;
end

info = catalogEntry(type);
card = struct('type', type, 'rows', repmat(defaultRow(info), 1, 0));
app.NotchCards(end + 1) = card;

renderNotchCards(app);
refreshFilterPreview(app);
end

function onDeleteCard(app, c)
app.NotchCards(c) = [];
renderNotchCards(app);
refreshFilterPreview(app);
end

function onAddRow(app, c)
info = catalogEntry(app.NotchCards(c).type);
app.NotchCards(c).rows(end + 1) = defaultRow(info);
renderNotchCards(app);
refreshFilterPreview(app);
end

function onDeleteRow(app, c, r)
app.NotchCards(c).rows(r) = [];
renderNotchCards(app);
refreshFilterPreview(app);
end

function onRowFieldChanged(app, c, r, name, value)
% nilai baru langsung masuk model lalu preview H dihitung ulang; card tidak
% digambar ulang supaya fokus input tidak hilang
app.NotchCards(c).rows(r).(name) = value;
refreshFilterPreview(app);
end

function onFillFromPeaks(app, c)
% satu baris per noise peak; (u,v) yang sudah ada di card dilewati
if isempty(app.Peaks)
    uialert(app.Figure, ['Belum ada noise peak. Tekan "Find Noise Peaks" lalu ' ...
        '"Find" dulu.'], 'Dari Peaks', 'Icon', 'info');
    return;
end

info = catalogEntry(app.NotchCards(c).type);
rows = app.NotchCards(c).rows;
for k = 1:numel(app.Peaks)
    sudahAda = any([rows.u0] == app.Peaks(k).u & [rows.v0] == app.Peaks(k).v);
    if sudahAda
        continue;
    end
    row = defaultRow(info);
    row.u0 = app.Peaks(k).u;
    row.v0 = app.Peaks(k).v;
    rows(end + 1) = row; %#ok<AGROW>
end
app.NotchCards(c).rows = rows;

renderNotchCards(app);
refreshFilterPreview(app);
end

% ---------------------------------------------------------------------------
% Noise peaks
% ---------------------------------------------------------------------------

function onOpenPeaksTab(app)
if isempty(app.Original)
    uialert(app.Figure, 'Muat citra dulu sebelum mencari noise peaks.', ...
        'Citra belum dimuat');
    return;
end

% tab dibuat sekali, berikutnya tinggal dipilih
if isempty(app.PeaksTab) || ~isvalid(app.PeaksTab)
    buildPeaksTab(app);
    drawPeaksSpectrum(app);
    refreshPeakTables(app);
end
app.TabGroup.SelectedTab = app.PeaksTab;
end

function onFindPeaks(app)
if isempty(app.Original), return; end

% deteksi di citra kerja yang sudah di-pad 2x supaya koordinat (u,v) peaks
% sama dengan koordinat filter H
base = workingImage(app);
try
    [peaks, mag] = findNoisePeaks(padImage2x(base), ...
        'ExcludeRadius', app.PeakExclude.Value, ...
        'MinDistance',   app.PeakMinDist.Value, ...
        'MaxPeaks',      app.PeakMax.Value, ...
        'ThresholdStd',  app.PeakThresh.Value);
catch ex
    uialert(app.Figure, sprintf('Deteksi noise peaks gagal:\n%s', ex.message), ...
        'Find Noise Peaks');
    return;
end

app.Peaks   = peaks;
app.BaseMag = mag;

if isempty(app.Result)
    sumber = 'citra masukan';
else
    sumber = sprintf('hasil langkah ke-%d', numel(app.Steps));
end
if isempty(peaks)
    app.PeakStatus.Text = sprintf(['Tidak ada peak terdeteksi pada %s. ' ...
        'Turunkan Threshold Std atau Exclude Radius.'], sumber);
    app.PeakStatus.FontColor = [0.7 0.1 0.1];
else
    app.PeakStatus.Text = sprintf('%d peak terdeteksi pada %s.', numel(peaks), sumber);
    app.PeakStatus.FontColor = [0.2 0.5 0.2];
end

drawPeaksSpectrum(app);
refreshPeakTables(app);
refreshFilterPreview(app);      % tanda peaks di gambar H ikut diperbarui
end

% ---------------------------------------------------------------------------
% Terapkan, undo, reset
% ---------------------------------------------------------------------------

function onApply(app)
if isempty(app.Original)
    uialert(app.Figure, 'Muat citra dulu sebelum menerapkan metode.', ...
        'Citra belum dimuat');
    return;
end

[method, params] = collectInputs(app);

% chaining: langkah berikutnya memakai hasil sebelumnya
base = workingImage(app);

try
    [result, methodName, paramText, extra] = applyFrequencyMethod(base, method, params);
catch ex
    uialert(app.Figure, sprintf('%s\n\n%s', ex.message, ...
        'Perbaiki parameter lalu tekan Terapkan lagi.'), 'Metode gagal');
    return;
end

pushHistory(app);      % simpan keadaan sebelum langkah ini supaya bisa di-undo
app.Result = result;
app.Steps{end + 1} = sprintf('%s | %s', methodName, paramText);
app.NoisePattern = extra.noisePattern;

updateWorkingSpectrum(app);
refreshOutput(app);
app.TabGroup.SelectedTab = app.MainTab;
end

function onReset(app)
if ~isempty(app.Result)
    pushHistory(app);
end
app.Result = [];
app.Steps  = {};
app.NoisePattern = [];
updateWorkingSpectrum(app);
refreshOutput(app);
end

function n = maxHistory()
n = 20;
end

function pushHistory(app)
st.Result = app.Result;
st.Steps  = app.Steps;
st.NoisePattern = app.NoisePattern;
app.History{end + 1} = st;
if numel(app.History) > maxHistory()
    app.History(1) = [];        % buang history terlama
end
updateUndoButton(app);
end

function resetHistory(app)
app.History = {};
updateUndoButton(app);
end

function updateUndoButton(app)
if isempty(app.UndoButton) || ~isvalid(app.UndoButton)
    return;
end
if isempty(app.History)
    app.UndoButton.Enable = 'off';
else
    app.UndoButton.Enable = 'on';
end
end

function onUndo(app)
if isempty(app.History)
    return;
end
st = app.History{end};
app.History(end) = [];
app.Result = st.Result;
app.Steps  = st.Steps;      %steps juga diundo
app.NoisePattern = st.NoisePattern;
updateWorkingSpectrum(app);
refreshOutput(app);
updateUndoButton(app);
end

% ---------------------------------------------------------------------------
function onCopyAxes(app, ax)
% salin isi axes (citra atau spektrum) ke clipboard sebagai gambar
try
    copygraphics(ax, 'ContentType', 'image', 'Resolution', 300);
catch ex
    uialert(app.Figure, sprintf('Gagal menyalin gambar:\n%s', ex.message), ...
        'Salin gambar');
end
end

function closeApp(fig)
delete(fig);
end

% ===========================================================================
% Pembacaan input & penyegaran tampilan
% ===========================================================================

function [method, params] = collectInputs(app)
% method dan params sesuai daftar field di applyFrequencyMethod.m

method = app.MethodBox.Value;

switch method
    case {'lowpass', 'highpass'}
        params = struct( ...
            'shape',    app.PassShape.Value, ...
            'diameter', app.PassDiameter.Value, ...
            'n',        app.PassOrder.Value);

    case 'brightness'
        params = struct('targetMean', app.TargetMean.Value);

    case 'notch'
        params = struct( ...
            'mode',   app.NotchMode.Value, ...
            'weight', app.NotchWeight.Value);
        % diisi terpisah: struct() memecah cell array jadi struct array
        params.filterList = cardsToFilterList(app);

    case 'motion'
        params = struct( ...
            'restoration', app.MotionMethod.Value, ...
            'L',           app.MotionL.Value, ...
            'theta',       app.MotionTheta.Value, ...
            'threshold',   app.MotionThreshold.Value, ...
            'K',           app.MotionK.Value);

    otherwise
        error('FrequencyDomainApp:metodeTidakDikenal', ...
            'Metode tidak dikenal: %s', method);
end
end

function img = workingImage(app)
% citra kerja = hasil terakhir, atau citra masukan kalau belum ada hasil
img = app.Result;
if isempty(img)
    img = app.Original;
end
end

function updateWorkingSpectrum(app)
% spektrum citra kerja dipakai tab Noise Peaks dan preview "spektrum x H"
if isempty(app.Original)
    app.BaseMag = [];
else
    app.BaseMag = logSpectrum(workingImage(app), true);
end
end

function mag = logSpectrum(img, padded)
% magnitude spectrum (log-scale, terpusat) dari versi abu-abu citra.
% padded = true: citra di-pad 2x dulu, sama seperti yang dipakai filter H
if size(img, 3) == 3
    img = rgb2gray(img);
end
if padded
    img = padImage2x(img);
end
F = fft2(double(img));
F = fftshift(F);
mag = log(abs(F) + 1);
end

function refreshAll(app)
refreshInput(app);
refreshOutput(app);
end

function refreshInput(app)
% kolom masukan dan referensi hanya berubah saat citra baru dimuat
drawImage(app.AxImageIn,  app.Original);
drawImage(app.AxImageRef, app.Reference);
drawSpectrumOf(app.AxSpecIn,  app.Original,  'Masukan, di-pad 2x');
drawSpectrumOf(app.AxSpecRef, app.Reference, 'Referensi, di-pad 2x');
end

function refreshOutput(app)
% semua yang bergantung pada hasil / citra kerja
drawImage(app.AxImageOut, app.Result);
drawSpectrumOf(app.AxSpecOut, app.Result, 'Hasil, di-pad 2x');

drawNoisePattern(app);
drawPeaksSpectrum(app);
refreshPeakTables(app);
refreshFilterPreview(app);
showLog(app);
updateUndoButton(app);
end

function drawImage(ax, img)
% tampilkan citra; [] mengosongkan axes
if isempty(img)
    clearAxes(ax);
    return;
end
imshow(img, 'Parent', ax);
ax.Toolbar.Visible = 'on';
shareContextMenu(ax);
end

function drawSpectrumOf(ax, img, judul)
if isempty(img)
    clearAxes(ax);
    return;
end
drawSpectrum(ax, logSpectrum(img, true), judul);
end

function drawSpectrum(ax, mag, judul)
% spektrum magnitude dengan sumbu koordinat u,v (sama dengan tabel peaks)
[U, V] = freqGrid(size(mag));
imagesc(ax, U(1, :), V(:, 1), mag);
colormap(ax, gray);
axis(ax, 'image');
labelUV(ax);
title(ax, judul);
showAxes(ax);
shareContextMenu(ax);
end

function drawNoisePattern(app)
% pola noise hasil notch mode pass (dinormalisasi supaya terlihat)
if isempty(app.NoisePattern)
    clearAxes(app.AxNoise);
    return;
end
drawImage(app.AxNoise, mat2gray(mean(app.NoisePattern, 3)));
end

function drawPeaksSpectrum(app)
% spektrum citra kerja di tab Noise Peaks, lengkap dengan lingkaran peaks
if isempty(app.AxPeaks) || ~isvalid(app.AxPeaks)
    return;     % tab belum dibuat
end
if isempty(app.BaseMag)
    clearAxes(app.AxPeaks);
    return;
end

if isempty(app.Peaks)
    drawSpectrum(app.AxPeaks, app.BaseMag, 'Spektrum citra kerja (belum ada peak)');
else
    plotNoisePeaks(app.AxPeaks, app.BaseMag, app.Peaks);
    labelUV(app.AxPeaks);
    showAxes(app.AxPeaks);
    shareContextMenu(app.AxPeaks);
end
end

function refreshPeakTables(app)
% isi tabel peaks di semua tab (Utama, Filter H, Noise Peaks) dengan data sama
n = numel(app.Peaks);
data = zeros(n, 5);
for k = 1:n
    data(k, :) = [k, app.Peaks(k).u, app.Peaks(k).v, ...
        app.Peaks(k).distance, app.Peaks(k).magnitude];
end

tables = {app.PeaksTableMain, app.PeaksTableFilter, app.PeaksTableTab};
for k = 1:numel(tables)
    if ~isempty(tables{k}) && isvalid(tables{k})
        tables{k}.Data = data;
    end
end
end

% ---------------------------------------------------------------------------
% Preview filter H
% ---------------------------------------------------------------------------

function refreshFilterPreview(app)
% hitung ulang H dari input saat ini (belum diterapkan) lalu gambar di tab
% Filter H. Dipanggil tiap ada input filter yang berubah.
if isempty(app.AxFilterH) || ~isvalid(app.AxFilterH)
    return;     % panel kanan belum dibangun
end

if isempty(app.Original)
    clearFilterPreview(app, 'Muat citra dulu untuk melihat preview filter.', false);
    return;
end

try
    [H, info, isPadded] = previewFilter(app);
catch ex
    clearFilterPreview(app, ['Filter belum valid: ' ex.message], true);
    return;
end

if isempty(H)
    clearFilterPreview(app, info, false);
    return;
end

app.FilterStatus.Text = info;
app.FilterStatus.FontColor = [0.2 0.2 0.2];

app.HImage = updateImage(app.AxFilterH, app.HImage, H, [0 1]);
title(app.AxFilterH, 'H(u,v): putih = lolos, hitam = diredam');

if isPadded
    spec  = app.BaseMag .* H;
    batas = [0 max(app.BaseMag(:))];
    judul = 'Spektrum citra kerja x H';
else
    % PSF motion blur tidak di-pad, jadi dibandingkan dengan spektrum tanpa pad
    spec  = logSpectrum(workingImage(app), false);
    batas = [0 max(spec(:))];
    judul = 'Spektrum citra kerja (tanpa pad): pita gelap = nol |H|';
end
app.MaskImage = updateImage(app.AxFilterSpec, app.MaskImage, spec, batas);
title(app.AxFilterSpec, judul);

drawPeakMarks(app, isPadded);
end

function [H, info, isPadded] = previewFilter(app)
% H terpusat dari input panel kiri. isPadded = false kalau H tidak berada di
% koordinat spektrum ter-pad (motion blur).
[method, params] = collectInputs(app);
base = workingImage(app);
sizeImg  = [size(base, 1), size(base, 2)];
isPadded = true;

switch method
    case {'lowpass', 'highpass'}
        entry = struct('type', params.shape, 'diameter', params.diameter, ...
            'n', params.n, 'isLowPass', strcmp(method, 'lowpass'));
        H = buildFilter(2 * sizeImg, entry);
        info = sprintf('%s %s, diameter %g, ukuran H %dx%d (citra di-pad 2x)', ...
            method, params.shape, params.diameter, size(H, 1), size(H, 2));

    case 'notch'
        H = buildFilter(2 * sizeImg, params.filterList, params.mode);
        info = sprintf('Notch/band %s, %d filter digabung, ukuran H %dx%d (citra di-pad 2x)', ...
            params.mode, numel(params.filterList), size(H, 1), size(H, 2));

    case 'motion'
        H = abs(fftshift(motionBlurPSF(sizeImg, params.L, params.theta)));
        isPadded = false;
        info = sprintf('|H| PSF motion blur, L = %g, theta = %g, ukuran %dx%d (tanpa pad)', ...
            params.L, params.theta, size(H, 1), size(H, 2));

    otherwise
        H = [];
        info = 'Brightness tidak memakai filter H: seluruh spektrum dikali satu alpha.';
end
end

function h = updateImage(ax, h, data, batas)
% perbarui CData gambar yang sudah ada (cepat untuk live preview); gambar baru
% dibuat hanya kalau belum ada atau ukurannya berubah
if ~isempty(h) && isvalid(h) && isequal(size(h.CData), size(data))
    h.CData = data;
else
    [U, V] = freqGrid(size(data));
    h = imagesc(ax, U(1, :), V(:, 1), data);
    colormap(ax, gray);
    axis(ax, 'image');
    box(ax, 'on');      % garis tepi, supaya H yang hampir putih semua tetap berbatas
    labelUV(ax);
    showAxes(ax);
    shareContextMenu(ax);
end

if batas(2) <= batas(1)
    batas(2) = batas(1) + 1;
end
clim(ax, batas);
end

function drawPeakMarks(app, tampil)
% lingkaran merah posisi noise peaks di atas gambar H
if ~isempty(app.HPeakMarks) && isvalid(app.HPeakMarks)
    delete(app.HPeakMarks);
end
app.HPeakMarks = [];

if ~tampil || isempty(app.Peaks)
    return;
end

hold(app.AxFilterH, 'on');
app.HPeakMarks = plot(app.AxFilterH, [app.Peaks.u], [app.Peaks.v], 'ro', ...
    'MarkerSize', 10, 'LineWidth', 1.2, ...
    'HitTest', 'off', 'PickableParts', 'none');
hold(app.AxFilterH, 'off');
end

function clearFilterPreview(app, pesan, isError)
app.FilterStatus.Text = pesan;
if isError
    app.FilterStatus.FontColor = [0.7 0.1 0.1];
else
    app.FilterStatus.FontColor = [0.2 0.2 0.2];
end
clearAxes(app.AxFilterH);
clearAxes(app.AxFilterSpec);
app.HImage = [];
app.MaskImage = [];
app.HPeakMarks = [];
end

% ---------------------------------------------------------------------------
% Log dan kualitas terhadap referensi
% ---------------------------------------------------------------------------

function showLog(app)
if isempty(app.Original)
    app.LogText.Value = {'Muat citra dulu, lalu pilih metode.'};
    return;
end

if isempty(app.Steps)
    baris = {'Belum ada langkah. Pilih metode lalu tekan Terapkan.'};
else
    baris = {'Langkah yang sudah diterapkan:'};
    for k = 1:numel(app.Steps)
        baris{end + 1} = sprintf('  %d. %s', k, app.Steps{k}); %#ok<AGROW>
    end
end

app.LogText.Value = [baris, qualityLines(app)];
end

function baris = qualityLines(app)
% PSNR dan MSE citra masukan dan hasil terhadap citra referensi
if isempty(app.Reference)
    baris = {'', 'Tidak ada citra referensi, PSNR/MSE tidak dihitung.'};
    return;
end

baris = {'', 'Kualitas terhadap referensi:', ...
    ['  masukan : ' qualityText(app.Original, app.Reference)]};
if ~isempty(app.Result)
    baris{end + 1} = ['  hasil   : ' qualityText(app.Result, app.Reference)];
end
end

function t = qualityText(img, ref)
if size(img, 1) ~= size(ref, 1) || size(img, 2) ~= size(ref, 2)
    t = 'ukuran berbeda dengan referensi, tidak dihitung';
    return;
end

% jumlah kanal beda: bandingkan versi abu-abunya
if size(img, 3) ~= size(ref, 3)
    if size(img, 3) == 3, img = rgb2gray(img); end
    if size(ref, 3) == 3, ref = rgb2gray(ref); end
end

selisih = double(img) - double(ref);
mseVal  = mean(selisih(:).^2);
if mseVal == 0
    t = 'identik dengan referensi (MSE = 0)';
else
    t = sprintf('PSNR = %.2f dB, MSE = %.2f', 10 * log10(255^2 / mseVal), mseVal);
end
end

% ---------------------------------------------------------------------------
% Helper axes dan layout
% ---------------------------------------------------------------------------

function shareContextMenu(ax)
% klik kanan mengenai objek gambar, bukan axes, jadi menu "Salin gambar"
% dipasang juga ke semua isi axes
set(ax.Children, 'ContextMenu', ax.ContextMenu);
end

function labelUV(ax)
% label sumbu spektrum; "v" ditulis tegak supaya tidak terbaca seperti tanda ">"
xlabel(ax, 'u');
ylabel(ax, 'v', 'Rotation', 0, ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
end

function showAxes(ax)
ax.Visible = 'on';
ax.Toolbar.Visible = 'on';
end

function hideAxes(ax)
% Visible off saja menyisakan toolbar (menu 3 titik), jadi toolbar ikut dimatikan
ax.Visible = 'off';
ax.Toolbar.Visible = 'off';
end

function clearAxes(ax)
if isempty(ax), return; end
if isgraphics(ax)
    cla(ax);
    title(ax, '');
    hideAxes(ax);
end
end

function setRowVisible(grid, row, visible)
if ~visible
    grid.RowHeight{row} = 1;
else
    grid.RowHeight{row} = '1x';
end
end

function setPanelRowVisible(app, panelName, visible)
% Lipat/buka baris pada ParamStack milik panel metode dengan nama panelName.
% Baris diambil dari Layout.Row panel itu sendiri supaya nomor baris tidak
% di-hardcode di dua tempat.
setRowVisible(app.ParamStack, app.Panels.(panelName).Layout.Row, visible);
end

% ===========================================================================
% Draggable Divider
% ===========================================================================

function updatePanelPositions(app)
% Perbarui posisi panel kiri, kanan, dan divider berdasarkan DividerPos
    figPos = app.Figure.Position;
    margin = 8 / figPos(3);  % margin dalam normalized units
    dividerWidth = 6 / figPos(3);  % lebar divider dalam normalized units
    gap = 4 / figPos(3);  % gap antar panel dan divider

    divX = app.DividerPos;

    % Left panel: dari kiri ke sebelum divider
    app.LeftPanel.Position = [margin, margin, divX - margin - gap - dividerWidth, 1 - 2*margin];

    % Divider: tepat di posisi divider
    app.Divider.Position = [divX - dividerWidth/2, 0, dividerWidth, 1];

    % Right panel: dari setelah divider ke kanan
    app.RightPanel.Position = [divX + dividerWidth/2 + gap, margin, 1 - divX - dividerWidth/2 - gap - margin, 1 - 2*margin];
end

function setupDividerCallbacks(app)
% Setup mouse callbacks untuk drag divider
    app.Figure.WindowButtonDownFcn   = @(~, ~) onDividerMouseDown(app);
    app.Figure.WindowButtonMotionFcn  = @(~, ~) onDividerMouseMove(app);
    app.Figure.WindowButtonUpFcn      = @(~, ~) onDividerMouseUp(app);
    app.Figure.SizeChangedFcn         = @(~, ~) updatePanelPositions(app);
end

function onDividerMouseDown(app)
% Cek apakah klik mouse dekat dengan divider
    figPos = app.Figure.Position;
    mouseX = app.Figure.CurrentPoint(1);  % posisi X mouse dalam pixel
    dividerPixelX = figPos(3) * app.DividerPos;

    % Toleransi 10 pixel
    if abs(mouseX - dividerPixelX) < 10
        app.IsDragging = true;
        app.Figure.Pointer = 'left';  % cursor resize
    end
end

function onDividerMouseMove(app)
% Update posisi divider saat dragging
    if app.IsDragging
        figPos = app.Figure.Position;
        mouseX = app.Figure.CurrentPoint(1);

        % Konversi ke posisi normalized
        newPos = mouseX / figPos(3);

        % Batasi: minimum 20%, maksimum 60%
        newPos = max(0.20, min(0.60, newPos));

        app.DividerPos = newPos;
        updatePanelPositions(app);
    else
        % Highlight divider saat hover
        figPos = app.Figure.Position;
        mouseX = app.Figure.CurrentPoint(1);
        dividerPixelX = figPos(3) * app.DividerPos;

        if abs(mouseX - dividerPixelX) < 10
            app.Figure.Pointer = 'left';
        else
            app.Figure.Pointer = 'arrow';
        end
    end
end

function onDividerMouseUp(app)
% Selesai dragging
    app.IsDragging = false;
    app.Figure.Pointer = 'arrow';
end
