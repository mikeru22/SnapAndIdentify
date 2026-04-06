function [net, inputSize, isOnnx] = sai_loadNetwork(networkName)
%SAI_LOADNETWORK  Load a pretrained ImageNet classifier by name.
%   [net, inputSize, isOnnx] = sai_loadNetwork(networkName) returns the
%   network, its expected [H W] input size, and whether it is an ONNX model
%   (which requires predict+argmax instead of classify).

    isOnnx = false;
    baseDir = fileparts(mfilename('fullpath'));

    switch lower(networkName)
        case 'googlenet'
            net = googlenet;
        case 'resnet18'
            net = resnet18;
        case 'resnet50'
            net = resnet50;
        case 'squeezenet'
            net = squeezenet;
        case 'resnet101'
            net = resnet101;
        case 'mobilenetv2'
            net = mobilenetv2;
        case 'efficientnetb0'
            net = efficientnetb0;
        case 'nasnetmobile'
            net = nasnetmobile;
        case 'shufflenet'
            net = shufflenet;
        case 'efficientnetlite4'
            matFile = fullfile(baseDir, 'efficientnet_lite4.mat');
            if ~isfile(matFile)
                sai_setupOnnxNetwork('efficientnetlite4');
            end
            data = load(matFile, 'net');
            net = data.net;
            inputSize = net.Layers(1).InputSize(1:2);
            isOnnx = true; return;
        otherwise
            error('sai_loadNetwork:UnknownNetwork', ...
                'Unknown network: %s.', networkName);
    end
    inputSize = net.Layers(1).InputSize(1:2);
end
