function output = preprocess_minimal_patch_triplet(data)
%PREPROCESS_MINIMAL_PATCH_TRIPLET 将 patch 三元组转换为训练格式。
%
% data{1}: RGB patch
% data{2}: 0/255 crack mask
% data{3}: 0/255 valid mask
%
% valid=0 的位置会变为 categorical <undefined>，
% pixelClassificationLayer 在 loss 中忽略这些像素。

    I = data{1};
    M = data{2};
    V = data{3};

    if ndims(I) == 2 || size(I,3) == 1
        I = repmat(I, [1 1 3]);
    elseif size(I,3) > 3
        I = I(:,:,1:3);
    end

    if ndims(M) == 3
        M = M(:,:,1);
    end

    if ndims(V) == 3
        V = V(:,:,1);
    end

    crackMask = M > 0;
    validMask = V > 0;

    labelData = nan(size(crackMask));
    labelData(validMask & ~crackMask) = 0;
    labelData(validMask & crackMask) = 1;

    L = categorical( ...
        labelData, ...
        [0 1], ...
        {'background','crack'});

    output = {im2single(I), L};
end
