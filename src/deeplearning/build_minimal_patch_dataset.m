function metadataTable = ...
        build_minimal_patch_dataset( ...
            sourceSplitDir, outputSplitDir, config)
%BUILD_MINIMAL_PATCH_DATASET 从原图生成不缩放的滑窗训练 patches。
%
% 输出目录：
%   images/  - symmetric padded RGB patches
%   masks/   - 0/255 crack masks，padding 区域暂存为 0
%   valid/   - 0/255 有效区域；0 表示训练时应忽略
%
% 训练 transform 会将 valid=0 的标签转换成 undefined。

    config = applyDefaults(config);
    rng(config.RandomSeed, 'twister');

    sourceSplitDir = char(sourceSplitDir);
    outputSplitDir = char(outputSplitDir);

    imageOutDir = fullfile(outputSplitDir, 'images');
    maskOutDir = fullfile(outputSplitDir, 'masks');
    validOutDir = fullfile(outputSplitDir, 'valid');

    if config.Overwrite && isfolder(outputSplitDir)
        rmdir(outputSplitDir, 's');
    end

    createFolder(imageOutDir);
    createFolder(maskOutDir);
    createFolder(validOutDir);

    pairTable = list_samebasename_pairs(sourceSplitDir);
    validate_pair_table(pairTable);

    patchNameColumn = strings(0,1);
    sourceImageColumn = strings(0,1);
    rowStartColumn = zeros(0,1);
    colStartColumn = zeros(0,1);
    crackPixelsColumn = zeros(0,1);
    validPixelsColumn = zeros(0,1);
    crackRatioColumn = zeros(0,1);
    positiveColumn = false(0,1);

    outputRow = 0;

    for imageIndex = 1:height(pairTable)
        I = imread(char(pairTable.ImageFile(imageIndex)));

        Mraw = imread(char(pairTable.MaskFile(imageIndex)));
        if ndims(Mraw) == 3
            Mraw = Mraw(:,:,1);
        end

        M = Mraw > 0;

        if size(I,1) ~= size(M,1) || ...
                size(I,2) ~= size(M,2)
            error('Image-mask size mismatch: %s', ...
                pairTable.ImageFile(imageIndex));
        end

        [Ipad, padInfo] = pad_minimal_symmetric( ...
            I, config.WindowSize, config.Stride);

        Mpad = padarray( ...
            M, ...
            [padInfo.PadBottom padInfo.PadRight], ...
            false, 'post');

        validPad = padarray( ...
            true(size(M)), ...
            [padInfo.PadBottom padInfo.PadRight], ...
            false, 'post');

        rowStarts = 1:config.Stride: ...
            (padInfo.PaddedSize(1) - config.WindowSize + 1);

        colStarts = 1:config.Stride: ...
            (padInfo.PaddedSize(2) - config.WindowSize + 1);

        numberCandidates = ...
            numel(rowStarts) * numel(colStarts);

        candidateRows = zeros(numberCandidates,1);
        candidateCols = zeros(numberCandidates,1);
        candidateCrackPixels = zeros(numberCandidates,1);
        candidateValidPixels = zeros(numberCandidates,1);

        candidateIndex = 0;

        for r = 1:numel(rowStarts)
            for c = 1:numel(colStarts)
                candidateIndex = candidateIndex + 1;

                rowStart = rowStarts(r);
                colStart = colStarts(c);

                rr = rowStart:(rowStart + config.WindowSize - 1);
                cc = colStart:(colStart + config.WindowSize - 1);

                currentMask = Mpad(rr,cc);
                currentValid = validPad(rr,cc);

                candidateRows(candidateIndex) = rowStart;
                candidateCols(candidateIndex) = colStart;
                candidateCrackPixels(candidateIndex) = ...
                    nnz(currentMask & currentValid);
                candidateValidPixels(candidateIndex) = ...
                    nnz(currentValid);
            end
        end

        positiveIndices = find(candidateCrackPixels > 0);
        backgroundIndices = find(candidateCrackPixels == 0);

        if config.KeepAllPatches
            selectedIndices = (1:numberCandidates)';
        else
            numberPositive = numel(positiveIndices);

            maximumBackground = max( ...
                config.MinimumBackgroundPerImage, ...
                ceil(numberPositive * ...
                    config.NegativeToPositiveRatio));

            maximumBackground = min( ...
                maximumBackground, ...
                numel(backgroundIndices));

            if maximumBackground > 0
                sampledOrder = randperm( ...
                    numel(backgroundIndices), ...
                    maximumBackground);

                selectedBackground = ...
                    backgroundIndices(sampledOrder);
            else
                selectedBackground = zeros(0,1);
            end

            selectedIndices = sort([ ...
                positiveIndices(:); ...
                selectedBackground(:)]);
        end

        [~, sourceBaseName, ~] = ...
            fileparts(char(pairTable.ImageFile(imageIndex)));

        for selectedPosition = 1:numel(selectedIndices)
            candidate = selectedIndices(selectedPosition);

            rowStart = candidateRows(candidate);
            colStart = candidateCols(candidate);

            rr = rowStart:(rowStart + config.WindowSize - 1);
            cc = colStart:(colStart + config.WindowSize - 1);

            imagePatch = Ipad(rr,cc,:);
            maskPatch = Mpad(rr,cc);
            validPatch = validPad(rr,cc);

            patchStem = sprintf( ...
                '%s_r%05d_c%05d', ...
                sourceBaseName, rowStart, colStart);

            patchImagePath = fullfile( ...
                imageOutDir, [patchStem '.png']);

            patchMaskPath = fullfile( ...
                maskOutDir, [patchStem '.png']);

            patchValidPath = fullfile( ...
                validOutDir, [patchStem '.png']);

            imwrite(imagePatch, patchImagePath);
            imwrite(uint8(maskPatch) * 255, patchMaskPath);
            imwrite(uint8(validPatch) * 255, patchValidPath);

            outputRow = outputRow + 1;

            patchNameColumn(outputRow,1) = ...
                string([patchStem '.png']);

            sourceImageColumn(outputRow,1) = ...
                string(sourceBaseName);

            rowStartColumn(outputRow,1) = rowStart;
            colStartColumn(outputRow,1) = colStart;

            crackPixelsColumn(outputRow,1) = ...
                candidateCrackPixels(candidate);

            validPixelsColumn(outputRow,1) = ...
                candidateValidPixels(candidate);

            crackRatioColumn(outputRow,1) = ...
                candidateCrackPixels(candidate) / ...
                max(candidateValidPixels(candidate),1);

            positiveColumn(outputRow,1) = ...
                candidateCrackPixels(candidate) > 0;
        end

        fprintf('Patch generation %d / %d\r', ...
            imageIndex, height(pairTable));
    end

    fprintf('\n');

    metadataTable = table( ...
        patchNameColumn, ...
        sourceImageColumn, ...
        rowStartColumn, ...
        colStartColumn, ...
        crackPixelsColumn, ...
        validPixelsColumn, ...
        crackRatioColumn, ...
        positiveColumn, ...
        'VariableNames', { ...
            'PatchName', ...
            'SourceImage', ...
            'RowStart', ...
            'ColStart', ...
            'CrackPixels', ...
            'ValidPixels', ...
            'CrackRatio', ...
            'ContainsCrack'});

    writetable(metadataTable, ...
        fullfile(outputSplitDir, 'patch_metadata.csv'));

    fprintf('Saved patch dataset: %s\n', outputSplitDir);
    fprintf('Total selected patches: %d\n', ...
        height(metadataTable));
    fprintf('Crack-containing patches: %d\n', ...
        nnz(metadataTable.ContainsCrack));
end

function config = applyDefaults(config)
    defaults.WindowSize = 256;
    defaults.Stride = 128;
    defaults.KeepAllPatches = false;
    defaults.NegativeToPositiveRatio = 1.0;
    defaults.MinimumBackgroundPerImage = 2;
    defaults.RandomSeed = 42;
    defaults.Overwrite = false;

    names = fieldnames(defaults);

    for k = 1:numel(names)
        name = names{k};

        if ~isfield(config,name) || isempty(config.(name))
            config.(name) = defaults.(name);
        end
    end
end

function createFolder(folderPath)
    if ~isfolder(folderPath)
        mkdir(folderPath);
    end
end
