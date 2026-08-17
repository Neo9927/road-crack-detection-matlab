function modelBundle = loadCrackModel(modelPath)
%LOADCRACKMODEL 加载Formal V1道路裂缝分割模型及其固定配置。
%   modelBundle = loadCrackModel()加载交付包models文件夹中的默认模型。
%   modelBundle = loadCrackModel(modelPath)加载指定路径中的兼容模型。

% 如果调用者没有提供路径，则使用交付包内的默认模型
if nargin < 1 || strlength(string(modelPath)) == 0
    packageFolder = fileparts(mfilename('fullpath'));
    modelPath = fullfile(packageFolder, ...
        'models', 'unet_v1_formal.mat');
end

% 检查模型文件是否存在，避免UI运行到预测阶段才报错
if ~isfile(modelPath)
    error('Formal V1 model file was not found: %s', modelPath);
end

% 只加载推理所需变量，不加载训练历史或其他实验数据
savedModel = load(modelPath, ...
    'trainedV1Net', 'inputSize', 'classNames', 'labelIDs');

% 检查模型文件是否包含约定的四个变量
requiredVariables = [ ...
    "trainedV1Net", "inputSize", "classNames", "labelIDs"];
loadedVariables = string(fieldnames(savedModel));
if ~all(ismember(requiredVariables, loadedVariables))
    error('The model file does not follow the Formal V1 handoff contract.');
end

% 将网络和预处理配置整理为统一的modelBundle
modelBundle = struct;
modelBundle.Network = savedModel.trainedV1Net;
modelBundle.InputSize = savedModel.inputSize;
modelBundle.ClassNames = string(savedModel.classNames);
modelBundle.LabelIDs = savedModel.labelIDs;

% 保存UI和日志需要的版本信息
modelBundle.ModelID = "ELEC9773-CRACK500-UNET";
modelBundle.ModelVersion = "Formal-V1";
modelBundle.InterfaceVersion = "1.0";
modelBundle.InferenceRoute = "whole-image-resize";
modelBundle.ModelPath = string(modelPath);

% 检查输入尺寸和类别名称是否仍然符合当前接口
if ~isequal(modelBundle.InputSize, [256 256 3]) || ...
        ~all(ismember(["background", "crack"], ...
        modelBundle.ClassNames))
    error('Formal V1 input size or class names are not compatible.');
end
end
