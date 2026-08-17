function [predictedMask, crackProbability, info] = ...
        predictCrackEnsembleAdaptive(inputImage, executionEnvironment, progressCallback)
%PREDICTCRACKENSEMBLEADAPTIVE Use whole-image or overlapped tiled inference.
%   Large images are divided into CRACK500-scale tiles. Probability maps are
%   blended before the frozen ensemble threshold is applied.

arguments
    inputImage
    executionEnvironment (1,1) string = "auto"
    progressCallback = []
end

image = ensureAdaptiveRgbImage(inputImage);
imageSize = size(image, [1 2]);
resNetInputSize = [320 576];
minimumWholeScale = 2 / 3;

if imageSize(1) > imageSize(2)
    workingSize = fliplr(imageSize);
else
    workingSize = imageSize;
end
scaleToResNet = min(resNetInputSize ./ workingSize);

if scaleToResNet >= minimumWholeScale
    [predictedMask, crackProbability, info] = predictCrackEnsemble( ...
        image, executionEnvironment, progressCallback);
    info.InferenceMode = "whole";
    info.ScaleToResNet = scaleToResNet;
    info.TileSize = imageSize;
    info.TileOverlap = 0;
    info.TileGrid = [1 1];
    info.TileCount = 1;
    return;
end

startTime = tic;
if imageSize(1) > imageSize(2)
    tileSize = [640 360];
else
    tileSize = [360 640];
end
overlapFraction = 0.25;
stride = max(1, round(tileSize .* (1 - overlapFraction)));
rowStarts = computeTileStarts(imageSize(1), tileSize(1), stride(1));
columnStarts = computeTileStarts(imageSize(2), tileSize(2), stride(2));
tileCount = numel(rowStarts) * numel(columnStarts);

probabilitySum = zeros(imageSize, 'single');
weightSum = zeros(imageSize, 'single');
modelSums = struct( ...
    'ResNet', zeros(imageSize, 'single'), ...
    'HardRS', zeros(imageSize, 'single'), ...
    'Photometric', zeros(imageSize, 'single'), ...
    'Transfer', zeros(imageSize, 'single'));
tileWeight = makeTileWeight(tileSize);

tileIndex = 0;
firstTileInfo = struct();
for rowIndex = 1:numel(rowStarts)
    for columnIndex = 1:numel(columnStarts)
        tileIndex = tileIndex + 1;
        rowStart = rowStarts(rowIndex);
        columnStart = columnStarts(columnIndex);
        rowEnd = min(imageSize(1), rowStart + tileSize(1) - 1);
        columnEnd = min(imageSize(2), columnStart + tileSize(2) - 1);
        validHeight = rowEnd - rowStart + 1;
        validWidth = columnEnd - columnStart + 1;

        tileImage = image(rowStart:rowEnd, columnStart:columnEnd, :);
        if validHeight < tileSize(1) || validWidth < tileSize(2)
            tileImage = padarray(tileImage, ...
                [tileSize(1) - validHeight, tileSize(2) - validWidth], ...
                'symmetric', 'post');
        end

        tileProgress = @(fraction) notifyAdaptiveProgress( ...
            progressCallback, (tileIndex - 1 + fraction) / tileCount);
        [~, tileProbability, tileInfo] = predictCrackEnsemble( ...
            tileImage, executionEnvironment, tileProgress);
        if tileIndex == 1
            firstTileInfo = tileInfo;
        end

        rows = rowStart:rowEnd;
        columns = columnStart:columnEnd;
        validWeight = tileWeight(1:validHeight, 1:validWidth);
        probabilitySum(rows, columns) = probabilitySum(rows, columns) + ...
            single(tileProbability(1:validHeight, 1:validWidth)) .* validWeight;
        weightSum(rows, columns) = weightSum(rows, columns) + validWeight;

        modelNames = fieldnames(modelSums);
        for modelIndex = 1:numel(modelNames)
            modelName = modelNames{modelIndex};
            tileModelProbability = tileInfo.PerModelProbabilities.(modelName);
            modelSums.(modelName)(rows, columns) = ...
                modelSums.(modelName)(rows, columns) + ...
                single(tileModelProbability(1:validHeight, 1:validWidth)) .* ...
                validWeight;
        end
    end
end

weightSum = max(weightSum, eps('single'));
crackProbability = probabilitySum ./ weightSum;
modelNames = fieldnames(modelSums);
for modelIndex = 1:numel(modelNames)
    modelName = modelNames{modelIndex};
    modelSums.(modelName) = modelSums.(modelName) ./ weightSum;
end

predictedMask = crackProbability >= firstTileInfo.Threshold;
if firstTileInfo.MinimumArea > 0
    predictedMask = bwareaopen( ...
        predictedMask, firstTileInfo.MinimumArea, 8);
end

info = firstTileInfo;
info.ElapsedSeconds = toc(startTime);
info.PerModelProbabilities = modelSums;
info.InferenceMode = "tiled";
info.ScaleToResNet = scaleToResNet;
info.TileSize = tileSize;
info.TileOverlap = overlapFraction;
info.TileStride = stride;
info.TileGrid = [numel(rowStarts), numel(columnStarts)];
info.TileCount = tileCount;
notifyAdaptiveProgress(progressCallback, 1);
end

function starts = computeTileStarts(imageLength, tileLength, stride)
if imageLength <= tileLength
    starts = 1;
    return;
end
lastStart = imageLength - tileLength + 1;
starts = 1:stride:lastStart;
if starts(end) ~= lastStart
    starts(end + 1) = lastStart;
end
end

function weight = makeTileWeight(tileSize)
rowWeight = sin(pi .* ((1:tileSize(1)) - 0.5) ./ tileSize(1)).^2;
columnWeight = sin(pi .* ((1:tileSize(2)) - 0.5) ./ tileSize(2)).^2;
weight = single(0.1 + 0.9 .* (rowWeight(:) * columnWeight));
end

function notifyAdaptiveProgress(progressCallback, fraction)
if ~isempty(progressCallback)
    progressCallback(min(max(fraction, 0), 1));
end
end

function image = ensureAdaptiveRgbImage(inputImage)
if ischar(inputImage) || (isstring(inputImage) && isscalar(inputImage))
    inputImage = imread(inputImage);
end
if ismatrix(inputImage) || size(inputImage, 3) == 1
    image = repmat(inputImage(:, :, 1), [1 1 3]);
else
    image = inputImage(:, :, 1:3);
end
end
