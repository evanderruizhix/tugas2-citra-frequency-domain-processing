classdef AppState < handle
% AppState - wadah state untuk FrequencyDomainApp

    properties
        % ---- state aplikasi ----
        Original   = [];    % citra masukan (uint8, tidak diubah)
        Result     = [];    % citra hasil chaining ([] = belum ada)
        Reference  = [];    % citra referensi / ground truth ([] = tidak ada)
        Steps      = {};    % riwayat langkah: cell array of string
        History    = {};    % tumpukan undo: cell of struct (.Result, .Steps, .NoisePattern)
        DatasetIdx = [];    % struktur dataset dari datasetIndex()

        Peaks        = [];  % struct array hasil findNoisePeaks ([] = belum ada)
        NotchCards   = [];  % model filter builder: struct array (.type, .rows)
        NoisePattern = [];  % pola noise terakhir dari notch mode pass
        BaseMag      = [];  % spektrum (log, ter-pad 2x) citra kerja, dipakai peaks & preview H

        % ---- container utama ----
        Figure     = [];
        LeftPanel  = [];
        RightPanel = [];
        Divider    = [];    % panel pemisah yang bisa di-drag
        DividerPos = 0.33;  % posisi divider (normalized 0-1, default 33%)
        IsDragging = false; % status dragging
    end

    properties
        % ---- panel kontrol kiri ----
        % pilih citra & metode
        FolderBox  = []; ImageBox = []; InfoLabel = [];
        PeaksButton = [];
        MethodBox  = [];
        ParamStack = [];
        Panels     = [];

        % panel lowpass / highpass
        PassShape = []; PassDiameter = []; PassOrder = [];
        PassEpoch = []; PassTuneStatus = [];

        % panel brightness
        TargetMean = []; BrightEpoch = []; BrightTuneStatus = [];

        % panel notch / band (filter builder)
        NotchMode = []; NotchWeight = []; NotchTypeBox = [];
        CardHost  = [];

        % panel motion blur
        MotionMethod = []; MotionL = []; MotionTheta = [];
        MotionParamLabel = []; MotionK = []; MotionThreshold = [];

        % tombol aksi
        UndoButton = [];

        % ---- panel tampilan kanan ----
        TabGroup = []; MainTab = []; FilterTab = []; PeaksTab = [];

        % tab Utama
        AxImageIn = []; AxImageOut = []; AxImageRef = [];
        AxSpecIn  = []; AxSpecOut  = []; AxSpecRef  = [];
        PeaksTableMain = []; LogText = [];

        % tab Filter H
        FilterStatus = [];
        AxFilterH = []; AxFilterSpec = []; AxNoise = [];
        HImage = []; MaskImage = []; HPeakMarks = [];
        PeaksTableFilter = [];

        % tab Noise Peaks
        PeakExclude = []; PeakMinDist = []; PeakMax = []; PeakThresh = [];
        PeakStatus  = []; AxPeaks = []; PeaksTableTab = [];
    end
end
