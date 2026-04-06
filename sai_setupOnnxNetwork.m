function sai_setupOnnxNetwork(networkName)
%SAI_SETUPONNXNETWORK  Download an ONNX model, import it, and save as .mat.
%   sai_setupOnnxNetwork(networkName) downloads the ONNX file for the
%   specified network, imports it using importNetworkFromONNX, and saves
%   the resulting dlnetwork + inputSize to a .mat file for fast reuse.

    baseDir = fileparts(mfilename('fullpath'));

    switch lower(networkName)
        case 'efficientnetlite4'
            url = 'https://github.com/onnx/models/raw/main/validated/vision/classification/efficientnet-lite4/model/efficientnet-lite4-11.onnx';
            matFile = fullfile(baseDir, 'efficientnet_lite4.mat');
        otherwise
            error('sai_setupOnnxNetwork:Unknown', 'Unknown ONNX network: %s', networkName);
    end

    onnxFile = fullfile(baseDir, [networkName '.onnx']);

    fprintf('Downloading %s ONNX model...\n', networkName);
    websave(onnxFile, url);

    fprintf('Importing ONNX model (this may take a minute)...\n');
    net = importNetworkFromONNX(onnxFile);

    % Read actual input size from the imported network's input layer
    inputSize = net.Layers(1).InputSize(1:2);
    fprintf('Detected input size: [%d %d]\n', inputSize(1), inputSize(2));

    fprintf('Saving to %s...\n', matFile);
    save(matFile, 'net', 'inputSize', '-v7.3');

    % Clean up ONNX file
    delete(onnxFile);
    fprintf('Done! %s is ready.\n', networkName);
end
