function [predictedMask, crackProbability, info] = ...
        predictCrackEnsemble(inputImage, executionEnvironment, progressCallback)
%PREDICTCRACKENSEMBLE Run the frozen four-model crack ensemble.
%   [MASK, PROBABILITY, INFO] = predictCrackEnsemble(IMAGE, "auto")
%   returns a logical mask and crack probability map in original image size.

arguments
    inputImage
    executionEnvironment (1,1) string = "auto"
    progressCallback = []
end

persistent modelBundle
if isempty(modelBundle)
    functionFolder = fileparts(mfilename('fullpath'));
    modelPath = fullfile(functionFolder, 'models', ...
        'final_unet_ensemble.mat');
    modelBundle = load(modelPath);
end

startTime = tic;
notifyProgress(progressCallback, 0);
image = ensureRgbImage(inputImage);
config = modelBundle.ensembleConfig;

directClassNames = string(config.DirectClassNames);
resnetClassNames = string(config.ResNetClassNames);
directCrackIndex = find(directClassNames == "crack", 1);
resnetCrackIndex = find(resnetClassNames == "crack", 1);

hardProbability = predictDirectTta(image, modelBundle.hardNetwork, ...
    directClassNames, directCrackIndex, config.DirectInputSize(1:2), ...
    executionEnvironment, progressCallback, 0);
photoProbability = predictDirectTta(image, modelBundle.photoNetwork, ...
    directClassNames, directCrackIndex, config.DirectInputSize(1:2), ...
    executionEnvironment, progressCallback, 3);
transferProbability = predictDirectTta(image, ...
    modelBundle.transferNetwork, directClassNames, directCrackIndex, ...
    config.DirectInputSize(1:2), executionEnvironment, progressCallback, 6);
resnetProbability = predictResNetTta(image, ...
    modelBundle.focalResNetNetwork, resnetClassNames, resnetCrackIndex, ...
    config.ResNetInputSize(1:2), executionEnvironment, progressCallback, 9);

crackProbability = config.ResNetWeight .* resnetProbability + ...
    config.HardWeight .* hardProbability + ...
    config.PhotoWeight .* photoProbability + ...
    config.TransferWeight .* transferProbability;
predictedMask = crackProbability >= config.Threshold;
if config.MinimumArea > 0
    predictedMask = bwareaopen(predictedMask, config.MinimumArea, 8);
end

info = struct;
info.ElapsedSeconds = toc(startTime);
info.Threshold = config.Threshold;
info.MinimumArea = config.MinimumArea;
info.ExecutionEnvironment = executionEnvironment;
info.PerModelProbabilities = struct( ...
    'ResNet', resnetProbability, ...
    'HardRS', hardProbability, ...
    'Photometric', photoProbability, ...
    'Transfer', transferProbability);
end

function meanProbability = predictDirectTta(image, network, classNames, ...
        crackIndex, targetSize, executionEnvironment, progressCallback, stepOffset)
views = {image, flip(image, 2), flip(image, 1)};
probabilitySum = zeros(size(image, 1), size(image, 2));
for viewIndex = 1:3
    networkInput = imresize(views{viewIndex}, targetSize, 'bilinear');
    [~, ~, scores] = semanticseg(networkInput, network, ...
        Classes=classNames, ExecutionEnvironment=executionEnvironment);
    scores = moveToCPU(scores);
    probability = imresize(double(scores(:, :, crackIndex)), ...
        size(image, [1 2]), 'nearest');
    probability = undoView(probability, viewIndex);
    probabilitySum = probabilitySum + probability;
    notifyProgress(progressCallback, (stepOffset + viewIndex) / 12);
end
meanProbability = probabilitySum / 3;
end

function meanProbability = predictResNetTta(image, network, classNames, ...
        crackIndex, targetSize, executionEnvironment, progressCallback, stepOffset)
views = {image, flip(image, 2), flip(image, 1)};
probabilitySum = zeros(size(image, 1), size(image, 2));
for viewIndex = 1:3
    [networkInput, geometry] = prepareCalibratedInput( ...
        views{viewIndex}, targetSize);
    [~, ~, scores] = semanticseg(networkInput, network, ...
        Classes=classNames, ExecutionEnvironment=executionEnvironment);
    scores = moveToCPU(scores);
    probability = restoreCalibratedProbability( ...
        double(scores(:, :, crackIndex)), geometry, size(image, [1 2]));
    probability = undoView(probability, viewIndex);
    probabilitySum = probabilitySum + probability;
    notifyProgress(progressCallback, (stepOffset + viewIndex) / 12);
end
meanProbability = probabilitySum / 3;
end

function notifyProgress(progressCallback, fraction)
if ~isempty(progressCallback)
    progressCallback(fraction);
end
end

function probability = undoView(probability, viewIndex)
if viewIndex == 2
    probability = flip(probability, 2);
elseif viewIndex == 3
    probability = flip(probability, 1);
end
end

function [networkInput, geometry] = prepareCalibratedInput(image, targetSize)
geometry.RotationApplied = size(image, 1) > size(image, 2);
if geometry.RotationApplied
    workingImage = rot90(image, -1);
else
    workingImage = image;
end
geometry.RotatedSize = size(workingImage, [1 2]);
scale = min(targetSize(1) / geometry.RotatedSize(1), ...
    targetSize(2) / geometry.RotatedSize(2));
geometry.ResizedHeight = min(targetSize(1), ...
    max(1, round(geometry.RotatedSize(1) * scale)));
geometry.ResizedWidth = min(targetSize(2), ...
    max(1, round(geometry.RotatedSize(2) * scale)));
geometry.PadTop = floor((targetSize(1) - geometry.ResizedHeight) / 2);
geometry.PadLeft = floor((targetSize(2) - geometry.ResizedWidth) / 2);
resizedImage = imresize(workingImage, ...
    [geometry.ResizedHeight geometry.ResizedWidth], 'bilinear');
networkInput = zeros(targetSize(1), targetSize(2), 3, ...
    'like', resizedImage);
for channel = 1:3
    networkInput(:, :, channel) = cast(mean( ...
        double(resizedImage(:, :, channel)), 'all'), class(resizedImage));
end
rows = geometry.PadTop + (1:geometry.ResizedHeight);
columns = geometry.PadLeft + (1:geometry.ResizedWidth);
networkInput(rows, columns, :) = resizedImage;
end

function originalProbability = restoreCalibratedProbability( ...
        calibratedProbability, geometry, originalSize)
rows = geometry.PadTop + (1:geometry.ResizedHeight);
columns = geometry.PadLeft + (1:geometry.ResizedWidth);
croppedProbability = calibratedProbability(rows, columns);
rotatedProbability = imresize(croppedProbability, ...
    geometry.RotatedSize, 'bilinear');
if geometry.RotationApplied
    originalProbability = rot90(rotatedProbability, 1);
else
    originalProbability = rotatedProbability;
end
originalProbability = originalProbability(1:originalSize(1), ...
    1:originalSize(2));
end

function image = ensureRgbImage(inputImage)
if ischar(inputImage) || (isstring(inputImage) && isscalar(inputImage))
    inputImage = imread(inputImage);
end
if ndims(inputImage) == 2 || size(inputImage, 3) == 1
    image = repmat(inputImage(:, :, 1), [1 1 3]);
else
    image = inputImage(:, :, 1:3);
end
end

function value = moveToCPU(value)
if isa(value, 'gpuArray')
    value = gather(value);
end
end
