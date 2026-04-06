%% Snap & Identify: Photo Booth Edition!
% Desktop/laptop + USB webcam. Interactive uifigure UI.

%% ====== CHECK DEPENDENCIES ======
[availableNetworks, availableDetectors] = sai_checkDependencies();

%% ====== SETTINGS (Museum Staff: Adjust These!) ======
numPhotos = 5;
delayBetween = 3;
countdownBefore = 5;
resetTimeout = 60;
gameMode = 'objectid';              % 'objectid' or 'emotion'
cameraIndex = 1;
% Auto-select best available network (highest accuracy first)
networkPrefs = {'efficientnetlite4','efficientnetb0','resnet101', ...
    'resnet50','nasnetmobile','mobilenetv2','googlenet', ...
    'resnet18','shufflenet','squeezenet'};
networkName = 'googlenet';  % fallback
for np = 1:numel(networkPrefs)
    if ismember(networkPrefs{np}, availableNetworks)
        networkName = networkPrefs{np};
        break;
    end
end

%% ====== AUTO-SETUP: Emotion model ======
matFile = fullfile(fileparts(mfilename('fullpath')), 'emotion_net.mat');
if ~isfile(matFile)
    fprintf('Emotion model not found. Running one-time setup...\n');
    sai_setupEmotionModel();
end

%% ====== LAUNCH ======
%% ====== DETECT CAMERAS ======
try
    camList = webcamlist;
catch
    camList = {};
end

%% ====== LAUNCH ======
cfg.numPhotos = numPhotos;
cfg.delayBetween = delayBetween;
cfg.countdownBefore = countdownBefore;
cfg.resetTimeout = resetTimeout;
cfg.cameraIndex = cameraIndex;
cfg.gameMode = gameMode;
cfg.networkName = networkName;
cfg.availableNetworks = availableNetworks;
cfg.availableDetectors = availableDetectors;
cfg.cameraList = camList;

SnapAndIdentify_Desktop(cfg);
