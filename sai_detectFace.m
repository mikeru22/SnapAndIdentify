function [faceCrop, bbox, found] = sai_detectFace(img)
%SAI_DETECTFACE  Detect and crop the largest face in an image.
%   Uses vision.CascadeObjectDetector with a persistent detector for speed.
%   Returns the cropped face, bounding box [x y w h], and found flag.

    persistent detector
    if isempty(detector)
        detector = vision.CascadeObjectDetector();
    end

    bboxes = step(detector, img);

    if isempty(bboxes)
        faceCrop = [];
        bbox = [];
        found = false;
        return;
    end

    % Select largest face by area
    areas = bboxes(:,3) .* bboxes(:,4);
    [~, idx] = max(areas);
    bbox = bboxes(idx, :);

    % Skip faces that are too small
    if bbox(3) < 20 || bbox(4) < 20
        faceCrop = [];
        bbox = [];
        found = false;
        return;
    end

    faceCrop = imcrop(img, bbox);
    found = true;
end
