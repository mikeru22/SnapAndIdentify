function labels = sai_imagenetLabels()
%SAI_IMAGENETLABELS  Return the 1000 ImageNet class names.
%   labels = sai_imagenetLabels() returns a 1x1000 cell array of class
%   names corresponding to ImageNet-1K indices (1-based). Used for ONNX
%   models that output raw scores instead of categorical labels.
%
%   Labels are loaded from imagenet_labels.txt (one label per line).
%   If the file is missing, it is downloaded from GitHub.

    persistent cachedLabels
    if ~isempty(cachedLabels)
        labels = cachedLabels;
        return;
    end

    baseDir = fileparts(mfilename('fullpath'));
    labelFile = fullfile(baseDir, 'imagenet_labels.txt');

    if ~isfile(labelFile)
        fprintf('Downloading ImageNet labels...\n');
        url = 'https://raw.githubusercontent.com/pytorch/hub/master/imagenet_classes.txt';
        websave(labelFile, url);
    end

    fid = fopen(labelFile, 'r');
    raw = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);
    labels = raw{1}';

    if numel(labels) < 1000
        warning('sai_imagenetLabels:Short', 'Only %d labels found (expected 1000).', numel(labels));
    end

    cachedLabels = labels;
end
