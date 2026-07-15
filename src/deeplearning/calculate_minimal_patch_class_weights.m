function [classWeights, weightTable] = ...
        calculate_minimal_patch_class_weights( ...
            maskDs, validDs, weightMode, maxCrackWeight)
%CALCULATE_MINIMAL_PATCH_CLASS_WEIGHTS 只统计有效原图像素。

    numberOfPatches = numel(maskDs.Files);

    backgroundPixels = 0;
    crackPixels = 0;

    fprintf('\nCounting valid patch pixels...\n');

    for k = 1:numberOfPatches
        M = readimage(maskDs,k);
        V = readimage(validDs,k);

        if ndims(M) == 3
            M = M(:,:,1);
        end

        if ndims(V) == 3
            V = V(:,:,1);
        end

        crackMask = M > 0;
        validMask = V > 0;

        crackPixels = crackPixels + ...
            nnz(crackMask & validMask);

        backgroundPixels = backgroundPixels + ...
            nnz(~crackMask & validMask);

        fprintf('Class counting %d / %d\r', ...
            k, numberOfPatches);
    end

    fprintf('\n');

    pixelCount = [backgroundPixels; crackPixels];
    frequency = pixelCount / sum(pixelCount);

    switch lower(string(weightMode))
        case "sqrt_capped"
            classWeights = sqrt( ...
                median(frequency) ./ frequency);

            classWeights = ...
                classWeights ./ min(classWeights);

            classWeights(2) = min( ...
                classWeights(2), maxCrackWeight);

        case "fixed5percent"
            classWeights = [1; 19];

        case "none"
            classWeights = [1; 1];

        otherwise
            error('Unknown weightMode: %s', ...
                char(weightMode));
    end

    classColumn = categorical( ...
        ["background"; "crack"]);

    weightTable = table( ...
        classColumn, ...
        pixelCount, ...
        frequency, ...
        classWeights, ...
        'VariableNames', { ...
            'Class', 'PixelCount', ...
            'Frequency', 'Weight'});

    fprintf('\nValid-pixel class distribution:\n');
    disp(weightTable);
end
