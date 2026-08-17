%% Minimal single-image example
clear;
clc;

imagePath = fullfile(pwd, 'example.jpg'); % Replace with an image path.
inputImage = imread(imagePath);
[predictedMask, crackProbability, info] = ...
    predictCrackEnsemble(inputImage, "auto");

figure('Color', 'w');
tiledlayout(1, 3, Padding='compact', TileSpacing='compact');
nexttile; imshow(inputImage); title('Original');
nexttile; imshow(crackProbability, []); title('Crack probability');
nexttile; imshow(predictedMask); title('Prediction');
fprintf('Inference time: %.2f seconds\n', info.ElapsedSeconds);
