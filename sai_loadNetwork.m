function [net, inputSize] = sai_loadNetwork(networkName)
%SAI_LOADNETWORK  Load a pretrained ImageNet classifier by name.
%   [net, inputSize] = sai_loadNetwork(networkName) returns the network
%   and its expected [H W] input size.

    switch lower(networkName)
        case 'googlenet'
            net = googlenet;
        case 'resnet18'
            net = resnet18;
        case 'resnet50'
            net = resnet50;
        case 'squeezenet'
            net = squeezenet;
        otherwise
            error('sai_loadNetwork:UnknownNetwork', ...
                'Unknown network: %s. Use googlenet, resnet18, resnet50, or squeezenet.', networkName);
    end
    inputSize = net.Layers(1).InputSize(1:2);
end
