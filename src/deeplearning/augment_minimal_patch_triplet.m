function output = augment_minimal_patch_triplet(data)
%AUGMENT_MINIMAL_PATCH_TRIPLET 同步增强 image、mask 和 valid 区域。

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

    if rand() > 0.5
        I = fliplr(I);
        M = fliplr(M);
        V = fliplr(V);
    end

    if rand() > 0.75
        I = flipud(I);
        M = flipud(M);
        V = flipud(V);
    end

    I = im2single(I);

    % 轻微光照增强，只影响 RGB 图像。
    gain = 0.90 + 0.20 * rand();
    bias = -0.04 + 0.08 * rand();
    gammaValue = 0.90 + 0.20 * rand();

    I = I * gain + bias;
    I = min(max(I,0),1);
    I = I .^ gammaValue;

    crackMask = M > 0;
    validMask = V > 0;

    labelData = nan(size(crackMask));
    labelData(validMask & ~crackMask) = 0;
    labelData(validMask & crackMask) = 1;

    L = categorical( ...
        labelData, ...
        [0 1], ...
        {'background','crack'});

    output = {I, L};
end
