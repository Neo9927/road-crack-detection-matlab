function [Ipad, paddingInfo] = ...
        pad_minimal_symmetric(I, windowSize, stride)
%PAD_MINIMAL_SYMMETRIC 对图像执行最小 symmetric padding。
%
% 不补成正方形。
% 高度和宽度分别补到滑窗可以完整覆盖的最小尺寸。
% 原图固定在左上角，只在右侧和下方 padding。

    I = ensureRGB(I);

    originalHeight = size(I,1);
    originalWidth = size(I,2);

    paddedHeight = aligned_sliding_length( ...
        originalHeight, windowSize, stride);

    paddedWidth = aligned_sliding_length( ...
        originalWidth, windowSize, stride);

    padBottom = paddedHeight - originalHeight;
    padRight = paddedWidth - originalWidth;

    Ipad = padarray( ...
        I, [0 padRight 0], ...
        'symmetric', 'post');

    Ipad = padarray( ...
        Ipad, [padBottom 0 0], ...
        'symmetric', 'post');

    paddingInfo = struct();
    paddingInfo.OriginalSize = ...
        [originalHeight originalWidth];
    paddingInfo.PaddedSize = ...
        [paddedHeight paddedWidth];
    paddingInfo.PadBottom = padBottom;
    paddingInfo.PadRight = padRight;
    paddingInfo.WindowSize = windowSize;
    paddingInfo.Stride = stride;
end

function I = ensureRGB(I)
    if ndims(I) == 2 || size(I,3) == 1
        I = repmat(I, [1 1 3]);
    elseif size(I,3) > 3
        I = I(:,:,1:3);
    end
end
