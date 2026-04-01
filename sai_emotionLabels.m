function labels = sai_emotionLabels()
%SAI_EMOTIONLABELS  Ordered emotion class names matching FER+ network output.
%   The order matches the output indices of the emotion-ferplus ONNX model.
    labels = {'neutral','happy','surprise','sad','angry','disgust','fear','contempt'};
end
