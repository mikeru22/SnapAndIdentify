function availableNetworks = sai_checkDependencies()
%SAI_CHECKDEPENDENCIES  Verify that required toolboxes and add-ons are installed.
%   availableNetworks = sai_checkDependencies() returns a cell array of
%   network names (e.g. {'googlenet','resnet18'}) that are installed and
%   ready to use. Errors if any required core dependency is missing.
%   Automatically installs GoogLeNet support package if not present.

    fprintf('\n--- Checking dependencies ---\n');
    allOk = true;

    % Required toolboxes (checked via ver)
    toolboxes = {
        'Deep Learning Toolbox',       'nnet'
        'Image Processing Toolbox',    'images'
        'Computer Vision Toolbox',     'vision'
    };

    for i = 1:size(toolboxes, 1)
        name = toolboxes{i, 1};
        id   = toolboxes{i, 2};
        v = ver(id);
        if isempty(v)
            fprintf('  [MISSING]  %s\n', name);
            allOk = false;
        else
            fprintf('  [OK]       %s (v%s)\n', name, v.Version);
        end
    end

    % USB Webcam support package (checked via webcamlist)
    try
        webcamlist; %#ok<NASGU> — just testing availability
        fprintf('  [OK]       MATLAB Support Package for USB Webcams\n');
    catch
        fprintf('  [MISSING]  MATLAB Support Package for USB Webcams\n');
        allOk = false;
    end

    % ONNX converter — only needed if emotion_net.mat does not exist yet
    matFile = fullfile(fileparts(mfilename('fullpath')), 'emotion_net.mat');
    if ~isfile(matFile)
        if exist('importNetworkFromONNX', 'file')
            fprintf('  [OK]       Deep Learning Toolbox Converter for ONNX Model Format\n');
        else
            fprintf('  [MISSING]  Deep Learning Toolbox Converter for ONNX Model Format (needed for first-time emotion model setup)\n');
            allOk = false;
        end
    else
        fprintf('  [OK]       Emotion model already built (emotion_net.mat found)\n');
    end

    % --- Check pretrained network support packages ---
    fprintf('\n--- Checking AI network support packages ---\n');
    networkList = {
        'googlenet',   'GoogLeNet',    'Deep Learning Toolbox Model for GoogLeNet Network'
        'resnet18',    'ResNet-18',    'Deep Learning Toolbox Model for ResNet-18 Network'
        'resnet50',    'ResNet-50',    'Deep Learning Toolbox Model for ResNet-50 Network'
        'squeezenet',  'SqueezeNet',   'Deep Learning Toolbox Model for SqueezeNet Network'
    };

    availableNetworks = {};
    for i = 1:size(networkList, 1)
        funcName    = networkList{i, 1};
        displayName = networkList{i, 2};
        pkgName     = networkList{i, 3};
        try
            feval(funcName); %#ok<NASGU> — test if network loads
            fprintf('  [OK]       %s (%s)\n', displayName, pkgName);
            availableNetworks{end+1} = funcName; %#ok<AGROW>
        catch
            fprintf('  [MISSING]  %s (%s)\n', displayName, pkgName);
        end
    end

    % Auto-install GoogLeNet if not available (it is the default network)
    if ~ismember('googlenet', availableNetworks)
        fprintf('\n  GoogLeNet is required as the default network. Attempting to install...\n');
        try
            matlab.addons.install('https://www.mathworks.com/matlabcentral/mlc-downloads/downloads/e5648817-8a78-4e3d-a3bf-1907a4b09834/74e40f98-28b1-4457-8ea9-4b7e9e79e264/packages/mps/dl/googlenet.mltbx');
            fprintf('  [INSTALLED] GoogLeNet installed successfully.\n');
            availableNetworks{end+1} = 'googlenet';
        catch
            % Try alternative: use the support package installer
            try
                eval('googlenet');  %#ok — trigger auto-download prompt
                fprintf('  [INSTALLED] GoogLeNet installed successfully.\n');
                availableNetworks{end+1} = 'googlenet';
            catch ME2
                fprintf('  [FAILED]   Could not auto-install GoogLeNet: %s\n', ME2.message);
                fprintf('             Please install it manually via Add-On Explorer:\n');
                fprintf('             Home > Add-Ons > Search for "Deep Learning Toolbox Model for GoogLeNet Network"\n');
                allOk = false;
            end
        end
    end

    fprintf('------------------------------\n');
    if isempty(availableNetworks)
        fprintf('  WARNING: No AI networks are installed!\n');
        fprintf('           Install at least one via Add-On Explorer.\n\n');
        allOk = false;
    else
        fprintf('  Available networks: %s\n\n', strjoin(availableNetworks, ', '));
    end

    if allOk
        fprintf('All dependencies satisfied!\n\n');
    else
        fprintf('\n');
        error('sai_checkDependencies:MissingDeps', ...
            ['One or more required toolboxes or support packages are missing.\n' ...
             'Install them via the MATLAB Add-On Explorer (Home > Add-Ons)\n' ...
             'and then run the photo booth again.']);
    end
end
