function sai_checkDependencies()
%SAI_CHECKDEPENDENCIES  Verify that required toolboxes and add-ons are installed.
%   Checks for all MATLAB toolboxes and support packages needed by the
%   Snap & Identify Photo Booth. Prints a summary and errors out if any
%   required dependency is missing.

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
        try
            % Check if importNetworkFromONNX is available
            narginchk(0, 0);  % dummy; real test below
            if exist('importNetworkFromONNX', 'file')
                fprintf('  [OK]       Deep Learning Toolbox Converter for ONNX Model Format\n');
            else
                fprintf('  [MISSING]  Deep Learning Toolbox Converter for ONNX Model Format (needed for first-time emotion model setup)\n');
                allOk = false;
            end
        catch
            fprintf('  [MISSING]  Deep Learning Toolbox Converter for ONNX Model Format (needed for first-time emotion model setup)\n');
            allOk = false;
        end
    else
        fprintf('  [OK]       Emotion model already built (emotion_net.mat found)\n');
    end

    % Pretrained network support packages — check if default network loads
    try
        googlenet; %#ok<NASGU>
        fprintf('  [OK]       Deep Learning Toolbox Model for GoogLeNet Network\n');
    catch
        fprintf('  [MISSING]  Deep Learning Toolbox Model for GoogLeNet Network\n');
        allOk = false;
    end

    fprintf('------------------------------\n');
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
