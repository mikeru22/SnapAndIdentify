function emojiMap = sai_buildEmotionEmojiMap()
%SAI_BUILDEMOTIONEMOJIMAP  Build FER emotion label -> emoji lookup table.
    emojiKeys = {'angry','disgust','fear','happy','sad','surprise','neutral','contempt'};
    emojiVals = {'&#x1F620;', '&#x1F922;', '&#x1F628;', '&#x1F604;', ...
                 '&#x1F622;', '&#x1F632;', '&#x1F610;', '&#x1F612;'};
    emojiMap = containers.Map(emojiKeys, emojiVals);
end
