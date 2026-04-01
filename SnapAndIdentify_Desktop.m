function SnapAndIdentify_Desktop(cfg)
% SNAPANDIDENTIFY_DESKTOP  Desktop photo booth with full interactive uifigure UI.
%   Requires uifigure support (desktop MATLAB only, NOT MATLAB Mobile).
%   Uses nested functions so button callbacks can access shared state.
%   Uses HTML interpreter for uilabel to render emoji properly.

    % Shared state variables (accessible by nested callback functions)
    startPressed = false;
    donePressed = false;
    feedback = zeros(1, cfg.numPhotos);

    % --- Load ---
    splashFig = uifigure('Name','Snap & Identify','Color',[0.18 0.55 0.78], ...
        'WindowState','maximized');
    [figW, figH] = waitForMaximize(splashFig);
    splashLabel = uilabel(splashFig, ...
        'Text',ehtml('&#x1F916;','Getting the Computer Brain Ready...'), ...
        'Interpreter','html', ...
        'FontSize',36,'FontWeight','bold','FontColor','white', ...
        'HorizontalAlignment','center','Position',[0 0 figW figH]);
    drawnow;

    try
        S = sai_init();
        net = S.net;  inputSize = S.inputSize;  emojiMap = S.emojiMap;
        cam = sai_setupCamera(cfg.cameraMode, cfg.cameraIndex, ...
            cfg.mobileCameraName, cfg.mobileCameraResolution);
        splashLabel.Text = ehtml('&#x2705;','Ready!');
        drawnow; pause(1.5);
    catch ME
        splashLabel.Text = ehtml('&#x274C;',['Error: ' ME.message]);
        splashLabel.FontSize = 24; drawnow; return;
    end
    delete(splashFig);

    keepRunning = true;
    while keepRunning

        % ---- START SCREEN WITH LIVE CAMERA PREVIEW ----
        startPressed = false;
        startFig = uifigure('Name','Snap & Identify: Photo Booth!', ...
            'Color','black','WindowState','maximized');
        [figW, figH] = waitForMaximize(startFig);

        topBarH=90; btnH=80; btnPad=15; infoPad=40;
        uilabel(startFig, ...
            'Text',ehtml('&#x1F4F8;','Snap & Identify!'), ...
            'Interpreter','html', ...
            'FontSize',min(42,floor(figW/22)),'FontWeight','bold', ...
            'FontColor','white','HorizontalAlignment','center', ...
            'BackgroundColor',[0 0 0 0.5], ...
            'Position',[0 figH-topBarH figW topBarH]);
        uilabel(startFig,'Text',sprintf('Hold up an object and tap START!  (%d photos, %d sec apart)',cfg.numPhotos,cfg.delayBetween), ...
            'FontSize',min(18,floor(figW/50)),'FontColor',[0.85 0.92 1.0], ...
            'HorizontalAlignment','center','BackgroundColor',[0 0 0 0.4], ...
            'Position',[0 figH-topBarH-infoPad figW infoPad]);

        previewY = btnH+2*btnPad;
        previewH = figH-topBarH-infoPad-previewY;
        previewW = min(figW, previewH*4/3);
        previewX = (figW-previewW)/2;
        previewAx = uiaxes(startFig,'Position',[previewX previewY previewW previewH]);
        previewAx.XTick=[]; previewAx.YTick=[];
        previewAx.Color='black'; previewAx.XColor='none'; previewAx.YColor='none';
        previewAx.Toolbar.Visible='off';

        btnW = min(figW*0.6, 500);
        uibutton(startFig,'push','Text','START!', ...
            'FontSize',min(36,floor(btnH*0.45)),'FontWeight','bold', ...
            'BackgroundColor',[0.2 0.8 0.3],'FontColor','white', ...
            'Position',[(figW-btnW)/2 btnPad btnW btnH], ...
            'ButtonPushedFcn',@(~,~) onStartPressed());

        tic;
        while ~startPressed
            if ~isvalid(startFig), keepRunning=false; break; end
            if toc > cfg.resetTimeout, tic; end
            try
                pImg = sai_takePhoto(cam);
                image(previewAx,pImg); previewAx.XTick=[]; previewAx.YTick=[];
                axis(previewAx,'image');
            catch, end
            drawnow; pause(0.05);
        end
        if ~keepRunning, break; end
        delete(startFig);

        % ---- TAKE PHOTOS ----
        photos = cell(1,cfg.numPhotos);
        pEmoji = strings(1,cfg.numPhotos);
        pName  = strings(1,cfg.numPhotos);
        pConf  = strings(1,cfg.numPhotos);

        snapFig = uifigure('Name','Taking Photos...','Color','black', ...
            'WindowState','maximized');
        [figW, figH] = waitForMaximize(snapFig);

        statusH=100; predLabelH=70; thumbH=120; pad=10;
        camY = predLabelH+thumbH+3*pad;
        camH = figH-statusH-camY-pad;
        camW = min(figW-2*pad, camH*4/3);
        camX = (figW-camW)/2;

        statusLabel = uilabel(snapFig,'Text','', ...
            'Interpreter','html', ...
            'FontSize',min(48,floor(figW/18)),'FontWeight','bold', ...
            'FontColor','white','HorizontalAlignment','center', ...
            'Position',[0 figH-statusH figW statusH]);
        cameraAx = uiaxes(snapFig,'Position',[camX camY camW camH]);
        cameraAx.XTick=[]; cameraAx.YTick=[];
        cameraAx.Color='black'; cameraAx.XColor='none'; cameraAx.YColor='none';
        cameraAx.Toolbar.Visible='off';
        thumbW=thumbH;
        thumbAx = uiaxes(snapFig,'Position',[(figW-thumbW)/2 predLabelH+2*pad thumbW thumbH]);
        thumbAx.XTick=[]; thumbAx.YTick=[];
        thumbAx.Color='black'; thumbAx.XColor='none'; thumbAx.YColor='none';
        thumbAx.Toolbar.Visible='off'; thumbAx.Visible='off';
        predLabel = uilabel(snapFig,'Text','', ...
            'Interpreter','html', ...
            'FontSize',min(28,floor(figW/30)),'FontWeight','bold', ...
            'FontColor','yellow','HorizontalAlignment','center', ...
            'Position',[0 pad figW predLabelH]);

        for p = 1:cfg.numPhotos
            try
                thumbAx.Visible='off'; predLabel.Text='';
                countSec = (p==1)*cfg.countdownBefore + (p>1)*cfg.delayBetween;
                for w = countSec:-1:1
                    if p==1
                        statusLabel.Text = ehtmlf('&#x1F3AF;','Photo %d of %d &mdash; %d',p,cfg.numPhotos,w);
                    else
                        statusLabel.Text = ehtmlf('','Next photo in %d...',w);
                    end
                    try
                        liveImg = sai_takePhoto(cam);
                        image(cameraAx,liveImg); cameraAx.XTick=[]; cameraAx.YTick=[];
                        axis(cameraAx,'image');
                    catch, end
                    drawnow; pause(1);
                end

                statusLabel.Text = ehtmlf('&#x1F4F8;','SNAP!  Photo %d of %d',p,cfg.numPhotos);
                drawnow;
                img = sai_takePhoto(cam);
                photos{p} = img;
                image(cameraAx,img); cameraAx.XTick=[]; cameraAx.YTick=[];
                axis(cameraAx,'image'); drawnow;

                imResized = imresize(img, inputSize);
                [lbl, scr] = classify(net, imResized);
                pEmoji(p) = string(sai_lookupEmoji(lbl, emojiMap));
                pName(p)  = string(sai_cleanLabel(lbl));
                pConf(p)  = string(sai_confidenceText(max(scr)));

                statusLabel.Text = ehtmlf('','Photo %d of %d &mdash; Result:',p,cfg.numPhotos);
                thumbAx.Visible='on';
                image(thumbAx,img); thumbAx.XTick=[]; thumbAx.YTick=[];
                axis(thumbAx,'image');
                predLabel.Text = ehtmlPred(pEmoji(p), pName(p), pConf(p));
                drawnow; pause(2);
            catch
                photos{p} = uint8(128*ones(224,224,3));
                pEmoji(p)="?"; pName(p)="Camera Error"; pConf(p)="";
            end
        end
        delete(snapFig);

        % ---- RESULTS GALLERY ----
        donePressed = false;
        feedback = zeros(1, cfg.numPhotos);

        resFig = uifigure('Name','Results','Color','white','WindowState','maximized');
        [figW, figH] = waitForMaximize(resFig);
        margin=12; titleH=55; bottomH=65; gapV=6;
        availH = figH-titleH-bottomH-2*margin;
        rowH = min(floor((availH-(cfg.numPhotos-1)*gapV)/cfg.numPhotos), 140);
        imgSize = rowH-4;
        thumbBtnW = max(44,min(70,floor(rowH*0.65)));
        thumbBtnGap = 8;
        labelFS = max(12,min(20,floor(rowH*0.20)));
        thumbFS = max(16,min(28,floor(thumbBtnW*0.45)));

        uilabel(resFig, ...
            'Text','<html><body style="text-align:center;font-weight:bold;">&#x1F3C6; Was the Computer Right? Tap &#x1F44D; or &#x1F44E; !</body></html>', ...
            'Interpreter','html', ...
            'FontSize',min(28,floor(figW/30)),'FontWeight','bold', ...
            'HorizontalAlignment','center','Position',[0 figH-titleH-margin figW titleH]);

        for p = 1:cfg.numPhotos
            y = figH-titleH-margin-margin-p*(rowH+gapV)+gapV;
            thumbFile = fullfile(tempdir, sprintf('snap_thumb_%d.png',p));
            imwrite(imresize(photos{p},[imgSize imgSize]), thumbFile);
            uiimage(resFig,'ImageSource',thumbFile,'Position',[margin y imgSize imgSize],'ScaleMethod','fit');

            labelX = margin+imgSize+12;
            btnAreaW = 2*thumbBtnW+thumbBtnGap+margin;
            labelW = figW-labelX-btnAreaW;
            uilabel(resFig, ...
                'Text',ehtmlPred(pEmoji(p), pName(p), pConf(p)), ...
                'Interpreter','html', ...
                'FontSize',labelFS,'FontWeight','bold','VerticalAlignment','center', ...
                'WordWrap','on','Position',[labelX y labelW rowH]);

            thumbUpX = figW-btnAreaW;
            btnY = y+(rowH-thumbBtnW)/2;
            upBtn = uibutton(resFig,'push','Text','👍','FontSize',thumbFS, ...
                'BackgroundColor',[0.85 0.95 0.85],'Position',[thumbUpX btnY thumbBtnW thumbBtnW]);
            dnBtn = uibutton(resFig,'push','Text','👎','FontSize',thumbFS, ...
                'BackgroundColor',[0.95 0.85 0.85],'Position',[thumbUpX+thumbBtnW+thumbBtnGap btnY thumbBtnW thumbBtnW]);
            upBtn.ButtonPushedFcn = @(btn,~) onFeedback(btn, p, 1);
            dnBtn.ButtonPushedFcn = @(btn,~) onFeedback(btn, p, -1);
        end

        doneW=min(180,figW*0.22); doneBtnH=bottomH-2*margin;
        scoreLbl = uilabel(resFig, ...
            'Text','<html><body>Tap &#x1F44D; or &#x1F44E; for each, then DONE!</body></html>', ...
            'Interpreter','html', ...
            'FontSize',min(16,floor(figW/55)),'FontColor',[0.4 0.4 0.4], ...
            'HorizontalAlignment','center','VerticalAlignment','center', ...
            'WordWrap','on', ...
            'Position',[margin margin figW-doneW-3*margin doneBtnH]);
        uibutton(resFig,'push','Text','DONE!','FontSize',min(22,floor(doneBtnH*0.5)), ...
            'FontWeight','bold','BackgroundColor',[0.2 0.7 0.9],'FontColor','white', ...
            'Position',[figW-doneW-margin margin doneW doneBtnH], ...
            'ButtonPushedFcn',@(~,~) onDonePressed());

        tic;
        while ~donePressed
            if ~isvalid(resFig), break; end
            if toc > cfg.resetTimeout, break; end
            nC=sum(feedback==1); nR=sum(feedback~=0);
            if nR>0
                scoreLbl.Text = sprintf('<html><body>Score so far: %d out of %d right!</body></html>',nC,nR);
            end
            pause(0.3); drawnow;
        end

        % ---- SCORE SUMMARY ----
        if isvalid(resFig)
            numCorrect=sum(feedback==1); numTotal=sum(feedback~=0);
            delete(resFig);
            scoreFig = uifigure('Name','Final Score!','Color',[0.18 0.55 0.78],'WindowState','maximized');
            [figW,figH] = waitForMaximize(scoreFig);
            if numTotal==0
                scoreHtml = '<html><body style="text-align:center;"><span style="font-size:60px;">&#x1F916;</span><br/><br/>Thanks for playing!</body></html>';
            elseif numCorrect==numTotal
                scoreHtml = sprintf('<html><body style="text-align:center;"><span style="font-size:60px;">&#x1F389;</span><br/><br/>PERFECT SCORE!<br/>The computer got ALL %d right!</body></html>',numTotal);
            elseif numCorrect>numTotal/2
                scoreHtml = sprintf('<html><body style="text-align:center;"><span style="font-size:60px;">&#x1F31F;</span><br/><br/>Nice!<br/>The computer got %d out of %d right!</body></html>',numCorrect,numTotal);
            else
                scoreHtml = sprintf('<html><body style="text-align:center;"><span style="font-size:60px;">&#x1F914;</span><br/><br/>Tricky!<br/>The computer only got %d out of %d right.<br/>Computers still have a lot to learn!</body></html>',numCorrect,numTotal);
            end
            uilabel(scoreFig,'Text',scoreHtml, ...
                'Interpreter','html', ...
                'FontSize',min(40,floor(figW/24)), ...
                'FontWeight','bold','FontColor','white','HorizontalAlignment','center', ...
                'WordWrap','on','Position',[figW*0.05 figH*0.25 figW*0.9 figH*0.55]);
            uilabel(scoreFig, ...
                'Text','<html><body style="text-align:center;">&#x1F9E0; This computer looked at millions of pictures to learn &mdash; just like how you learn by seeing things over and over!</body></html>', ...
                'Interpreter','html', ...
                'FontSize',min(20,floor(figW/45)),'FontColor',[0.85 0.92 1.0], ...
                'HorizontalAlignment','center','WordWrap','on', ...
                'Position',[figW*0.1 figH*0.05 figW*0.8 figH*0.2]);
            pause(8);
            if isvalid(scoreFig), delete(scoreFig); end
        end

        startPressed=false; donePressed=false;
        feedback=zeros(1,cfg.numPhotos);
    end

    % ===== NESTED CALLBACK FUNCTIONS =====
    function onStartPressed()
        startPressed = true;
    end

    function onDonePressed()
        donePressed = true;
    end

    function onFeedback(btn, photoIdx, value)
        feedback(photoIdx) = value;
        if value==1, btn.BackgroundColor=[0.3 0.85 0.3];
        else, btn.BackgroundColor=[0.9 0.3 0.3]; end
    end
