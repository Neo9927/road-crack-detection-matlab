function [modelFile, summaryTable, perImageTable] = ...
        run_minimal_sliding_unet_pipeline(rebuildPatches, retrainModel)
%RUN_MINIMAL_SLIDING_UNET_PIPELINE 完整的最小 padding 滑窗 U-Net 流程。
%
% 用法：
%   run_minimal_sliding_unet_pipeline(true, true)
%       重新生成训练 patches、重新训练、重新评估。
%
%   run_minimal_sliding_unet_pipeline(false, true)
%       使用已有 patches 重新训练。
%
%   run_minimal_sliding_unet_pipeline(false, false)
%       使用已有模型直接评估。
%
% 核心配置：
%   windowSize = 256
%   stride     = 128
%   padding    = 只在右侧和下方进行最小 symmetric padding
%   resize     = 不缩放原图
%
% 数据命名：
%   xxx.jpg  <->  xxx.png

    if nargin < 1
        rebuildPatches = false;
    end

    if nargin < 2
        retrainModel = false;
    end

    thisDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(fileparts(thisDir));

    addpath(genpath(fullfile(repoRoot, 'src')));

    modelFile = fullfile( ...
        repoRoot, 'models', ...
        'crack500_unet_minimal_sliding_256.mat');

    if retrainModel || ~isfile(modelFile)
        modelFile = train_minimal_sliding_unet(rebuildPatches);
    else
        fprintf('\n发现已有模型，跳过训练：\n%s\n', modelFile);
    end

    [summaryTable, perImageTable] = ...
        evaluate_minimal_sliding_unet(modelFile);
end
