function [emoji, label, confText, found] = sai_classifyEmotion(img, emotionNet, emotionInputSize, emotionEmojiMap)
%SAI_CLASSIFYEMOTION  Detect a face and classify its emotion.
%   Returns emoji, cleaned label, confidence text, and found flag.
%   Output shape matches the object ID pipeline for seamless integration.

    [faceCrop, ~, found] = sai_detectFace(img);

    if ~found
        emoji = '&#x1F645;';  % person gesturing NO
        label = 'No Face Found';
        confText = 'Try again!';
        return;
    end

    dlInput = sai_preprocessFace(faceCrop, emotionInputSize);
    scores = predict(emotionNet, dlInput);
    scores = extractdata(scores);

    % Apply softmax if scores are not already probabilities
    if any(scores < 0) || sum(scores) < 0.99 || sum(scores) > 1.01
        scores = exp(scores) ./ sum(exp(scores));
    end

    scores = scores(:)';  % ensure row vector
    [maxScore, idx] = max(scores);

    emotionLabels = sai_emotionLabels();
    emotionName = emotionLabels{idx};

    emoji = sai_lookupEmoji(emotionName, emotionEmojiMap);
    label = sai_cleanLabel(emotionName);
    confText = sai_confidenceText(maxScore);
end
