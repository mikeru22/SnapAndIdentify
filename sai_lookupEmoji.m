function emoji = sai_lookupEmoji(label, emojiMap)
    key = lower(char(label));
    if emojiMap.isKey(key)
        emoji = emojiMap(key);
    else
        emoji = '&#x1F914;';
    end
end
