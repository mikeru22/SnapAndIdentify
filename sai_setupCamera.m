function cam = sai_setupCamera(mode, camIndex, mobileCamName, mobileCamRes)
    if strcmpi(mode, 'mobile')
        m = mobiledev;
        if ~m.Connected
            error('SnapAndIdentify:NotConnected', 'MATLAB Mobile device not connected.');
        end
        cam = camera(m, mobileCamName);
        if nargin >= 4 && ~isempty(mobileCamRes)
            try cam.Resolution = mobileCamRes; catch, end
        end
    else
        cam = webcam(camIndex);
    end
end
