function [mask, scoreMap, predictionInfo] = ...
        predict_minimal_sliding_unet( ...
            I, net, threshold, ...
            windowSize, stride, blendMode)
%PREDICT_MINIMAL_SLIDING_UNET 完整的最小 padding 滑窗推理。
%
% 默认：
%   windowSize = 256
%   stride = 128
%   blendMode = "cosine"

    if nargin < 3 || isempty(threshold)
        threshold = 0.5;
    end

    if nargin < 4 || isempty(windowSize)
        windowSize = 256;
    end

    if nargin < 5 || isempty(stride)
        stride = 128;
    end

    if nargin < 6 || isempty(blendMode)
        blendMode = "cosine";
    end

    totalTimer = tic;

    [tiles, tileInfo] = ...
        extract_minimal_sliding_tiles( ...
            I, windowSize, stride);

    crackIndex = ...
        find_minimal_crack_class_index(net);

    tileScores = zeros( ...
        windowSize, windowSize, ...
        tileInfo.NumberOfTiles, 'single');

    inferenceTimer = tic;

    for tileIndex = 1:tileInfo.NumberOfTiles
        tile = im2single(tiles(:,:,:,tileIndex));

        % 第三个输出才是 H×W×类别数的全部类别 score。
        [~, ~, allScores] = semanticseg(tile, net);

        if crackIndex > size(allScores,3)
            error(['Crack index %d exceeds score channels %d.'], ...
                crackIndex, size(allScores,3));
        end

        tileScores(:,:,tileIndex) = ...
            single(allScores(:,:,crackIndex));
    end

    networkSeconds = toc(inferenceTimer);

    scoreMap = merge_minimal_tile_scores( ...
        tileScores, tileInfo, blendMode);

    mask = scoreMap >= threshold;

    totalSeconds = toc(totalTimer);

    predictionInfo = tileInfo;
    predictionInfo.NetworkSeconds = networkSeconds;
    predictionInfo.TotalSeconds = totalSeconds;
    predictionInfo.BlendMode = string(blendMode);
    predictionInfo.Threshold = threshold;
end
