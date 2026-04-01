function dlInput = sai_preprocessFace(faceCrop, inputSize)
%SAI_PREPROCESSFACE  Preprocess a face crop for the emotion network.
%   Converts to grayscale, resizes, normalizes to [0,1], wraps in dlarray.

    if size(faceCrop, 3) == 3
        faceGray = rgb2gray(faceCrop);
    else
        faceGray = faceCrop;
    end

    faceResized = imresize(faceGray, inputSize);
    faceNorm = single(faceResized);  % FER+ expects [0,255] float, not [0,1]
    dlInput = dlarray(faceNorm, 'SSCB');
end
