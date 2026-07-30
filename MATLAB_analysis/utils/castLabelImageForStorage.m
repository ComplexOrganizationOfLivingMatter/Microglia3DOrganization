function outputImage = castLabelImageForStorage(labelImage)
%CASTLABELIMAGEFORSTORAGE Cast a non-negative label image to uint8 or uint16.
%
% Label images with a maximum label of 254 or less are stored as uint8.
% Images requiring labels above 254 are stored as uint16. Zero remains the
% background value in both cases.

    if isempty(labelImage)
        outputImage = uint8(labelImage);
        return;
    end

    if any(labelImage(:) < 0) || any(~isfinite(double(labelImage(:))))
        error('Label images must contain finite, non-negative values.');
    end

    maxLabel = double(max(labelImage(:)));
    if maxLabel <= 254
        outputImage = uint8(labelImage);
    elseif maxLabel <= double(intmax('uint16'))
        outputImage = uint16(labelImage);
    else
        error('Label image contains values above the uint16 range. Maximum label: %.0f.', maxLabel);
    end
end
