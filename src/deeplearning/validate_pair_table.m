function reportTable = validate_pair_table(pairTable)
%VALIDATE_PAIR_TABLE 检查每张 JPG 和同名 PNG 是否尺寸一致。
%
% 不要求不同图片之间具有相同分辨率。

    numberOfPairs = height(pairTable);

    imageHeight = zeros(numberOfPairs, 1);
    imageWidth = zeros(numberOfPairs, 1);
    maskHeight = zeros(numberOfPairs, 1);
    maskWidth = zeros(numberOfPairs, 1);
    imageMaskMatch = false(numberOfPairs, 1);

    for k = 1:numberOfPairs
        imageInfo = imfinfo(char(pairTable.ImageFile(k)));
        maskInfo = imfinfo(char(pairTable.MaskFile(k)));

        imageHeight(k) = imageInfo.Height;
        imageWidth(k) = imageInfo.Width;
        maskHeight(k) = maskInfo.Height;
        maskWidth(k) = maskInfo.Width;

        imageMaskMatch(k) = ...
            imageHeight(k) == maskHeight(k) && ...
            imageWidth(k) == maskWidth(k);
    end

    reportTable = table( ...
        pairTable.ImageFile, ...
        imageHeight, imageWidth, ...
        maskHeight, maskWidth, ...
        imageMaskMatch, ...
        'VariableNames', { ...
            'ImageFile', ...
            'ImageHeight', 'ImageWidth', ...
            'MaskHeight', 'MaskWidth', ...
            'ImageMaskMatch'});

    if any(~imageMaskMatch)
        fprintf('\nImage-mask size mismatch:\n');
        disp(reportTable(~imageMaskMatch, :));

        error('Some JPG-PNG pairs have different dimensions.');
    end

    sizeTable = table(imageHeight, imageWidth);

    [uniqueSizes, ~, groupIndex] = ...
        unique(sizeTable, 'rows');

    counts = accumarray(groupIndex, 1);

    resolutionSummary = table( ...
        uniqueSizes.imageHeight, ...
        uniqueSizes.imageWidth, ...
        counts, ...
        'VariableNames', {'Height', 'Width', 'Count'});

    fprintf('\nDetected source resolutions:\n');
    disp(resolutionSummary);
end
