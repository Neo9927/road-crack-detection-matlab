function modelFile = train_minimal_sliding_unet(rebuildPatches)
%TRAIN_MINIMAL_SLIDING_UNET 使用不缩放的 256×256 patches 训练 U-Net。
%
% 训练图像预处理：
%   原图
%   -> 高度、宽度分别做最小 symmetric padding
%   -> 256×256 window
%   -> stride 128
%
% 标签预处理：
%   原始区域保留 background/crack；
%   padding 区域标记为 undefined，训练 loss 自动忽略。
%
% 训练与推理使用相同的原始像素尺度，避免 letterbox resize
% 导致的训练/推理分布差异。

    if nargin < 1
        rebuildPatches = false;
    end

    rng(42, 'twister');

    %% 1. 项目路径
    thisDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(fileparts(thisDir));

    dataRoot = fullfile( ...
        repoRoot, 'src', 'data', 'CRACK500');

    trainDir = fullfile(dataRoot, 'train');
    valDir   = fullfile(dataRoot, 'val');

    derivedRoot = fullfile( ...
        repoRoot, 'src', 'data', 'derived', ...
        'CRACK500_minimal_sliding_256');

    patchTrainDir = fullfile(derivedRoot, 'train');
    patchValDir   = fullfile(derivedRoot, 'val');

    modelDir = fullfile(repoRoot, 'models');

    resultDir = fullfile( ...
        repoRoot, 'results', 'deeplearning', ...
        'minimal_sliding_256');

    checkpointDir = fullfile( ...
        modelDir, 'checkpoints_minimal_sliding_256');

    createFolder(modelDir);
    createFolder(resultDir);
    createFolder(checkpointDir);

    %% 2. 核心参数
    inputSize = [256 256 3];
    windowSize = 256;
    stride = 128;
    blendMode = "cosine";

    classNames = ["background", "crack"];
    numberOfClasses = numel(classNames);

    encoderDepth = 3;
    maxEpochs = 50;
    miniBatchSize = 4;
    initialLearnRate = 3e-4;
    validationPatience = 10;
    executionEnvironment = 'auto';

    % 训练 patch 筛选：
    % 保留所有包含 crack 的窗口；
    % 对纯背景窗口按每张原图进行下采样。
    negativeToPositiveRatio = 1.0;
    minimumBackgroundPerImage = 2;

    % 类别权重模式：
    %   "sqrt_capped"   推荐
    %   "fixed5percent" background=1, crack=19
    %   "none"
    weightMode = "sqrt_capped";
    maxCrackWeight = 8;

    thresholdCandidates = 0.10:0.05:0.90;

    fprintf('\n===== Minimal Sliding U-Net Training =====\n');
    fprintf('Window size: %d\n', windowSize);
    fprintf('Stride:      %d\n', stride);
    fprintf('Input size:  [%d %d %d]\n', inputSize);
    fprintf('Encoder depth: %d\n\n', encoderDepth);

    %% 3. 检查原始 train / val 数据
    trainPairs = list_samebasename_pairs(trainDir);
    valPairs = list_samebasename_pairs(valDir);

    trainSizeReport = validate_pair_table(trainPairs);
    valSizeReport = validate_pair_table(valPairs);

    writetable(trainSizeReport, ...
        fullfile(resultDir, 'train_source_sizes.csv'));

    writetable(valSizeReport, ...
        fullfile(resultDir, 'val_source_sizes.csv'));

    %% 4. 生成不缩放的滑窗训练数据
    trainPatchConfig.WindowSize = windowSize;
    trainPatchConfig.Stride = stride;
    trainPatchConfig.KeepAllPatches = false;
    trainPatchConfig.NegativeToPositiveRatio = ...
        negativeToPositiveRatio;
    trainPatchConfig.MinimumBackgroundPerImage = ...
        minimumBackgroundPerImage;
    trainPatchConfig.RandomSeed = 42;
    trainPatchConfig.Overwrite = rebuildPatches;

    valPatchConfig.WindowSize = windowSize;
    valPatchConfig.Stride = stride;
    valPatchConfig.KeepAllPatches = true;
    valPatchConfig.NegativeToPositiveRatio = inf;
    valPatchConfig.MinimumBackgroundPerImage = 0;
    valPatchConfig.RandomSeed = 4242;
    valPatchConfig.Overwrite = rebuildPatches;

    trainMetadataFile = fullfile( ...
        patchTrainDir, 'patch_metadata.csv');

    valMetadataFile = fullfile( ...
        patchValDir, 'patch_metadata.csv');

    if rebuildPatches || ~isfile(trainMetadataFile)
        build_minimal_patch_dataset( ...
            trainDir, patchTrainDir, trainPatchConfig);
    else
        fprintf('Using existing training patches: %s\n', ...
            patchTrainDir);
    end

    if rebuildPatches || ~isfile(valMetadataFile)
        build_minimal_patch_dataset( ...
            valDir, patchValDir, valPatchConfig);
    else
        fprintf('Using existing validation patches: %s\n', ...
            patchValDir);
    end

    %% 5. 建立 patch datastores
    [imdsTrain, maskDsTrain, validDsTrain, trainMetadata] = ...
        create_patch_triplet_datastores(patchTrainDir);

    [imdsVal, maskDsVal, validDsVal, valMetadata] = ...
        create_patch_triplet_datastores(patchValDir);

    fprintf('Training patches:   %d\n', height(trainMetadata));
    fprintf('Validation patches: %d\n', height(valMetadata));

    %% 6. 根据有效像素统计类别权重
    [classWeights, weightTable] = ...
        calculate_minimal_patch_class_weights( ...
            maskDsTrain, validDsTrain, ...
            weightMode, maxCrackWeight);

    writetable(weightTable, ...
        fullfile(resultDir, 'class_weights.csv'));

    %% 7. 建立 U-Net
    lgraph = unetLayers( ...
        inputSize, numberOfClasses, ...
        'EncoderDepth', encoderDepth);

    outputLayerIndex = find(arrayfun(@(k) ...
        isa(lgraph.Layers(k), ...
        'nnet.cnn.layer.PixelClassificationLayer'), ...
        1:numel(lgraph.Layers)), 1, 'last');

    if isempty(outputLayerIndex)
        error('PixelClassificationLayer not found in U-Net.');
    end

    oldOutputLayerName = ...
        lgraph.Layers(outputLayerIndex).Name;

    weightedOutputLayer = pixelClassificationLayer( ...
        'Name', 'weighted_pixel_labels', ...
        'Classes', weightTable.Class, ...
        'ClassWeights', classWeights);

    lgraph = replaceLayer( ...
        lgraph, oldOutputLayerName, weightedOutputLayer);

    %% 8. 训练和 validation patch 流水线
    dsTrain = transform( ...
        combine(imdsTrain, maskDsTrain, validDsTrain), ...
        @augment_minimal_patch_triplet);

    dsVal = transform( ...
        combine(imdsVal, maskDsVal, validDsVal), ...
        @preprocess_minimal_patch_triplet);

    % 保存一个训练 patch 检查图。
    sample = read(dsTrain);
    reset(dsTrain);

    sampleFigure = figure('Name', 'Training Patch Check');
    tiledlayout(1, 3);

    nexttile;
    imshow(sample{1});
    title('Training patch');

    nexttile;
    imshow(sample{2} == 'crack');
    title('Crack label');

    nexttile;
    imshow(labeloverlay( ...
        sample{1}, sample{2} == 'crack', ...
        'Transparency', 0.65, ...
        'Colormap', [0 1 0]));
    title('Patch alignment');

    exportgraphics(sampleFigure, ...
        fullfile(resultDir, 'training_patch_check.png'));

    %% 9. Training options
    iterationsPerEpoch = ceil( ...
        numel(imdsTrain.Files) / miniBatchSize);

    validationFrequency = max(1, iterationsPerEpoch);

    options = trainingOptions('adam', ...
        'InitialLearnRate', initialLearnRate, ...
        'L2Regularization', 1e-4, ...
        'GradientThreshold', 1, ...
        'MaxEpochs', maxEpochs, ...
        'MiniBatchSize', miniBatchSize, ...
        'Shuffle', 'every-epoch', ...
        'ValidationData', dsVal, ...
        'ValidationFrequency', validationFrequency, ...
        'ValidationPatience', validationPatience, ...
        'OutputNetwork', 'best-validation-loss', ...
        'CheckpointPath', checkpointDir, ...
        'ExecutionEnvironment', executionEnvironment, ...
        'Verbose', true, ...
        'VerboseFrequency', ...
            max(1, floor(iterationsPerEpoch / 4)), ...
        'Plots', 'training-progress');

    %% 10. 训练
    fprintf('\nStarting patch U-Net training...\n');

    [net, trainingInfo] = ...
        trainNetwork(dsTrain, lgraph, options);

    %% 11. 在完整 validation 图片上重新选择 threshold
    [bestThreshold, thresholdTable] = ...
        tune_minimal_sliding_threshold( ...
            net, valDir, ...
            windowSize, stride, ...
            blendMode, thresholdCandidates);

    writetable(thresholdTable, ...
        fullfile(resultDir, ...
            'validation_threshold_search.csv'));

    %% 12. 保存模型
    trainingConfig = struct();
    trainingConfig.inputSize = inputSize;
    trainingConfig.windowSize = windowSize;
    trainingConfig.stride = stride;
    trainingConfig.blendMode = blendMode;
    trainingConfig.classNames = classNames;
    trainingConfig.encoderDepth = encoderDepth;
    trainingConfig.maxEpochs = maxEpochs;
    trainingConfig.miniBatchSize = miniBatchSize;
    trainingConfig.initialLearnRate = initialLearnRate;
    trainingConfig.weightMode = weightMode;
    trainingConfig.classWeights = classWeights;
    trainingConfig.bestThreshold = bestThreshold;
    trainingConfig.negativeToPositiveRatio = ...
        negativeToPositiveRatio;
    trainingConfig.minimumBackgroundPerImage = ...
        minimumBackgroundPerImage;
    trainingConfig.randomSeed = 42;

    modelFile = fullfile( ...
        modelDir, ...
        'crack500_unet_minimal_sliding_256.mat');

    save(modelFile, ...
        'net', ...
        'trainingInfo', ...
        'trainingConfig', ...
        'weightTable', ...
        'thresholdTable', ...
        '-v7.3');

    fprintf('\nTraining complete.\n');
    fprintf('Saved model: %s\n', modelFile);
    fprintf('Best validation threshold: %.2f\n', ...
        bestThreshold);
end

function createFolder(folderPath)
    if ~isfolder(folderPath)
        mkdir(folderPath);
    end
end
