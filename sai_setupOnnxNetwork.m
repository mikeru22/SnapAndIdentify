function sai_setupOnnxNetwork(networkName)
%SAI_SETUPONNXNETWORK  Download an ONNX model, import it, and save as .mat.
%   sai_setupOnnxNetwork(networkName) downloads the ONNX file for the
%   specified network, imports it using importNetworkFromONNX, and saves
%   the resulting dlnetwork + inputSize to a .mat file for fast reuse.

    baseDir = fileparts(mfilename('fullpath'));

    switch lower(networkName)
        case 'mobilenetv3small'
            url = 'https://huggingface.co/pyronear/mobilenet_v3_small/resolve/main/model.onnx';
            matFile = fullfile(baseDir, 'mobilenetv3_small.mat');
            inputSize = [224 224];
        case 'mobilenetv3large'
            url = 'https://huggingface.co/pyronear/mobilenet_v3_large/resolve/main/model.onnx';
            matFile = fullfile(baseDir, 'mobilenetv3_large.mat');
            inputSize = [224 224];
        case 'efficientnetlite4'
            url = 'https://github.com/onnx/models/raw/main/validated/vision/classification/efficientnet-lite4/model/efficientnet-lite4-11.onnx';
            matFile = fullfile(baseDir, 'efficientnet_lite4.mat');
            inputSize = [300 300];
        otherwise
            error('sai_setupOnnxNetwork:Unknown', 'Unknown ONNX network: %s', networkName);
    end

    onnxFile = fullfile(baseDir, [networkName '.onnx']);

    fprintf('Downloading %s ONNX model...\n', networkName);
    websave(onnxFile, url);

    fprintf('Importing ONNX model (this may take a minute)...\n');
    net = importNetworkFromONNX(onnxFile); %#ok<NASGU>

    fprintf('Saving to %s...\n', matFile);
    save(matFile, 'net', 'inputSize', '-v7.3');

    % Clean up ONNX file
    delete(onnxFile);
    fprintf('Done! %s is ready.\n', networkName);
end
