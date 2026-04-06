function detector = sai_loadDetector(detectorName)
%SAI_LOADDETECTOR  Load a pretrained object detector by name.
%   detector = sai_loadDetector(detectorName) returns a YOLO object
%   detector ready for use with the detect() function.

    switch lower(detectorName)
        case 'tiny-yolov4-coco'
            detector = yolov4ObjectDetector('tiny-yolov4-coco');
        case 'yolov4-coco'
            detector = yolov4ObjectDetector('csp-darknet53-coco');
        otherwise
            error('sai_loadDetector:Unknown', 'Unknown detector: %s', detectorName);
    end
end
