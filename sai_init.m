function S = sai_init(networkName)
%SAI_INIT  Initialize Snap & Identify shared resources.
%   S = sai_init(networkName) returns a struct with:
%     S.net            - loaded classification network
%     S.inputSize      - [H W] input size for the network
%     S.networkName    - name of the loaded network
%     S.emojiMap       - containers.Map of labels -> emoji
%     S.emotionNet     - emotion detection dlnetwork (or [])
%     S.emotionInputSize - [H W] for emotion model (or [])
%     S.emotionEmojiMap  - emotion label -> emoji map (or [])

    if nargin < 1, networkName = 'googlenet'; end

    % Workaround: R2026a prerelease support package path
    if isfolder('C:\ProgramData\MATLAB\SupportPackages\R2026aPrerelease') && ...
            isempty(matlabshared.supportpkg.getSupportPackageRoot)
        matlabshared.supportpkg.setSupportPackageRoot(...
            'C:\ProgramData\MATLAB\SupportPackages\R2026aPrerelease');
    end

    [S.net, S.inputSize, S.isOnnx] = sai_loadNetwork(networkName);
    S.networkName = networkName;
    S.emojiMap = sai_buildEmojiMap();
    if S.isOnnx
        S.imagenetLabels = sai_imagenetLabels();
    else
        S.imagenetLabels = {};
    end

    % Load emotion detection model if available
    modelPath = fullfile(fileparts(mfilename('fullpath')), 'emotion_net.mat');
    if isfile(modelPath)
        data = load(modelPath, 'emotionNet', 'emotionInputSize');
        S.emotionNet = data.emotionNet;
        S.emotionInputSize = data.emotionInputSize;
        S.emotionEmojiMap = sai_buildEmotionEmojiMap();
    else
        S.emotionNet = [];
        S.emotionInputSize = [];
        S.emotionEmojiMap = [];
    end
end
