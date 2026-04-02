function SnapAndIdentify_Desktop(cfg)
% SNAPANDIDENTIFY_DESKTOP  Desktop photo booth with full interactive uifigure UI.
%   Features: configurable settings panel, AI network selection, emotion
%   detection mode, scalable UI, and optimized camera preview performance.

    % Shared state variables (accessible by nested callback functions)
    startPressed  = false;
    donePressed   = false;
    exitRequested = false;
    feedback      = zeros(1, cfg.numPhotos);
    currentMode   = cfg.gameMode;       % 'objectid' or 'emotion'
    pendingNetworkName = cfg.networkName;

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
        allNetNames  = {'googlenet','resnet18','resnet50','squeezenet', 'resnet101'};
        allNetLabels = {'GoogLeNet','ResNet-18','ResNet-50','SqueezeNet', 'resnet101'};
        if isfield(cfg, 'availableNetworks') && ~isempty(cfg.availableNetworks)
            availNets = cfg.availableNetworks;
        else
            availNets = allNetNames;  % fallback: show all
        end
        keepIdx = ismember(allNetNames, availNets);
        ddItems     = allNetLabels(keepIdx);
        ddItemsData = allNetNames(keepIdx);
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

        % Mode selection: two side-by-side buttons
        modeBtnH = round(38*sf);
        modeBtnW = round((settingsW - 3*padS) / 2);
        modeActiveColor   = [0.4 0.2 0.7];
        modeInactiveColor = [0.35 0.35 0.35];

        objBtn = uibutton(startFig,'push', ...
            'Text','<html><body>&#x1F50D; Object ID</body></html>', ...
            'Interpreter','html', ...
            'FontSize',round(14*sf),'FontWeight','bold','FontColor','white', ...
            'Position',[settingsX+padS settingsY+padS modeBtnW modeBtnH], ...
            'ButtonPushedFcn',@(~,~) onModeSelect('objectid'));
        emoBtn = uibutton(startFig,'push', ...
            'Text','<html><body>&#x1F60A; Emotion</body></html>', ...
            'Interpreter','html', ...
            'FontSize',round(14*sf),'FontWeight','bold','FontColor','white', ...
            'Position',[settingsX+2*padS+modeBtnW settingsY+padS modeBtnW modeBtnH], ...
            'ButtonPushedFcn',@(~,~) onModeSelect('emotion'));

        % Set initial highlight
        if strcmpi(currentMode,'emotion')
            emoBtn.BackgroundColor = modeActiveColor;
            objBtn.BackgroundColor = modeInactiveColor;
            netLabel.Visible = 'off';
            ddNetwork.Visible = 'off';
        else
            objBtn.BackgroundColor = modeActiveColor;
            emoBtn.BackgroundColor = modeInactiveColor;
        end

        addExitButton(startFig, sf);

        % --- Camera preview ---
        previewAx = uiaxes(startFig,'Position',[previewX previewY previewW previewH]);
        previewAx.XTick = []; previewAx.YTick = [];
        previewAx.Color = 'black'; previewAx.XColor = 'none'; previewAx.YColor = 'none';
        previewAx.Toolbar.Visible = 'off';

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

        % Live preview loop — update CData only, use drawnow limitrate
        tic;
        while ~startPressed && ~exitRequested
            if ~isvalid(startFig), keepRunning = false; break; end
            if toc > cfg.resetTimeout, tic; end
            try
                hPreview.CData = sai_takePhoto(cam);
            catch
            end
            drawnow limitrate;
        end
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
                [net, inputSize] = sai_loadNetwork(pendingNetworkName);
                S.net = net; S.inputSize = inputSize;
                S.networkName = pendingNetworkName;
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

        % ==================== TAKE PHOTOS ====================
        photos = cell(1, cfg.numPhotos);
        pEmoji = strings(1, cfg.numPhotos);
        pName  = strings(1, cfg.numPhotos);
        pConf  = strings(1, cfg.numPhotos);

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
            guideW = round(240*sf);
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
            eRowH = round(camH / (numel(emotionLabels)+1));
            eFS = round(16*sf);
            for ei = 1:numel(emotionLabels)
                ey = camH - round(40*sf) - ei*eRowH;
                emojiForLabel = guideEmojiMap(emotionLabels{ei});
                htmlStr = sprintf('<html><body style="%s"><span style="font-size:1.4em;">%s</span> %s</body></html>', ...
                    emojiFontCSS(), emojiForLabel, sai_cleanLabel(emotionLabels{ei}));
                uilabel(guidePanel,'Text',htmlStr, ...
                    'Interpreter','html', ...
                    'FontSize',eFS,'FontColor','white', ...
                    'Position',[round(8*sf) ey guideW-round(16*sf) eRowH]);
            end
        end

        % Photo loop
        for p = 1:cfg.numPhotos
            if exitRequested, break; end
            try
                thumbAx.Visible = 'off'; predLabel.Text = '';
                if p == 1
                    countSec = cfg.countdownBefore;
                else
                    countSec = cfg.delayBetween;
                end

                % Countdown with fast inner loop for smooth video
                for w = countSec:-1:1
                    if exitRequested, break; end
                    if p == 1
                        statusLabel.Text = ehtmlf('&#x1F3AF;','Photo %d of %d &mdash; %d', p, cfg.numPhotos, w);
                    else
                        statusLabel.Text = ehtmlf('','Next photo in %d...', w);
                    end
                    deadline = tic;
                    while toc(deadline) < 1
                        if exitRequested, break; end
                        try
                            hCam.CData = sai_takePhoto(cam);
                        catch
                        end
                        drawnow limitrate;
                    end
                end

                statusLabel.Text = ehtmlf('&#x1F4F8;','SNAP!  Photo %d of %d', p, cfg.numPhotos);
                drawnow;
                img = sai_takePhoto(cam);
                photos{p} = img;
                hCam.CData = img;
                drawnow;

                % Classify
                if strcmpi(currentMode, 'emotion') && ~isempty(S.emotionNet)
                    [em, lb, ct, ~] = sai_classifyEmotion(img, S.emotionNet, S.emotionInputSize, S.emotionEmojiMap);
                    pEmoji(p) = string(em);
                    pName(p)  = string(lb);
                    pConf(p)  = string(ct);
                else
                    imResized = imresize(img, inputSize);
                    [lbl, scr] = classify(net, imResized);
                    pEmoji(p) = string(sai_lookupEmoji(lbl, emojiMap));
                    pName(p)  = string(sai_cleanLabel(lbl));
                    pConf(p)  = string(sai_confidenceText(max(scr)));
                end

                statusLabel.Text = ehtmlf('','Photo %d of %d &mdash; Result:', p, cfg.numPhotos);
                thumbAx.Visible = 'on';
                image(thumbAx, img); thumbAx.XTick = []; thumbAx.YTick = [];
                axis(thumbAx, 'image');
                predLabel.Text = ehtmlPred(pEmoji(p), pName(p), pConf(p));
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
        feedback = zeros(1, cfg.numPhotos);

        resFig = uifigure('Name','Results','Color','white','WindowState','maximized');
        [figW, figH] = waitForMaximize(resFig);
        sf = scaleFactor(figW, figH);
        addExitButton(resFig, sf);

        margin   = round(12*sf);
        titleH   = round(60*sf);
        bottomH  = round(70*sf);
        gapV     = round(6*sf);
        availH   = figH - titleH - bottomH - 2*margin;
        rowH     = min(floor((availH - (cfg.numPhotos-1)*gapV) / cfg.numPhotos), round(200*sf));
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
        panelH = max(availH, cfg.numPhotos*(rowH+gapV));

        uilabel(resFig, ...
            'Text',['<html><body style="text-align:center;font-weight:bold;' emojiFontCSS() '">&#x1F3C6; Was the Computer Right? Tap &#x1F44D; or &#x1F44E; !</body></html>'], ...
            'Interpreter','html', ...
            'FontSize',round(28*sf),'FontWeight','bold', ...
            'HorizontalAlignment','center','Position',[0 figH-titleH-margin figW titleH]);

        for p = 1:cfg.numPhotos
            y = panelH - p*(rowH+gapV) + gapV;
            thumbFile = fullfile(tempdir, sprintf('snap_thumb_%d.png', p));
            imwrite(imresize(photos{p}, [imgSize imgSize]), thumbFile);

            % Center the row: image + gap + label + gap + buttons as one group
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

        doneW = min(round(180*sf), figW*0.22);
        doneBtnH = bottomH - 2*margin;
        scoreLbl = uilabel(resFig, ...
            'Text',['<html><body style="' emojiFontCSS() '">Tap &#x1F44D; or &#x1F44E; for each, then DONE!</body></html>'], ...
            'Interpreter','html', ...
            'FontSize',round(16*sf),'FontColor',[0.4 0.4 0.4], ...
            'HorizontalAlignment','center','VerticalAlignment','center', ...
            'WordWrap','on', ...
            'Position',[margin margin figW-doneW-3*margin doneBtnH]);
        uibutton(resFig,'push','Text','DONE!','FontSize',round(22*sf), ...
            'FontWeight','bold','BackgroundColor',[0.2 0.7 0.9],'FontColor','white', ...
            'Position',[figW-doneW-margin margin doneW doneBtnH], ...
            'ButtonPushedFcn',@(~,~) onDonePressed());

        tic;
        while ~donePressed && ~exitRequested
            if ~isvalid(resFig), break; end
            if toc > cfg.resetTimeout, break; end
            nC = sum(feedback==1); nR = sum(feedback~=0);
            if nR > 0
                scoreLbl.Text = sprintf('<html><body>Score so far: %d out of %d right!</body></html>', nC, nR);
            end
            pause(0.3); drawnow;
        end
        if exitRequested
            if isvalid(resFig), delete(resFig); end
            break;
        end

        % ==================== SCORE SUMMARY ====================
        if isvalid(resFig)
            numCorrect = sum(feedback==1);
            numTotal   = sum(feedback~=0);
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
            addExitButton(scoreFig, sf);
            scoreDeadline = tic;
            while toc(scoreDeadline) < 8 && ~exitRequested
                if ~isvalid(scoreFig), break; end
                pause(0.3); drawnow;
            end
            if isvalid(scoreFig), delete(scoreFig); end
        end

        if exitRequested, break; end
        startPressed = false; donePressed = false;
        feedback = zeros(1, cfg.numPhotos);
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
           contains(allFigs(f).Name, 'Loading Network')
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
        if strcmpi(mode, 'emotion')
            emoBtn.BackgroundColor = modeActiveColor;
            objBtn.BackgroundColor = modeInactiveColor;
            netLabel.Visible = 'off';
            ddNetwork.Visible = 'off';
        else
            objBtn.BackgroundColor = modeActiveColor;
            emoBtn.BackgroundColor = modeInactiveColor;
            netLabel.Visible = 'on';
            ddNetwork.Visible = 'on';
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
