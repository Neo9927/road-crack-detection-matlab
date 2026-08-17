function results = compare_adaptive_vs_whole_large_images( ...
        datasetFolder, outputFolder, executionEnvironment)
%COMPARE_ADAPTIVE_VS_WHOLE_LARGE_IMAGES Compare two inference geometries.

arguments
    datasetFolder (1,1) string
    outputFolder (1,1) string
    executionEnvironment (1,1) string = "auto"
end

if ~isfolder(datasetFolder)
    error('CrackVision:DatasetMissing', ...
        'Dataset folder does not exist: %s', datasetFolder);
end
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

sampleNames = ["20160222_080933", "20160222_081839", "20160222_114759"];
rowCount = numel(sampleNames);
results = table('Size', [rowCount 17], ...
    'VariableTypes', ["string", repmat("double", 1, 15), "string"], ...
    'VariableNames', ["Image", "Height", "Width", "TileCount", ...
    "WholePrecision", "WholeRecall", "WholeF1", "WholeIoU", ...
    "AdaptivePrecision", "AdaptiveRecall", "AdaptiveF1", "AdaptiveIoU", ...
    "F1Delta", "IoUDelta", "WholeSeconds", "AdaptiveSeconds", ...
    "AdaptiveMode"]);

fprintf('Adaptive inference comparison starting: %d large images\n', rowCount);
for sampleIndex = 1:rowCount
    sampleName = sampleNames(sampleIndex);
    imagePath = fullfile(datasetFolder, sampleName + ".jpg");
    maskPath = fullfile(datasetFolder, sampleName + "_mask.png");
    image = imread(imagePath);
    groundTruth = readComparisonMask(maskPath, size(image, [1 2]));

    fprintf('[%d/%d] %s | %dx%d\n', sampleIndex, rowCount, ...
        sampleName, size(image, 1), size(image, 2));
    [wholeMask, ~, wholeInfo] = predictCrackEnsemble( ...
        image, executionEnvironment);
    wholeMetrics = computeComparisonMetrics(wholeMask, groundTruth);
    wholeSeconds = wholeInfo.ElapsedSeconds;
    clear wholeInfo

    progressCallback = @(fraction) fprintfProgress( ...
        sampleIndex, rowCount, fraction);
    [adaptiveMask, ~, adaptiveInfo] = predictCrackEnsembleAdaptive( ...
        image, executionEnvironment, progressCallback);
    adaptiveMetrics = computeComparisonMetrics(adaptiveMask, groundTruth);

    results.Image(sampleIndex) = sampleName;
    results.Height(sampleIndex) = size(image, 1);
    results.Width(sampleIndex) = size(image, 2);
    results.TileCount(sampleIndex) = adaptiveInfo.TileCount;
    results.WholePrecision(sampleIndex) = wholeMetrics.Precision;
    results.WholeRecall(sampleIndex) = wholeMetrics.Recall;
    results.WholeF1(sampleIndex) = wholeMetrics.F1;
    results.WholeIoU(sampleIndex) = wholeMetrics.IoU;
    results.AdaptivePrecision(sampleIndex) = adaptiveMetrics.Precision;
    results.AdaptiveRecall(sampleIndex) = adaptiveMetrics.Recall;
    results.AdaptiveF1(sampleIndex) = adaptiveMetrics.F1;
    results.AdaptiveIoU(sampleIndex) = adaptiveMetrics.IoU;
    results.F1Delta(sampleIndex) = adaptiveMetrics.F1 - wholeMetrics.F1;
    results.IoUDelta(sampleIndex) = adaptiveMetrics.IoU - wholeMetrics.IoU;
    results.WholeSeconds(sampleIndex) = wholeSeconds;
    results.AdaptiveSeconds(sampleIndex) = adaptiveInfo.ElapsedSeconds;
    results.AdaptiveMode(sampleIndex) = adaptiveInfo.InferenceMode;

    saveComparisonFigure(image, groundTruth, wholeMask, adaptiveMask, ...
        wholeMetrics, adaptiveMetrics, fullfile(outputFolder, ...
        sampleName + "_whole_vs_adaptive.png"));
    fprintf('\n  Whole F1 %.4f | Adaptive F1 %.4f | delta %+.4f | tiles %d\n', ...
        wholeMetrics.F1, adaptiveMetrics.F1, results.F1Delta(sampleIndex), ...
        adaptiveInfo.TileCount);
    clear adaptiveInfo
end

writetable(results, fullfile(outputFolder, ...
    'adaptive_vs_whole_large_image_metrics.csv'));
