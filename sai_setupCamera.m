function cam = sai_setupCamera(camIndex)
%SAI_SETUPCAMERA  Initialize webcam for photo booth.
%   Uses 640x480 resolution for smooth preview performance.
    cam = webcam(camIndex);
    % Set lower resolution for performance (default is often max res)
    try
        cam.Resolution = '640x480';
    catch
        % If 640x480 not available, try to pick a modest resolution
        res = cam.AvailableResolutions;
        for i = 1:numel(res)
            dims = sscanf(res{i}, '%dx%d');
            if dims(1) <= 800
                cam.Resolution = res{i};
                break;
            end
        end
    end
end
