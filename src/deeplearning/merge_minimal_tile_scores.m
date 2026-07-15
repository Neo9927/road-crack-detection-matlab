function scoreMap = ...
        merge_minimal_tile_scores( ...
            tileScores, tileInfo, blendMode)
%MERGE_MINIMAL_TILE_SCORES 融合 score 后裁剪回原图。
%
% 必须先融合连续 score，再统一 threshold。

    windowSize = tileInfo.WindowSize;

    if size(tileScores,1) ~= windowSize || ...
            size(tileScores,2) ~= windowSize || ...
            size(tileScores,3) ~= tileInfo.NumberOfTiles
        error('tileScores dimensions do not match tileInfo.');
    end

    tileWeight = ...
        make_blending_weight(windowSize, blendMode);

    scoreSum = zeros( ...
        tileInfo.PaddedSize, 'single');

    weightSum = zeros( ...
        tileInfo.PaddedSize, 'single');

    for tileIndex = 1:tileInfo.NumberOfTiles
        rowStart = tileInfo.TileLocations(tileIndex,1);
        colStart = tileInfo.TileLocations(tileIndex,2);

        rr = rowStart:(rowStart + windowSize - 1);
        cc = colStart:(colStart + windowSize - 1);

        scoreSum(rr,cc) = ...
            scoreSum(rr,cc) + ...
            single(tileScores(:,:,tileIndex)) .* tileWeight;

        weightSum(rr,cc) = ...
            weightSum(rr,cc) + tileWeight;
    end

    paddedScore = ...
        scoreSum ./ max(weightSum,eps('single'));

    originalHeight = tileInfo.OriginalSize(1);
    originalWidth = tileInfo.OriginalSize(2);

    scoreMap = paddedScore( ...
        1:originalHeight, ...
        1:originalWidth);
end
