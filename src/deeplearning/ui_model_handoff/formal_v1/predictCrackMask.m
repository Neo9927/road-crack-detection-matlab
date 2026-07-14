function [predictedMask, overlayImage, info] = ...
        predictCrackMask(inputImage, modelBundle)
%PREDICTCRACKMASK 使用统一接口执行道路裂缝分割。
%   predictedMask与输入图像具有相同高度和宽度，类型为logical。
%   overlayImage为相同尺寸的uint8 RGB红色叠加图。
%   info包含模型版本、推理时间和预测裂缝比例。

% 检查输入图像和模型是否已经由UI正确传入
if isempty(inputImage)
    error('inputImage is empty. Load an image before prediction.');
end
if nargin < 2 || ~isstruct(modelBundle) || ...
        ~isfield(modelBundle, 'Network')
    error('modelBundle is invalid. Call loadCrackModel first.');
end

% 将灰度图或额外通道图像统一为三通道uint8 RGB图像
displayImage = prepareRgbImage(inputImage);

% 记录原始图像尺寸，供输出Mask恢复使用
originalHeight = size(displayImage, 1);
originalWidth = size(displayImage, 2);

% 按Formal V1训练方式将整张图缩放到256 x 256
networkInput = imresize( ...
    displayImage, modelBundle.InputSize(1:2));

% 对一次完整模型推理进行计时
predictionTimer = tic;

% 使用Formal V1网络生成每个像素的语义类别
predictedLabels = semanticseg( ...
    networkInput, modelBundle.Network, ...
    Classes=modelBundle.ClassNames);

% 记录不包含模型加载时间的推理耗时
inferenceTimeSeconds = toc(predictionTimer);

% 将categorical标签转换为256 x 256二值裂缝Mask
networkMask = predictedLabels == "crack";

% 使用最近邻插值恢复到原图尺寸，避免产生中间标签值
predictedMask = logical(imresize( ...
    networkMask, [originalHeight originalWidth], 'nearest'));

% 在原始比例图像上生成半透明红色预测叠加图
overlayImage = createRedOverlay(displayImage, predictedMask);

% 返回UI状态栏和实验日志可直接使用的信息
info = struct;
info.ModelID = modelBundle.ModelID;
info.ModelVersion = modelBundle.ModelVersion;
info.InterfaceVersion = modelBundle.InterfaceVersion;
info.InferenceRoute = modelBundle.InferenceRoute;
info.OriginalImageSize = size(displayImage);
info.NetworkInputSize = modelBundle.InputSize;
info.OutputMaskSize = size(predictedMask);
info.InferenceTimeSeconds = inferenceTimeSeconds;
info.PredictedCrackFraction = mean(predictedMask(:));
info.KnownLimitation = ...
    "Formal V1 resizes the whole image to 256 x 256 before inference.";
end

function rgbImage = prepareRgbImage(inputImage)
%PREPARERGBIMAGE 将UI输入统一为三通道uint8 RGB图像。

% 灰度图复制为三个相同通道
if size(inputImage, 3) == 1
    inputImage = repmat(inputImage, [1 1 3]);
end

% 如果图像包含alpha等额外通道，则只保留前三个RGB通道
if size(inputImage, 3) > 3
    inputImage = inputImage(:, :, 1:3);
end

% 统一为uint8，便于模型、overlay和App Designer稳定显示
rgbImage = im2uint8(inputImage);
end

function overlayImage = createRedOverlay(rgbImage, binaryMask)
%CREATEREDOVERLAY 在预测裂缝区域叠加半透明红色。

% 建立纯红色覆盖层和三通道逻辑Mask
redLayer = zeros(size(rgbImage), 'uint8');
redLayer(:, :, 1) = 255;
mask3 = repmat(logical(binaryMask), [1 1 3]);

% 以55%透明度混合原图和红色覆盖层
overlayAlpha = 0.55;
blendedImage = uint8( ...
    (1 - overlayAlpha) * double(rgbImage) + ...
    overlayAlpha * double(redLayer));

% 只替换预测裂缝区域，其他像素保持原图不变
overlayImage = rgbImage;
overlayImage(mask3) = blendedImage(mask3);
end
