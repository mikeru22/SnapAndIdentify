function displayName = sai_emotionDisplayName(modelLabel)
%SAI_EMOTIONDISPLAYNAME  Map emotion model labels to kid-friendly display names.
    persistent nameMap
    if isempty(nameMap)
        nameMap = containers.Map('KeyType','char','ValueType','char');
        nameMap('neutral') = 'Calm';
    end
    key = lower(strtrim(char(modelLabel)));
    if nameMap.isKey(key)
        displayName = nameMap(key);
    else
        displayName = sai_cleanLabel(modelLabel);
    end
end
