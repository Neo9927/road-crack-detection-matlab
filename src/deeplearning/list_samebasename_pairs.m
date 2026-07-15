function pairTable = list_samebasename_pairs(splitDir)
%LIST_SAMEBASENAME_PAIRS 配对同名的 JPG 图片和 PNG mask。
%
% 命名：
%   xxx.jpg  <->  xxx.png

    splitDir = char(splitDir);

    if ~isfolder(splitDir)
        error('Dataset folder does not exist: %s', splitDir);
    end

    imageInfo = dir(fullfile(splitDir, '*.jpg'));

    if isempty(imageInfo)
        error('No JPG images found in: %s', splitDir);
    end

    [~, order] = sort(lower(string({imageInfo.name})));
    imageInfo = imageInfo(order);

    imageFiles = fullfile(splitDir, {imageInfo.name});
    maskFiles = cell(size(imageFiles));

    for k = 1:numel(imageFiles)
        [~, baseName, ~] = fileparts(imageFiles{k});

        maskFiles{k} = fullfile( ...
            splitDir, [baseName '.png']);
    end

    missingMask = ~cellfun(@isfile, maskFiles);

    if any(missingMask)
        fprintf('Missing masks:\n');
        fprintf('  %s\n', maskFiles{missingMask});

        error(['Some JPG images do not have a same-name PNG mask. ' ...
            'Expected xxx.jpg <-> xxx.png.']);
    end

    pairTable = table( ...
        string(imageFiles(:)), ...
        string(maskFiles(:)), ...
        'VariableNames', {'ImageFile', 'MaskFile'});
end
