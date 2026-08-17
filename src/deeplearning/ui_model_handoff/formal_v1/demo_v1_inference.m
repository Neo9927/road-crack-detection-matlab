%% Formal V1 UI handoff demo
% 本脚本验证交付包无需训练代码即可完成一次道路裂缝预测。

% 清空命令行并关闭旧图窗
clc;
close all;
clear;

% 获取交付包文件夹并加入MATLAB搜索路径
packageFolder = fileparts(mfilename('fullpath'));
addpath(packageFolder);

% 从交付包models文件夹加载Formal V1模型
modelBundle = loadCrackModel();

% 让使用者选择一张需要检测的道路图像
[imageFilename, imageFolder] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png;*.bmp', 'Road images'}, ...
    'Select one road image');

% 如果使用者取消选择，则结束演示且不报错
if isequal(imageFilename, 0)
    fprintf('No image was selected. Demo stopped.\n');
    return;
end

% 读取使用者选择的原始图像
inputImage = imread(fullfile(imageFolder, imageFilename));

% 通过稳定公共接口获得Mask、Overlay和推理信息
[predictedMask, overlayImage, info] = ...
    predictCrackMask(inputImage, modelBundle);

% 显示原图、预测Mask和红色Overlay
figure('Name', 'Formal V1 UI handoff demo', ...
    'Color', 'white', 'Position', [100 100 1500 520]);
demoLayout = tiledlayout(1, 3, ...
    'TileSpacing', 'compact', 'Padding', 'compact');
title(demoLayout, sprintf( ...
    '%s | inference %.3f s | predicted crack %.2f%%', ...
    info.ModelVersion, info.InferenceTimeSeconds, ...
    100 * info.PredictedCrackFraction));

% 第一列显示原始输入图像
nexttile;
imshow(inputImage);
title('Original image');

% 第二列显示与原图同尺寸的逻辑预测Mask
nexttile;
imshow(predictedMask);
title('Predicted crack mask');

% 第三列显示可直接放入UIAxes的红色叠加结果
nexttile;
imshow(overlayImage);
title('Prediction overlay');

% 在命令行打印完整接口返回信息
fprintf('Formal V1 handoff demo completed.\n');
disp(info);