summary = table(mean(results.WholePrecision), mean(results.WholeRecall), ...
    mean(results.WholeF1), mean(results.WholeIoU), ...
    mean(results.AdaptivePrecision), mean(results.AdaptiveRecall), ...
    mean(results.AdaptiveF1), mean(results.AdaptiveIoU), ...
    mean(results.F1Delta), mean(results.IoUDelta), ...
    mean(results.WholeSeconds), mean(results.AdaptiveSeconds), ...
    'VariableNames', ["WholePrecision", "WholeRecall", "WholeF1", "WholeIoU", ...
    "AdaptivePrecision", "AdaptiveRecall", "AdaptiveF1", "AdaptiveIoU", ...
    "F1Delta", "IoUDelta", "WholeSeconds", "AdaptiveSeconds"]);
writetable(summary, fullfile(outputFolder, ...
    'adaptive_vs_whole_large_image_summary.csv'));
disp(results);
disp(summary);
end

function groundTruth = readComparisonMask(maskPath, targetSize)
groundTruth = imread(maskPath);
if ndims(groundTruth) == 3
    groundTruth = rgb2gray(groundTruth);
end
groundTruth = groundTruth > 0;
if ~isequal(size(groundTruth), targetSize)
    groundTruth = imresize(groundTruth, targetSize, 'nearest');
end
end

function metrics = computeComparisonMetrics(prediction, groundTruth)
prediction = logical(prediction);
groundTruth = logical(groundTruth);
truePositive = nnz(prediction & groundTruth);
falsePositive = nnz(prediction & ~groundTruth);
falseNegative = nnz(~prediction & groundTruth);
metrics.Precision = truePositive / max(truePositive + falsePositive, 1);
metrics.Recall = truePositive / max(truePositive + falseNegative, 1);
metrics.F1 = 2 * truePositive / max(2 * truePositive + ...
    falsePositive + falseNegative, 1);
metrics.IoU = truePositive / max(truePositive + ...
    falsePositive + falseNegative, 1);
end

function saveComparisonFigure(image, groundTruth, wholeMask, adaptiveMask, ...
        wholeMetrics, adaptiveMetrics, outputPath)
figureHandle = figure('Visible', 'off', 'Color', 'white', ...
    'Position', [100 100 1800 900]);
layout = tiledlayout(figureHandle, 2, 3, ...
    'TileSpacing', 'compact', 'Padding', 'compact');
nexttile(layout); imshow(image); title('Original');
nexttile(layout); imshow(groundTruth); title('Ground Truth');
nexttile(layout); imshow(wholeMask); title(sprintf( ...
    'Whole prediction | F1 %.3f | IoU %.3f', ...
    wholeMetrics.F1, wholeMetrics.IoU));
nexttile(layout); imshow(makeComparisonOverlay(image, groundTruth, wholeMask));
title(sprintf('Whole overlay | P %.3f | R %.3f', ...
    wholeMetrics.Precision, wholeMetrics.Recall));
nexttile(layout); imshow(adaptiveMask); title(sprintf( ...
    'Adaptive prediction | F1 %.3f | IoU %.3f', ...
    adaptiveMetrics.F1, adaptiveMetrics.IoU));
nexttile(layout); imshow(makeComparisonOverlay( ...
    image, groundTruth, adaptiveMask));
title(sprintf('Adaptive overlay | P %.3f | R %.3f', ...
    adaptiveMetrics.Precision, adaptiveMetrics.Recall));
exportgraphics(figureHandle, outputPath, 'Resolution', 160);
close(figureHandle);
end

function overlay = makeComparisonOverlay(image, groundTruth, prediction)
base = im2double(image);
if ismatrix(base) || size(base, 3) == 1
    base = repmat(base(:, :, 1), [1 1 3]);
else
    base = base(:, :, 1:3);
end
truePositive = prediction & groundTruth;
falsePositive = prediction & ~groundTruth;
falseNegative = ~prediction & groundTruth;
colours = zeros(size(base));
colours(:, :, 1) = falsePositive | falseNegative;
colours(:, :, 2) = truePositive;
colours(:, :, 3) = falseNegative;
active = truePositive | falsePositive | falseNegative;
alpha = 0.68;
overlay = base;
for channel = 1:3
    current = overlay(:, :, channel);
    colour = colours(:, :, channel);
    current(active) = (1 - alpha) .* current(active) + ...
        alpha .* colour(active);
    overlay(:, :, channel) = current;
end
end

function fprintfProgress(sampleIndex, sampleCount, fraction)
persistent lastPercent
percent = floor(100 * fraction);
if isempty(lastPercent) || percent == 100 || percent >= lastPercent + 10
    fprintf('  image %d/%d adaptive %d%%\n', ...
        sampleIndex, sampleCount, percent);
    lastPercent = percent;
end
if percent == 100
    lastPercent = [];
end
end