end

% ===== HELPER: HTML emoji + text =====
function s = ehtml(emojiCode, text)
% Wraps emoji (HTML entity) and text in HTML for uilabel rendering
    if isempty(emojiCode)
        s = sprintf('<html><body>%s</body></html>', text);
    else
        s = sprintf('<html><body><span style="font-size:1.2em;">%s</span> %s</body></html>', emojiCode, text);
    end
end

function s = ehtmlf(emojiCode, fmt, varargin)
% Like ehtml but with sprintf formatting
    text = sprintf(fmt, varargin{:});
    s = ehtml(emojiCode, text);
end

function s = ehtmlPred(emoji, name, conf)
% Format a prediction result with emoji for uilabel HTML display
    e = char(emoji); n = char(name); c = char(conf);
    s = sprintf('<html><body><span style="font-size:1.3em;">%s</span> <b>%s</b> &mdash; %s</body></html>', e, n, c);
end

function [figW, figH] = waitForMaximize(fig)
    drawnow;
    screenSz = get(0,'ScreenSize');
    deadline = tic;
    while toc(deadline) < 1.0
        pos = fig.Position;
        if pos(3)>600 || pos(4)>500
            figW=pos(3); figH=pos(4); return;
        end
        pause(0.05); drawnow;
    end
    figW=screenSz(3); figH=screenSz(4)-40;
    fig.Position=[1 1 figW figH];
end
