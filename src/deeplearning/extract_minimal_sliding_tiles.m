function [tiles, tileInfo] = ...
        extract_minimal_sliding_tiles( ...
            I, windowSize, stride)
%EXTRACT_MINIMAL_SLIDING_TILES 最小 padding 后提取全部滑窗。
%
% 不缩放，不补成正方形。
% 只在右侧和下方做 symmetric padding。

    [Ipad, padInfo] = ...
        pad_minimal_symmetric( ...
            I, windowSize, stride);

    rowStarts = 1:stride: ...
        (padInfo.PaddedSize(1) - windowSize + 1);

    colStarts = 1:stride: ...
        (padInfo.PaddedSize(2) - windowSize + 1);

    numberOfTiles = ...
        numel(rowStarts) * numel(colStarts);

    tiles = zeros( ...
        windowSize, windowSize, 3, numberOfTiles, ...
        'like', Ipad);

    tileLocations = zeros(numberOfTiles,2);

    tileIndex = 0;

    for r = 1:numel(rowStarts)
        for c = 1:numel(colStarts)
            tileIndex = tileIndex + 1;

            rowStart = rowStarts(r);
            colStart = colStarts(c);

            rr = rowStart:(rowStart + windowSize - 1);
            cc = colStart:(colStart + windowSize - 1);

            tiles(:,:,:,tileIndex) = Ipad(rr,cc,:);
            tileLocations(tileIndex,:) = ...
                [rowStart colStart];
        end
    end

    tileInfo = padInfo;
    tileInfo.RowStarts = rowStarts;
    tileInfo.ColStarts = colStarts;
    tileInfo.TileLocations = tileLocations;
    tileInfo.NumberOfTiles = numberOfTiles;
end
