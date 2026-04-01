function confText = sai_confidenceText(score)
    if score >= 0.80
        confText = 'Super Sure! &#x2B50;';
    elseif score >= 0.50
        confText = 'Pretty Sure!';
    elseif score >= 0.25
        confText = 'Hmm, Maybe...';
    else
        confText = 'Just Guessing! &#x1F937;';
    end
end
