function SnapAndIdentify_Desktop(cfg)
% SNAPANDIDENTIFY_DESKTOP  Desktop photo booth with full interactive uifigure UI.
%   Features: configurable settings panel, AI network selection, emotion
%   detection mode, scalable UI, and optimized camera preview performance.

    % Shared state variables (accessible by nested callback functions)
    startPressed  = false;
    donePressed   = false;
    exitRequested = false;
    backPressed   = false;              % continuous mode back button
    feedback      = zeros(1, cfg.numPhotos);
    currentMode   = cfg.gameMode;       % 'objectid', 'emotion', or 'continuous'
    pendingNetworkName = cfg.networkName;
    savedClassifierName = cfg.networkName;  % remember classifier when switching to continuous
    promptMode    = false;              % guided emotion prompts

    % Continuous mode shared state (for nested callbacks)
    detector       = [];
    hContImg       = [];
    contStatus     = [];
    contLabel      = [];              % classification label overlay
    totalDetections = 0;
    uniqueLabels    = {};
    contNet        = [];              % classifier network for continuous mode
    contInputSize  = [];
    contIsOnnx     = false;
    contImgnetLabels = {};
    contEmojiMap   = [];

    % Logo path
    logoFile = fullfile(fileparts(mfilename('fullpath')), 'mathworks-logo-full-color-rgb.png');
    hasLogo  = isfile(logoFile);

    % --- Loading splash ---
    splashFig = uifigure('Name','Snap & Identify','Color',[0.18 0.55 0.78], ...
        'WindowState','maximized');
    [figW, figH] = waitForMaximize(splashFig);
    sf = scaleFactor(figW, figH);
    splashLabel = uilabel(splashFig, ...
        'Text',ehtml('&#x1F916;','Getting the Computer Brain Ready...'), ...
        'Interpreter','html', ...
        'FontSize',round(36*sf),'FontWeight','bold','FontColor','white', ...
        'HorizontalAlignment','center','Position',[0 figH*0.2 figW figH*0.6]);
    if hasLogo
        logoH_splash = round(60*sf);
        logoW_splash = round(logoH_splash * 5);  % logo aspect ~5:1
        uiimage(splashFig,'ImageSource',logoFile, ...
            'Position',[(figW-logoW_splash)/2 round(20*sf) logoW_splash logoH_splash]);
    end
    addExitButton(splashFig, sf);
    drawnow;

    try
        S = sai_init(cfg.networkName);
        net       = S.net;
        inputSize = S.inputSize;
        emojiMap  = S.emojiMap;
        cam = sai_setupCamera(cfg.cameraIndex);
        splashLabel.Text = ehtml('&#x2705;','Ready!');
        drawnow; pause(1.5);
    catch ME
        splashLabel.Text = ehtml('&#x274C;',['Error: ' ME.message]);
        splashLabel.FontSize = round(24*sf); drawnow; return;
    end
    delete(splashFig);

    keepRunning = true;
    while keepRunning

        % ==================== START SCREEN ====================
        startPressed = false;
        startFig = uifigure('Name','Snap & Identify: Photo Booth!', ...
            'Color','black','WindowState','maximized');
        [figW, figH] = waitForMaximize(startFig);
        sf = scaleFactor(figW, figH);

        topBarH = round(90*sf);
        btnH    = round(80*sf);
        btnPad  = round(15*sf);
        infoPad = round(40*sf);

        % Title bar
        uilabel(startFig, ...
            'Text',ehtml('&#x1F4F8;','Snap & Identify!'), ...
            'Interpreter','html', ...
            'FontSize',round(42*sf),'FontWeight','bold', ...
            'FontColor','white','HorizontalAlignment','center', ...
            'BackgroundColor',[0 0 0 0.5], ...
            'Position',[0 figH-topBarH figW topBarH]);

        % Info bar
        if strcmpi(currentMode,'emotion')
            infoText = sprintf('Show your face and tap START!  (%d photos, %d sec apart)', cfg.numPhotos, cfg.delayBetween);
        else
            infoText = sprintf('Hold up an object and tap START!  (%d photos, %d sec apart)', cfg.numPhotos, cfg.delayBetween);
        end
        uilabel(startFig,'Text',infoText, ...
            'FontSize',round(18*sf),'FontColor',[0.85 0.92 1.0], ...
            'HorizontalAlignment','center','BackgroundColor',[0 0 0 0.4], ...
            'Position',[0 figH-topBarH-infoPad figW infoPad]);

        % Layout: settings panel on left-center, camera preview on right-center
        settingsW = round(320*sf);
        settingsH = round(400*sf);
        previewY  = btnH + 2*btnPad;
        previewH  = figH - topBarH - infoPad - previewY;

        % Center the settings+preview group
        previewW  = min(figW*0.55, previewH*4/3);
        groupW    = settingsW + round(20*sf) + previewW;
        groupX    = max(round(10*sf), (figW - groupW)/2);

        settingsX = groupX;
        settingsY = previewY + (previewH - settingsH)/2;

        previewX  = settingsX + settingsW + round(20*sf);

        % --- Settings panel ---
        settPanel = uipanel(startFig, ...
            'Title','Settings','FontSize',round(16*sf), ...
            'BackgroundColor',[0.15 0.15 0.15], ...
            'ForegroundColor','white', ...
            'Position',[settingsX settingsY settingsW settingsH]);

        rowH_s = round(40*sf);
        lblFS  = round(14*sf);
        padS   = round(12*sf);
        ddW    = round(120*sf);
        lblW   = settingsW - ddW - 3*padS;
        yy     = settingsH - round(70*sf);  % inside panel coords (extra top padding for title)

        % Photos dropdown
        uilabel(settPanel,'Text','Photos:','FontSize',lblFS, ...
            'FontColor','white','Position',[padS yy lblW rowH_s]);
        ddPhotos = uidropdown(settPanel, ...
            'Items',string(1:10),'Value',string(cfg.numPhotos), ...
            'FontSize',lblFS, ...
            'Position',[lblW+2*padS yy ddW rowH_s], ...
            'ValueChangedFcn',@(src,~) onSettingChange('numPhotos',str2double(src.Value)));
        yy = yy - rowH_s - padS;

        % Seconds Between dropdown (1-10)
        uilabel(settPanel,'Text','Seconds Between:','FontSize',lblFS, ...
            'FontColor','white','Position',[padS yy lblW rowH_s]);
        ddDelay = uidropdown(settPanel, ...
            'Items',string(1:10),'Value',string(cfg.delayBetween), ...
            'FontSize',lblFS, ...
            'Position',[lblW+2*padS yy ddW rowH_s], ...
            'ValueChangedFcn',@(src,~) onSettingChange('delayBetween',str2double(src.Value)));
        yy = yy - rowH_s - padS;

        % Countdown dropdown
        uilabel(settPanel,'Text','Countdown:','FontSize',lblFS, ...
            'FontColor','white','Position',[padS yy lblW rowH_s]);
        ddCountdown = uidropdown(settPanel, ...
            'Items',string(1:10),'Value',string(cfg.countdownBefore), ...
            'FontSize',lblFS, ...
            'Position',[lblW+2*padS yy ddW rowH_s], ...
            'ValueChangedFcn',@(src,~) onSettingChange('countdownBefore',str2double(src.Value)));
        yy = yy - rowH_s - padS;

        % AI Network dropdown (hidden in emotion mode, only shows installed networks)
        allNetNames  = {'googlenet','resnet18','resnet50','squeezenet','resnet101','mobilenetv2','efficientnetb0','nasnetmobile','shufflenet','efficientnetlite4'};
        allNetLabels = {'GoogLeNet','ResNet-18','ResNet-50','SqueezeNet','ResNet-101','MobileNet-v2','EfficientNet-b0','NASNet-Mobile','ShuffleNet','EfficientNet-Lite4'};
        % Detector names (for continuous mode)
        detectorNames  = {'tiny-yolov4-coco'};
        detectorLabels = {'Tiny YOLOv4 (COCO)'};
        if isfield(cfg, 'availableNetworks') && ~isempty(cfg.availableNetworks)
            availNets = cfg.availableNetworks;
        else
            availNets = allNetNames;  % fallback: show all
        end
        keepIdx = ismember(allNetNames, availNets);
        ddItems     = allNetLabels(keepIdx);
        ddItemsData = allNetNames(keepIdx);
        % Add available detectors to the dropdown
        if isfield(cfg, 'availableDetectors') && ~isempty(cfg.availableDetectors)
            for di = 1:numel(detectorNames)
                if ismember(detectorNames{di}, cfg.availableDetectors)
                    ddItems     = [ddItems, detectorLabels(di)];
                    ddItemsData = [ddItemsData, detectorNames(di)];
                end
            end
        end
        % Ensure selected network is in the list
        if ~ismember(pendingNetworkName, ddItemsData) && ~isempty(ddItemsData)
            pendingNetworkName = ddItemsData{1};
        end

        netLabel = uilabel(settPanel,'Text','AI Network:','FontSize',lblFS, ...
            'FontColor','white','Position',[padS yy lblW rowH_s]);
        ddNetwork = uidropdown(settPanel, ...
            'Items',ddItems, ...
            'ItemsData',ddItemsData, ...
            'Value',pendingNetworkName, ...
            'FontSize',lblFS, ...
            'Position',[lblW+2*padS yy ddW rowH_s], ...
            'ValueChangedFcn',@(src,~) onNetworkSelect(src.Value));
        yy = yy - rowH_s - padS;

        % Camera dropdown
        if isfield(cfg, 'cameraList') && ~isempty(cfg.cameraList)
            camNames = cfg.cameraList;
            % Build display items: "1: Name"
            camItems = cell(1, numel(camNames));
            camItemsData = 1:numel(camNames);
            for ci = 1:numel(camNames)
                camItems{ci} = sprintf('%d: %s', ci, camNames{ci});
            end
        else
            camItems = {'1: Default'};
            camItemsData = 1;
        end
        uilabel(settPanel,'Text','Camera:','FontSize',lblFS, ...
            'FontColor','white','Position',[padS yy lblW rowH_s]);
        ddCamera = uidropdown(settPanel, ...
            'Items',camItems, ...
            'ItemsData',camItemsData, ...
            'Value',cfg.cameraIndex, ...
            'FontSize',round(11*sf), ...
            'Position',[lblW+2*padS yy ddW rowH_s], ...
            'ValueChangedFcn',@(src,~) onCameraSelect(src.Value));
        yy = yy - rowH_s - padS;

        % Mode selection: three side-by-side buttons + prompt toggle
        modeBtnH = round(38*sf);
        modeBtnW = round((settingsW - 4*padS) / 3);
        modeActiveColor   = [0.4 0.2 0.7];
        modeInactiveColor = [0.35 0.35 0.35];
        modeRow2Y = settingsY + padS;
        modeRow1Y = modeRow2Y + modeBtnH + round(4*sf);

        objBtn = uibutton(startFig,'push', ...
            'Text','<html><body>&#x1F50D; Object ID</body></html>', ...
            'Interpreter','html', ...
            'FontSize',round(12*sf),'FontWeight','bold','FontColor','white', ...
            'Position',[settingsX+padS modeRow1Y modeBtnW modeBtnH], ...
            'ButtonPushedFcn',@(~,~) onModeSelect('objectid'));
        contBtn = uibutton(startFig,'push', ...
            'Text','<html><body>&#x1F4F7; Continuous</body></html>', ...
            'Interpreter','html', ...
            'FontSize',round(12*sf),'FontWeight','bold','FontColor','white', ...
            'Position',[settingsX+2*padS+modeBtnW modeRow1Y modeBtnW modeBtnH], ...
            'ButtonPushedFcn',@(~,~) onModeSelect('continuous'));
        emoBtn = uibutton(startFig,'push', ...
            'Text','<html><body>&#x1F60A; Emotion</body></html>', ...
            'Interpreter','html', ...
            'FontSize',round(12*sf),'FontWeight','bold','FontColor','white', ...
            'Position',[settingsX+3*padS+2*modeBtnW modeRow1Y modeBtnW modeBtnH], ...
            'ButtonPushedFcn',@(~,~) onModeSelect('emotion'));

        % Guided Prompts toggle (only visible in emotion mode)
        promptBtnW = settingsW - 2*padS;
        promptBtn = uibutton(startFig,'push', ...
            'Text','Guided Prompts: OFF', ...
            'FontSize',round(11*sf),'FontWeight','bold','FontColor','white', ...
            'BackgroundColor',[0.35 0.35 0.35], ...
            'Position',[settingsX+padS modeRow2Y promptBtnW modeBtnH], ...
            'ButtonPushedFcn',@(~,~) onPromptToggle());
        promptBtn.Visible = 'off';

        % Set initial highlight
        updateModeUI();

        addExitButton(startFig, sf);

        % --- Camera preview ---
        previewAx = uiaxes(startFig,'Position',[previewX previewY previewW previewH]);
        previewAx.XTick = []; previewAx.YTick = [];
        previewAx.Color = 'black'; previewAx.XColor = 'none'; previewAx.YColor = 'none';
        previewAx.Toolbar.Visible = 'off';
        previewAx.CLim = [0 255];  % lock color limits to avoid recalculation

        % Create image object once for performance
        try
            initImg = sai_takePhoto(cam);
            hPreview = image(previewAx, initImg);
            axis(previewAx, 'image');
            previewAx.XTick = []; previewAx.YTick = [];
        catch
        end

        % MathWorks logo (bottom-right corner)
        if hasLogo
            logoH_start = round(40*sf);
            logoW_start = round(logoH_start * 5);
            uiimage(startFig,'ImageSource',logoFile, ...
                'Position',[figW-logoW_start-round(10*sf) round(10*sf) logoW_start logoH_start]);
        end

        % START button
        btnW = min(round(figW*0.6), round(500*sf));
        uibutton(startFig,'push','Text','START!', ...
            'FontSize',round(36*sf),'FontWeight','bold', ...
            'BackgroundColor',[0.2 0.8 0.3],'FontColor','white', ...
            'Position',[(figW-btnW)/2 btnPad btnW btnH], ...
            'ButtonPushedFcn',@(~,~) onStartPressed());

        % Live preview via timer (non-blocking for responsive UI)
        previewTimer = timer('ExecutionMode','fixedSpacing', ...
            'Period', 0.05, 'BusyMode','drop', ...
            'TimerFcn', @(~,~) updatePreview());
        start(previewTimer);

        % Wait for START or Exit (non-blocking pause loop)
        tic;
        while ~startPressed && ~exitRequested
            if ~isvalid(startFig), keepRunning = false; break; end
            if toc > cfg.resetTimeout, tic; end
            pause(0.1);
        end
        stop(previewTimer); delete(previewTimer);
        if ~keepRunning || exitRequested, break; end

        % --- If network changed, show loading screen and reload ---
        if ~strcmpi(pendingNetworkName, S.networkName) && strcmpi(currentMode,'objectid')
            delete(startFig);
            loadFig = uifigure('Name','Loading Network...','Color',[0.18 0.55 0.78], ...
                'WindowState','maximized');
            [figW2, figH2] = waitForMaximize(loadFig);
            uilabel(loadFig, ...
                'Text',ehtml('&#x1F916;',sprintf('Loading %s...', pendingNetworkName)), ...
                'Interpreter','html', ...
                'FontSize',round(36*sf),'FontWeight','bold','FontColor','white', ...
                'HorizontalAlignment','center','Position',[0 0 figW2 figH2]);
            drawnow;
            try
                [net, inputSize, isOnnx] = sai_loadNetwork(pendingNetworkName);
                S.net = net; S.inputSize = inputSize; S.isOnnx = isOnnx;
                S.networkName = pendingNetworkName;
                if isOnnx
                    S.imagenetLabels = sai_imagenetLabels();
                else
                    S.imagenetLabels = {};
                end
            catch ME2
                uilabel(loadFig, ...
                    'Text',ehtml('&#x274C;',['Failed: ' ME2.message]), ...
                    'Interpreter','html', ...
                    'FontSize',round(20*sf),'FontColor','white', ...
                    'HorizontalAlignment','center','Position',[0 0 figW2 figH2*0.4]);
                drawnow; pause(3);
            end
            delete(loadFig);
        else
            delete(startFig);
        end

        % ==================== CONTINUOUS MODE ====================
        if strcmpi(currentMode, 'continuous')
            useDetector = isDetectorName(pendingNetworkName);

            contFig = uifigure('Name','Continuous Detection','Color','black', ...
                'WindowState','maximized');
            [figW, figH] = waitForMaximize(contFig);
            sf = scaleFactor(figW, figH);
            addExitButton(contFig, sf);

            % Camera display
            statusBarH = round(50*sf);
            contLabelH = round(80*sf);
            camBottomY = statusBarH;  % adjusted below for classifier mode
            contAx = uiaxes(contFig,'Position',[0 camBottomY figW figH-camBottomY]);
            contAx.XTick = []; contAx.YTick = [];
            contAx.Color = 'black'; contAx.XColor = 'none'; contAx.YColor = 'none';
            contAx.Toolbar.Visible = 'off'; contAx.CLim = [0 255];

            try
                initFrame = sai_takePhoto(cam);
                hContImg = image(contAx, initFrame);
                axis(contAx, 'image');
                contAx.XTick = []; contAx.YTick = [];
            catch
                hContImg = [];
            end

            % Status overlay (bottom bar)
            contStatus = uilabel(contFig,'Text','Loading...', ...
                'FontSize',round(18*sf),'FontColor','yellow', ...
                'BackgroundColor',[0 0 0 0.5], ...
                'HorizontalAlignment','center', ...
                'Position',[0 0 figW statusBarH]);

            % Classification label overlay (large, above status bar — classifier mode only)
            contLabel = uilabel(contFig,'Text','Classifying...','Interpreter','html', ...
                'FontSize',round(36*sf),'FontWeight','bold', ...
                'FontColor','yellow','HorizontalAlignment','center', ...
                'BackgroundColor','black', ...
                'Position',[0 statusBarH figW contLabelH]);
            contLabel.Visible = 'off';

            % Back button
            backW = round(140*sf); backH = round(40*sf);
            backPressed = false;
            uibutton(contFig,'push','Text','Back to Settings', ...
                'FontSize',round(12*sf),'FontWeight','bold', ...
                'BackgroundColor',[0.3 0.3 0.8],'FontColor','white', ...
                'Position',[round(10*sf) figH-backH-round(40*sf) backW backH], ...
                'ButtonPushedFcn',@(~,~) setBackPressed());
            drawnow;

            totalDetections = 0;
            uniqueLabels = {};
            contNet = []; contIsOnnx = false; contImgnetLabels = {};
            detector = [];
            timerStarted = false;

            if useDetector
                % --- YOLO detector path ---
                contStatus.Text = 'Loading YOLO detector...';
                drawnow;
                try
                    detector = sai_loadDetector(pendingNetworkName);
                    contStatus.Text = 'Detecting objects...';
                catch ME3
                    contStatus.Text = sprintf('Detector load failed: %s', ME3.message);
                end
            else
                % --- Classifier path ---
                contStatus.Text = sprintf('Loading %s...', pendingNetworkName);
                drawnow;
                try
                    [contNet, contInputSize, contIsOnnx] = sai_loadNetwork(pendingNetworkName);
                    contEmojiMap = sai_buildEmojiMap();
                    if contIsOnnx
                        contImgnetLabels = sai_imagenetLabels();
                    end
                    contStatus.Text = sprintf('Classifying with %s...', pendingNetworkName);
                    contLabel.Visible = 'on';
                    % Shrink camera to make room for label bar
                    contAx.Position = [0 statusBarH+contLabelH figW figH-statusBarH-contLabelH];
                catch ME3
                    contStatus.Text = sprintf('Network load failed: %s', ME3.message);
                end
            end
            drawnow;

            if ~isempty(hContImg) && (useDetector && ~isempty(detector) || ~useDetector && ~isempty(contNet))
                if useDetector
                    detTimer = timer('ExecutionMode','fixedSpacing', ...
                        'Period', 0.15, 'BusyMode','drop', ...
                        'TimerFcn', @(~,~) detectAndDisplay());
                else
                    detTimer = timer('ExecutionMode','fixedSpacing', ...
                        'Period', 0.15, 'BusyMode','drop', ...
                        'TimerFcn', @(~,~) classifyAndDisplay());
                end
                start(detTimer);
                timerStarted = true;
            end

            % Wait for back or exit
            while ~backPressed && ~exitRequested
                if ~isvalid(contFig), break; end
                pause(0.2);
            end

            if timerStarted
                try stop(detTimer); delete(detTimer); catch, end
            end
            if isvalid(contFig), delete(contFig); end

            if exitRequested, break; end
            startPressed = false; donePressed = false;
            continue;  % go back to start screen
        end

        % ==================== TAKE PHOTOS ====================
        % Determine photo count and prompt setup
        isPromptMode = promptMode && strcmpi(currentMode, 'emotion');
        if isPromptMode
            promptEmotions = {'neutral','happy','sad','surprise','angry'};
            promptEmojiMap = sai_buildEmotionEmojiMap();
            nPhotos = numel(promptEmotions);
        else
            nPhotos = cfg.numPhotos;
        end
        photos = cell(1, nPhotos);
        pEmoji = strings(1, nPhotos);
        pName  = strings(1, nPhotos);
        pConf  = strings(1, nPhotos);
        pPrompt      = strings(1, nPhotos);  % prompted emotion (raw key)
        pPromptEmoji = strings(1, nPhotos);  % prompted emoji HTML

        snapFig = uifigure('Name','Taking Photos...','Color','black', ...
            'WindowState','maximized');
        [figW, figH] = waitForMaximize(snapFig);
        sf = scaleFactor(figW, figH);
        addExitButton(snapFig, sf);

        statusH    = round(100*sf);
        predLabelH = round(70*sf);
        thumbH     = round(120*sf);
        pad        = round(10*sf);
        camY = predLabelH + thumbH + 3*pad;
        camH = figH - statusH - camY - pad;

        % Emotion guide panel on right side
        guideW = 0;
        if strcmpi(currentMode, 'emotion')
            guideW = round(320*sf);
        end

        camW = min(figW - 2*pad - guideW, camH*4/3);
        camX = (figW - camW - guideW)/2;

        statusLabel = uilabel(snapFig,'Text','', ...
            'Interpreter','html', ...
            'FontSize',round(48*sf),'FontWeight','bold', ...
            'FontColor','white','HorizontalAlignment','center', ...
            'Position',[0 figH-statusH figW statusH]);

        cameraAx = uiaxes(snapFig,'Position',[camX camY camW camH]);
        cameraAx.XTick = []; cameraAx.YTick = [];
        cameraAx.Color = 'black'; cameraAx.XColor = 'none'; cameraAx.YColor = 'none';
        cameraAx.Toolbar.Visible = 'off';
        cameraAx.CLim = [0 255];

        % Create camera image object once
        try
            initCamImg = sai_takePhoto(cam);
            hCam = image(cameraAx, initCamImg);
            axis(cameraAx, 'image');
            cameraAx.XTick = []; cameraAx.YTick = [];
        catch
        end

        thumbW_px = thumbH;
        thumbAx = uiaxes(snapFig,'Position',[(figW-thumbW_px)/2 predLabelH+2*pad thumbW_px thumbH]);
        thumbAx.XTick = []; thumbAx.YTick = [];
        thumbAx.Color = 'black'; thumbAx.XColor = 'none'; thumbAx.YColor = 'none';
        thumbAx.Toolbar.Visible = 'off'; thumbAx.Visible = 'off';

        predLabel = uilabel(snapFig,'Text','', ...
            'Interpreter','html', ...
            'FontSize',round(28*sf),'FontWeight','bold', ...
            'FontColor','yellow','HorizontalAlignment','center', ...
            'Position',[0 pad figW predLabelH]);

        % Emotion guide panel
        if strcmpi(currentMode, 'emotion')
            guideX = camX + camW + round(10*sf);
            guidePanel = uipanel(snapFig, ...
                'Title','Emotions','FontSize',round(16*sf), ...
                'BackgroundColor',[0.12 0.12 0.12], ...
                'ForegroundColor','white', ...
                'Position',[guideX camY guideW camH]);
            emotionLabels = sai_emotionLabels();
            guideEmojiMap = sai_buildEmotionEmojiMap();
            eRowH = round((camH - round(40*sf)) / numel(emotionLabels));
            for ei = 1:numel(emotionLabels)
                ey = camH - round(40*sf) - ei*eRowH;
                emojiForLabel = guideEmojiMap(emotionLabels{ei});
                htmlStr = sprintf(['<html><body style="text-align:center;%s">' ...
                    '<span style="font-size:2.5em;">%s</span><br/>' ...
                    '<b>%s</b></body></html>'], ...
                    emojiFontCSS(), emojiForLabel, sai_cleanLabel(emotionLabels{ei}));
                uilabel(guidePanel,'Text',htmlStr, ...
                    'Interpreter','html', ...
                    'FontSize',round(18*sf),'FontColor','white', ...
                    'HorizontalAlignment','center', ...
                    'Position',[round(4*sf) ey guideW-round(8*sf) eRowH]);
            end
        end

        % Prompt label (only used in guided prompt mode, placed above camera)
        promptLabel = uilabel(snapFig,'Text','','Interpreter','html', ...
            'FontSize',round(36*sf),'FontWeight','bold', ...
            'FontColor','white','HorizontalAlignment','center', ...
            'Position',[camX figH-statusH-round(80*sf) camW round(70*sf)]);
        promptLabel.Visible = 'off';

        % Photo loop
        for p = 1:nPhotos
            if exitRequested, break; end
            try
                thumbAx.Visible = 'off'; predLabel.Text = '';

                % Show prompt emoji if in guided prompt mode
                if isPromptMode
                    pPrompt(p) = string(promptEmotions{p});
                    pPromptEmoji(p) = string(promptEmojiMap(promptEmotions{p}));
                    promptLabel.Text = sprintf( ...
                        '<html><body style="text-align:center;%s"><span style="font-size:2.0em;">%s</span> Try to look <b>%s</b>!</body></html>', ...
                        emojiFontCSS(), char(pPromptEmoji(p)), upper(char(pPrompt(p))));
                    promptLabel.Visible = 'on';
                    drawnow;
                end

                if p == 1
                    countSec = cfg.countdownBefore;
                else
                    countSec = cfg.delayBetween;
                end

                % Countdown with timer-based camera preview
                countdownTimer = timer('ExecutionMode','fixedSpacing', ...
                    'Period', 0.05, 'BusyMode','drop', ...
                    'TimerFcn', @(~,~) updateCamPreview());
                start(countdownTimer);
                for w = countSec:-1:1
                    if exitRequested, break; end
                    if p == 1
                        statusLabel.Text = ehtmlf('&#x1F3AF;','Photo %d of %d &mdash; %d', p, nPhotos, w);
                    else
                        statusLabel.Text = ehtmlf('','Next photo in %d...', w);
                    end
                    drawnow;
                    pause(1);
                end
                stop(countdownTimer); delete(countdownTimer);

                statusLabel.Text = ehtmlf('&#x1F4F8;','SNAP!  Photo %d of %d', p, nPhotos);
                drawnow;
                img = sai_takePhoto(cam);
                photos{p} = img;
                hCam.CData = img;
                drawnow;

                % Hide prompt during classification
                if isPromptMode
                    promptLabel.Visible = 'off';
                end

                % Classify
                if strcmpi(currentMode, 'emotion') && ~isempty(S.emotionNet)
                    [em, lb, ct, ~] = sai_classifyEmotion(img, S.emotionNet, S.emotionInputSize, S.emotionEmojiMap);
                    pEmoji(p) = string(em);
                    pName(p)  = string(lb);
                    pConf(p)  = string(ct);
                elseif S.isOnnx
                    % ONNX model: use predict + argmax + label lookup
                    imResized = imresize(img, inputSize);
                    imSingle = single(imResized) / 255;
                    dl = dlarray(imSingle, 'SSCB');
                    scores = extractdata(predict(net, dl));
                    scores = scores(:)';
                    [maxScr, idx] = max(scores);
                    lbl = S.imagenetLabels{idx};
                    pEmoji(p) = string(sai_lookupEmoji(lbl, emojiMap));
                    pName(p)  = string(sai_modernizeLabel(sai_cleanLabel(lbl)));
                    pConf(p)  = string(sai_confidenceText(maxScr));
                else
                    imResized = imresize(img, inputSize);
                    [lbl, scr] = classify(net, imResized);
                    pEmoji(p) = string(sai_lookupEmoji(lbl, emojiMap));
                    pName(p)  = string(sai_modernizeLabel(sai_cleanLabel(lbl)));
                    pConf(p)  = string(sai_confidenceText(max(scr)));
                end

                statusLabel.Text = ehtmlf('','Photo %d of %d &mdash; Result:', p, nPhotos);
                thumbAx.Visible = 'on';
                image(thumbAx, img); thumbAx.XTick = []; thumbAx.YTick = [];
                axis(thumbAx, 'image');

                % Show result (with prompt comparison if guided mode)
                if isPromptMode
                    isMatch = strcmpi(pPrompt(p), pName(p));
                    if isMatch, matchStr = '&#x2705;'; else, matchStr = '&#x274C;'; end
                    predLabel.Text = sprintf( ...
                        '<html><body style="%s">Prompt: %s <b>%s</b> &rarr; Detected: %s <b>%s</b> %s</body></html>', ...
                        emojiFontCSS(), char(pPromptEmoji(p)), sai_cleanLabel(char(pPrompt(p))), ...
                        char(pEmoji(p)), char(pName(p)), matchStr);
                else
                    predLabel.Text = ehtmlPred(pEmoji(p), pName(p), pConf(p));
                end
                drawnow; pause(2);
            catch
                photos{p} = uint8(128*ones(224,224,3));
                pEmoji(p) = "?"; pName(p) = "Camera Error"; pConf(p) = "";
            end
        end
        delete(snapFig);
        if exitRequested, break; end

        % ==================== RESULTS GALLERY ====================
        donePressed = false;
        feedback = zeros(1, nPhotos);

        resFig = uifigure('Name','Results','Color','white','WindowState','maximized');
        [figW, figH] = waitForMaximize(resFig);
        sf = scaleFactor(figW, figH);
        addExitButton(resFig, sf);

        margin   = round(12*sf);
        titleH   = round(60*sf);
        bottomH  = round(70*sf);
        gapV     = round(6*sf);
        availH   = figH - titleH - bottomH - 2*margin;
        rowH     = min(floor((availH - (nPhotos-1)*gapV) / nPhotos), round(200*sf));
        imgSize  = rowH - 4;
        thumbBtnW   = max(round(50*sf), min(round(80*sf), floor(rowH*0.65)));
        thumbBtnGap = round(8*sf);
        labelFS     = max(round(14*sf), min(round(22*sf), floor(rowH*0.20)));
        thumbFS     = max(round(18*sf), min(round(30*sf), floor(thumbBtnW*0.45)));

        % Scrollable panel for results
        scrollPanel = uipanel(resFig, ...
            'Position',[0 bottomH figW figH-titleH-bottomH], ...
            'BackgroundColor','white','BorderType','none', ...
            'Scrollable','on');
        panelH = max(availH, nPhotos*(rowH+gapV));

        if isPromptMode
            titleText = ['<html><body style="text-align:center;font-weight:bold;' emojiFontCSS() '">&#x1F3AD; How did you do? Prompt vs. Computer!</body></html>'];
        else
            titleText = ['<html><body style="text-align:center;font-weight:bold;' emojiFontCSS() '">&#x1F3C6; Was the Computer Right? Tap &#x1F44D; or &#x1F44E; !</body></html>'];
        end
        uilabel(resFig,'Text',titleText,'Interpreter','html', ...
            'FontSize',round(28*sf),'FontWeight','bold', ...
            'HorizontalAlignment','center','Position',[0 figH-titleH-margin figW titleH]);

        for p = 1:nPhotos
            y = panelH - p*(rowH+gapV) + gapV;
            thumbFile = fullfile(tempdir, sprintf('snap_thumb_%d.png', p));
            imwrite(imresize(photos{p}, [imgSize imgSize]), thumbFile);

            if isPromptMode
                % Prompt mode: show prompt vs detected with match indicator
                isMatch = strcmpi(pPrompt(p), pName(p));
                matchStr = char("&#x2705;" * isMatch + "&#x274C;" * ~isMatch);
                rowLabelText = sprintf( ...
                    '<html><body style="%s">Prompt: %s <b>%s</b> &rarr; Detected: %s <b>%s</b> %s</body></html>', ...
                    emojiFontCSS(), char(pPromptEmoji(p)), sai_cleanLabel(char(pPrompt(p))), ...
                    char(pEmoji(p)), char(pName(p)), matchStr);
                labelW = round(550*sf);
                gapH   = round(12*sf);
                contentW = imgSize + gapH + labelW;
                rowX = max(margin, (figW - contentW)/2);

                uiimage(scrollPanel,'ImageSource',thumbFile, ...
                    'Position',[rowX y imgSize imgSize],'ScaleMethod','fit');
                labelX = rowX + imgSize + gapH;
                uilabel(scrollPanel,'Text',rowLabelText,'Interpreter','html', ...
                    'FontSize',labelFS,'FontWeight','bold','VerticalAlignment','center', ...
                    'WordWrap','on','Position',[labelX y labelW rowH]);
            else
                % Normal mode: show result + thumbs up/down buttons
                btnAreaW = 2*thumbBtnW + thumbBtnGap;
                labelW   = round(450*sf);
                gapH     = round(12*sf);
                contentW = imgSize + gapH + labelW + gapH + btnAreaW;
                rowX     = max(margin, (figW - contentW)/2);

                uiimage(scrollPanel,'ImageSource',thumbFile, ...
                    'Position',[rowX y imgSize imgSize],'ScaleMethod','fit');

                labelX = rowX + imgSize + gapH;
                uilabel(scrollPanel, ...
                    'Text',ehtmlPred(pEmoji(p), pName(p), pConf(p)), ...
                    'Interpreter','html', ...
                    'FontSize',labelFS,'FontWeight','bold','VerticalAlignment','center', ...
                    'WordWrap','on','Position',[labelX y labelW rowH]);

                thumbUpX = labelX + labelW + gapH;
                btnY = y + (rowH - thumbBtnW)/2;
                upBtn = uibutton(scrollPanel,'push','Text','👍','FontSize',thumbFS, ...
                    'BackgroundColor',[0.85 0.95 0.85],'Position',[thumbUpX btnY thumbBtnW thumbBtnW]);
                dnBtn = uibutton(scrollPanel,'push','Text','👎','FontSize',thumbFS, ...
                    'BackgroundColor',[0.95 0.85 0.85],'Position',[thumbUpX+thumbBtnW+thumbBtnGap btnY thumbBtnW thumbBtnW]);
                upBtn.ButtonPushedFcn = @(~,~) onFeedback(upBtn, dnBtn, p, 1);
                dnBtn.ButtonPushedFcn = @(~,~) onFeedback(upBtn, dnBtn, p, -1);
            end
        end

        doneW = min(round(180*sf), figW*0.22);
        doneBtnH = bottomH - 2*margin;
        if isPromptMode
            % Auto-calculate score for prompt mode
            numMatched = sum(arrayfun(@(i) strcmpi(pPrompt(i), pName(i)), 1:nPhotos));
            scoreLbl = uilabel(resFig, ...
                'Text',sprintf('<html><body style="%s">You matched %d out of %d prompts!</body></html>', emojiFontCSS(), numMatched, nPhotos), ...
                'Interpreter','html', ...
                'FontSize',round(18*sf),'FontColor',[0.2 0.2 0.6], ...
                'HorizontalAlignment','center','VerticalAlignment','center', ...
                'WordWrap','on', ...
                'Position',[margin margin figW-doneW-3*margin doneBtnH]);
        else
            scoreLbl = uilabel(resFig, ...
                'Text',['<html><body style="' emojiFontCSS() '">Tap &#x1F44D; or &#x1F44E; for each, then DONE!</body></html>'], ...
                'Interpreter','html', ...
                'FontSize',round(16*sf),'FontColor',[0.4 0.4 0.4], ...
                'HorizontalAlignment','center','VerticalAlignment','center', ...
                'WordWrap','on', ...
                'Position',[margin margin figW-doneW-3*margin doneBtnH]);
        end
        uibutton(resFig,'push','Text','DONE!','FontSize',round(22*sf), ...
            'FontWeight','bold','BackgroundColor',[0.2 0.7 0.9],'FontColor','white', ...
            'Position',[figW-doneW-margin margin doneW doneBtnH], ...
            'ButtonPushedFcn',@(~,~) onDonePressed());

        tic;
        while ~donePressed && ~exitRequested
            if ~isvalid(resFig), break; end
            if toc > cfg.resetTimeout, break; end
            if ~isPromptMode
                nC = sum(feedback==1); nR = sum(feedback~=0);
                if nR > 0
                    scoreLbl.Text = sprintf('<html><body>Score so far: %d out of %d right!</body></html>', nC, nR);
                end
            end
            pause(0.3); drawnow;
        end
        if exitRequested
            if isvalid(resFig), delete(resFig); end
            break;
        end

        % ==================== SCORE SUMMARY ====================
        if isvalid(resFig)
            if isPromptMode
                numCorrect = sum(arrayfun(@(i) strcmpi(pPrompt(i), pName(i)), 1:nPhotos));
                numTotal   = nPhotos;
            else
                numCorrect = sum(feedback==1);
                numTotal   = sum(feedback~=0);
            end
            delete(resFig);
            scoreFig = uifigure('Name','Final Score!','Color',[0.18 0.55 0.78], ...
                'WindowState','maximized');
            [figW, figH] = waitForMaximize(scoreFig);
            sf = scaleFactor(figW, figH);

            css = emojiFontCSS();
            if numTotal == 0
                scoreHtml = sprintf('<html><body style="text-align:center;%s"><span style="font-size:%.0fpx;">&#x1F916;</span><br/><br/>Thanks for playing!</body></html>', css, 60*sf);
            elseif numCorrect == numTotal
                scoreHtml = sprintf('<html><body style="text-align:center;%s"><span style="font-size:%.0fpx;">&#x1F389;</span><br/><br/>PERFECT SCORE!<br/>The computer got ALL %d right!</body></html>', css, 60*sf, numTotal);
            elseif numCorrect > numTotal/2
                scoreHtml = sprintf('<html><body style="text-align:center;%s"><span style="font-size:%.0fpx;">&#x1F31F;</span><br/><br/>Nice!<br/>The computer got %d out of %d right!</body></html>', css, 60*sf, numCorrect, numTotal);
            else
                scoreHtml = sprintf('<html><body style="text-align:center;%s"><span style="font-size:%.0fpx;">&#x1F914;</span><br/><br/>Tricky!<br/>The computer only got %d out of %d right.<br/>Computers still have a lot to learn!</body></html>', css, 60*sf, numCorrect, numTotal);
            end
            uilabel(scoreFig,'Text',scoreHtml, ...
                'Interpreter','html', ...
                'FontSize',round(40*sf), ...
                'FontWeight','bold','FontColor','white','HorizontalAlignment','center', ...
                'WordWrap','on','Position',[figW*0.05 figH*0.25 figW*0.9 figH*0.55]);
            uilabel(scoreFig, ...
                'Text',['<html><body style="text-align:center;' css '">&#x1F9E0; This computer looked at millions of pictures to learn &mdash; just like how you learn by seeing things over and over!</body></html>'], ...
                'Interpreter','html', ...
                'FontSize',round(20*sf),'FontColor',[0.85 0.92 1.0], ...
                'HorizontalAlignment','center','WordWrap','on', ...
                'Position',[figW*0.1 figH*0.05 figW*0.8 figH*0.2]);
            if hasLogo
                logoH_score = round(50*sf);
                logoW_score = round(logoH_score * 5);
                uiimage(scoreFig,'ImageSource',logoFile, ...
                    'Position',[(figW-logoW_score)/2 round(15*sf) logoW_score logoH_score]);
            end
            % Play Again button
            playAgainW = round(280*sf);
            playAgainH = round(60*sf);
            startPressed = false;
            uibutton(scoreFig,'push','Text','Play Again!', ...
                'FontSize',round(24*sf),'FontWeight','bold', ...
                'BackgroundColor',[0.2 0.8 0.3],'FontColor','white', ...
                'Position',[(figW-playAgainW)/2 figH*0.12 playAgainW playAgainH], ...
                'ButtonPushedFcn',@(~,~) onStartPressed());
            addExitButton(scoreFig, sf);

            scoreDeadline = tic;
            while toc(scoreDeadline) < 15 && ~exitRequested && ~startPressed
                if ~isvalid(scoreFig), break; end
                pause(0.3); drawnow;
            end
            if isvalid(scoreFig), delete(scoreFig); end
        end

        if exitRequested, break; end
        startPressed = false; donePressed = false;
        feedback = zeros(1, nPhotos);
    end

    % Cleanup on exit
    try clear cam; catch, end
    % Close any lingering figures from this session
    allFigs = findall(0, 'Type', 'figure');
    for f = 1:numel(allFigs)
        if contains(allFigs(f).Name, 'Snap & Identify') || ...
           contains(allFigs(f).Name, 'Taking Photos') || ...
           contains(allFigs(f).Name, 'Results') || ...
           contains(allFigs(f).Name, 'Final Score') || ...
           contains(allFigs(f).Name, 'Loading Network') || ...
           contains(allFigs(f).Name, 'Continuous Detection')
            delete(allFigs(f));
        end
    end

    % ===== NESTED CALLBACK FUNCTIONS =====
    function onStartPressed()
        startPressed = true;
    end

    function onDonePressed()
        donePressed = true;
    end

    function onExit()
        exitRequested = true;
        keepRunning = false;
    end

    function addExitButton(fig, sf_local)
        exitW = round(70*sf_local);
        exitH = round(30*sf_local);
        uibutton(fig,'push','Text','Exit', ...
            'FontSize',round(12*sf_local), ...
            'BackgroundColor',[0.6 0.1 0.1],'FontColor','white', ...
            'Position',[fig.Position(3)-exitW-round(5*sf_local) fig.Position(4)-exitH-round(5*sf_local) exitW exitH], ...
            'ButtonPushedFcn',@(~,~) onExit());
    end

    function onFeedback(upBtn, dnBtn, photoIdx, value)
        feedback(photoIdx) = value;
        if value == 1
            upBtn.BackgroundColor = [0.3 0.85 0.3];
            dnBtn.BackgroundColor = [0.95 0.85 0.85];  % reset other
        else
            dnBtn.BackgroundColor = [0.9 0.3 0.3];
            upBtn.BackgroundColor = [0.85 0.95 0.85];  % reset other
        end
    end

    function onSettingChange(field, value)
        cfg.(field) = value;
    end

    function onNetworkSelect(value)
        pendingNetworkName = value;
    end

    function updatePreview()
        try
            hPreview.CData = snapshot(cam);
            drawnow limitrate;
        catch
        end
    end

    function updateCamPreview()
        try
            hCam.CData = snapshot(cam);
            drawnow limitrate;
        catch
        end
    end

    function onCameraSelect(newIndex)
        try
            clear cam;
            cam = sai_setupCamera(newIndex);
            cfg.cameraIndex = newIndex;
            % Update preview with new camera
            try
                hPreview.CData = sai_takePhoto(cam);
            catch
            end
        catch ME3
            fprintf('Camera switch failed: %s\n', ME3.message);
        end
    end

    function onModeSelect(mode)
        currentMode = mode;
        updateModeUI();
    end

    function onPromptToggle()
        promptMode = ~promptMode;
        if promptMode
            promptBtn.Text = 'Guided Prompts: ON';
            promptBtn.BackgroundColor = [0.2 0.7 0.4];
        else
            promptBtn.Text = 'Guided Prompts: OFF';
            promptBtn.BackgroundColor = [0.35 0.35 0.35];
        end
    end

    function setBackPressed()
        backPressed = true;
    end

    function detectAndDisplay()
        try
            frame = snapshot(cam);
            [bboxes, scores, labels] = detect(detector, frame, 'Threshold', 0.4);
            if ~isempty(bboxes)
                annotated = insertObjectAnnotation(frame, 'rectangle', bboxes, labels, ...
                    'FontSize', 18, 'LineWidth', 3);
                hContImg.CData = annotated;
                % Track stats
                for dj = 1:numel(labels)
                    lStr = char(labels(dj));
                    if ~ismember(lStr, uniqueLabels)
                        uniqueLabels{end+1} = lStr; %#ok<AGROW>
                    end
                end
                totalDetections = totalDetections + numel(labels);
                contStatus.Text = sprintf('Objects found: %d | Unique types: %d', totalDetections, numel(uniqueLabels));
            else
                hContImg.CData = frame;
            end
            drawnow limitrate;
        catch
        end
    end

    function classifyAndDisplay()
        try
            frame = snapshot(cam);
            hContImg.CData = frame;
            % Classify
            if contIsOnnx
                imResized = imresize(frame, contInputSize);
                imSingle = single(imResized) / 255;
                dl = dlarray(imSingle, 'SSCB');
                scores = extractdata(predict(contNet, dl));
                scores = scores(:)';
                [maxScr, idx] = max(scores);
                lbl = contImgnetLabels{idx};
            else
                imResized = imresize(frame, contInputSize);
                [lbl, scr] = classify(contNet, imResized);
                maxScr = max(scr);
                lbl = char(lbl);
            end
            emoji = sai_lookupEmoji(lbl, contEmojiMap);
            cleanName = sai_modernizeLabel(sai_cleanLabel(lbl));
            confStr = sai_confidenceText(maxScr);
            contLabel.Text = sprintf( ...
                '<html><body style="%s"><span style="font-size:1.4em;">%s</span> <b>%s</b> &mdash; %s</body></html>', ...
                emojiFontCSS(), emoji, cleanName, confStr);
            totalDetections = totalDetections + 1;
            if ~ismember(cleanName, uniqueLabels)
                uniqueLabels{end+1} = cleanName; %#ok<AGROW>
            end
            contStatus.Text = sprintf('Classifications: %d | Unique: %d', totalDetections, numel(uniqueLabels));
            drawnow limitrate;
        catch ME4
            try
                contLabel.Text = sprintf('Error: %s', ME4.message);
                drawnow limitrate;
            catch
            end
        end
    end

    function updateModeUI()
        objBtn.BackgroundColor  = modeInactiveColor;
        contBtn.BackgroundColor = modeInactiveColor;
        emoBtn.BackgroundColor  = modeInactiveColor;
        if strcmpi(currentMode, 'objectid')
            objBtn.BackgroundColor = modeActiveColor;
            netLabel.Visible = 'on';  ddNetwork.Visible = 'on';
            ddPhotos.Enable = 'on';   ddDelay.Enable = 'on';  ddCountdown.Enable = 'on';
            promptBtn.Visible = 'off';
            % Restore classifier if coming from continuous
            if isDetectorName(pendingNetworkName)
                pendingNetworkName = savedClassifierName;
                ddNetwork.Value = pendingNetworkName;
            end
        elseif strcmpi(currentMode, 'continuous')
            contBtn.BackgroundColor = modeActiveColor;
            netLabel.Visible = 'on';  ddNetwork.Visible = 'on';
            ddPhotos.Enable = 'off';  ddDelay.Enable = 'off';  ddCountdown.Enable = 'off';
            promptBtn.Visible = 'off';
            % Save current classifier and default to YOLO
            if ~isDetectorName(pendingNetworkName)
                savedClassifierName = pendingNetworkName;
            end
            if ismember('tiny-yolov4-coco', ddNetwork.ItemsData)
                pendingNetworkName = 'tiny-yolov4-coco';
                ddNetwork.Value = 'tiny-yolov4-coco';
            end
        elseif strcmpi(currentMode, 'emotion')
            emoBtn.BackgroundColor = modeActiveColor;
            netLabel.Visible = 'off';  ddNetwork.Visible = 'off';
            ddPhotos.Enable = 'on';    ddDelay.Enable = 'on';   ddCountdown.Enable = 'on';
            promptBtn.Visible = 'on';
            % Restore classifier if coming from continuous
            if isDetectorName(pendingNetworkName)
                pendingNetworkName = savedClassifierName;
                ddNetwork.Value = pendingNetworkName;
            end
        end
    end
