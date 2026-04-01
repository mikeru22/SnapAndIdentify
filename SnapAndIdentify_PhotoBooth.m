%% Snap & Identify: Photo Booth Edition!
% Desktop/laptop + USB webcam. Interactive uifigure UI.

%% ====== CHECK DEPENDENCIES ======
sai_checkDependencies();

%% ====== SETTINGS (Museum Staff: Adjust These!) ======
numPhotos = 5;
delayBetween = 3;
countdownBefore = 5;
resetTimeout = 60;
gameMode = 'objectid';              % 'objectid' or 'emotion'
cameraIndex = 1;
networkName = 'googlenet';          % 'googlenet', 'resnet18', 'resnet50', 'squeezenet'

%% ====== AUTO-SETUP: Emotion model ======
matFile = fullfile(fileparts(mfilename('fullpath')), 'emotion_net.mat');
if ~isfile(matFile)
    fprintf('Emotion model not found. Running one-time setup...\n');
    sai_setupEmotionModel();
end

%% ====== LAUNCH ======
cfg.numPhotos = numPhotos;
cfg.delayBetween = delayBetween;
cfg.countdownBefore = countdownBefore;
cfg.resetTimeout = resetTimeout;
cfg.cameraIndex = cameraIndex;
cfg.gameMode = gameMode;
cfg.networkName = networkName;

SnapAndIdentify_Desktop(cfg);
