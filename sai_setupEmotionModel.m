function sai_setupEmotionModel()
%SAI_SETUPEMOTIONMODEL  Download and convert emotion detection model.
%   Run once to create emotion_net.mat. Called automatically by the photo
%   booth launcher when the MAT file is missing.
%
%   Requires: "Deep Learning Toolbox Converter for ONNX Model Format"
%   support package.
%
%   The model is emotion-ferplus-8.onnx from the ONNX Model Zoo, trained on
%   the FER+ dataset (8 emotion classes: neutral, happy, surprise, sad,
%   angry, disgust, fear, contempt).

    baseDir  = fileparts(mfilename('fullpath'));
    onnxUrl  = 'https://github.com/onnx/models/raw/main/validated/vision/body_analysis/emotion_ferplus/model/emotion-ferplus-8.onnx';
    onnxFile = fullfile(baseDir, 'emotion-ferplus-8.onnx');
    matFile  = fullfile(baseDir, 'emotion_net.mat');

    %% Download the ONNX model
    if ~isfile(onnxFile)
        fprintf('Downloading emotion-ferplus-8.onnx...\n');
        websave(onnxFile, onnxUrl);
        fprintf('Download complete.\n');
    else
        fprintf('ONNX file already exists: %s\n', onnxFile);
    end

    %% Import as dlnetwork
    fprintf('Importing ONNX model...\n');
    emotionNet = importNetworkFromONNX(onnxFile, ...
        'InputDataFormats', 'BCSS'); %#ok<NASGU>

    % Input size for this model (64x64 grayscale)
    emotionInputSize = [64 64]; %#ok<NASGU>

    %% Save as MAT file
    fprintf('Saving emotion_net.mat...\n');
    save(matFile, 'emotionNet', 'emotionInputSize');
    fprintf('Done! emotion_net.mat saved to:\n  %s\n', matFile);
end
