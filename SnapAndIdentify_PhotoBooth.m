%% Snap & Identify: Photo Booth Edition!
% Two modes controlled by cameraMode setting:
%   'webcam'  - Desktop/laptop + USB webcam. Interactive uifigure UI.
%   'mobile'  - iPad via MATLAB Mobile. Classic figure() GUI.

%% ====== SETTINGS (Museum Staff: Adjust These!) ======
numPhotos = 5;
delayBetween = 3;
countdownBefore = 5;
resetTimeout = 60;

cameraMode = 'webcam';              % <<< CHANGE TO 'mobile' FOR iPAD
cameraIndex = 1;
mobileCameraName = 'front';         % 'front' (selfie) or 'back'
mobileCameraResolution = '640x480';

%% ====== LAUNCH ======
cfg.numPhotos = numPhotos;
cfg.delayBetween = delayBetween;
cfg.countdownBefore = countdownBefore;
cfg.resetTimeout = resetTimeout;
cfg.cameraMode = cameraMode;
cfg.cameraIndex = cameraIndex;
cfg.mobileCameraName = mobileCameraName;
cfg.mobileCameraResolution = mobileCameraResolution;

if strcmpi(cameraMode, 'webcam')
    SnapAndIdentify_Desktop(cfg);
else
    SnapAndIdentify_Mobile(cfg);
end
