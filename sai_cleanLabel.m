function cleanName = sai_cleanLabel(label)
    name = char(label);
    name = strrep(name, '_', ' ');
    words = strsplit(name);
    for i = 1:numel(words)
        w = words{i};
        if strlength(w) > 0
            words{i} = [upper(w(1)) w(2:end)];
        end
    end
    cleanName = strjoin(words, ' ');
end