end

% ===== HELPER FUNCTIONS =====

function s = ehtml(emojiCode, text)
    css = emojiFontCSS();
    if isempty(emojiCode)
        s = sprintf('<html><body style="%s">%s</body></html>', css, text);
    else
        s = sprintf('<html><body style="%s"><span style="font-size:1.2em;">%s</span> %s</body></html>', css, emojiCode, text);
    end
end

function s = ehtmlf(emojiCode, fmt, varargin)
    text = sprintf(fmt, varargin{:});
    s = ehtml(emojiCode, text);
end

function s = ehtmlPred(emoji, name, conf)
    css = emojiFontCSS();
    e = char(emoji); n = char(name); c = char(conf);
    s = sprintf('<html><body style="%s"><span style="font-size:1.3em;">%s</span> <b>%s</b> &mdash; %s</body></html>', css, e, n, c);
end

function css = emojiFontCSS()
    css = 'font-family:''Segoe UI Emoji'',''Apple Color Emoji'',''Noto Color Emoji'',sans-serif;';
end

function sf = scaleFactor(figW, figH)
    sf = min(figW/1920, figH/1080);
    sf = max(sf, 0.5);
end

function [figW, figH] = waitForMaximize(fig)
    drawnow;
    screenSz = get(0, 'ScreenSize');
    deadline = tic;
    while toc(deadline) < 1.0
        pos = fig.Position;
        if pos(3) > 600 || pos(4) > 500
            figW = pos(3); figH = pos(4); return;
        end
        pause(0.05); drawnow;
    end
    figW = screenSz(3); figH = screenSz(4) - 40;
    fig.Position = [1 1 figW figH];
end

function tf = isDetectorName(name)
    detectors = {'tiny-yolov4-coco', 'yolov4-coco', 'csp-darknet53-coco'};
    tf = ismember(lower(name), detectors);
end
