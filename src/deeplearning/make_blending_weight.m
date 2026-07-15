function weight = make_blending_weight(windowSize, blendMode)
%MAKE_BLENDING_WEIGHT 生成重叠窗口融合权重。

    switch lower(string(blendMode))
        case "uniform"
            weight = ones( ...
                windowSize, windowSize, 'single');

        case "cosine"
            coordinate = single(0:(windowSize-1));

            oneDimensional = ...
                0.5 - 0.5*cos( ...
                    2*pi*coordinate/(windowSize-1));

            % 防止图像外边界处权重严格为 0。
            edgeFloor = single(0.05);

            oneDimensional = ...
                edgeFloor + ...
                (1-edgeFloor)*oneDimensional;

            weight = ...
                oneDimensional' * oneDimensional;

        otherwise
            error('blendMode must be "cosine" or "uniform".');
    end
end
