function [predMask, debugInfo] = classicalCrackBaseline(I, varargin)
%CLASSICALCRACKBASELINE Segment road cracks using a classical pipeline.
% 直接套用 V2 批量评估脚本的固定逻辑与参数
% 该组内基线为固定协议；可选第二输入仅为兼容旧调用，不会改变算法。

narginchk(1, 2);

% ---------- Sauvola / CLAHE 固化参数 ----------
w         = 321;      % 窗口大小
k         = 0.80;     % 灵敏度 0.80
R         = 0.5;      % 动态范围
clipLimit = 0.015;    % CLAHE 裁剪限制
numTiles  = [2 2];    % 块大小

% ---------- 后处理形态学固化参数 ----------
open_radius  = 1;     % 开运算半径（去盐噪）
close_radius = 2;     % 闭运算半径（连接断裂裂缝）
area_th      = 600;   % bwareaopen 面积阈值

% Step1: 灰度化+归一化
if ndims(I) == 3
    gray = rgb2gray(I);
else
    gray = I;
end
grayD = im2double(gray);

% Step2: CLAHE
enhanced = adapthisteq(grayD, 'ClipLimit', clipLimit, ...
                   'NumTiles', numTiles, 'Distribution', 'rayleigh');

% Step3: Sauvola 阈值 (内联展开)
m  = imboxfilt(enhanced, w);
m2 = imboxfilt(enhanced.^2, w);
s  = sqrt(max(m2 - m.^2, 0));
T  = m .* (1 + k .* (s./R - 1));
rawMask = enhanced < T;   % cracks darker than local T

% Step4: 开运算去噪
mask = imopen(rawMask, strel('disk', open_radius, 0));

% Step5: 闭运算连接裂缝
if close_radius > 0                                               
    mask = imclose(mask, strel('disk', close_radius, 0));
end

% Step6: 面积过滤
predMask = bwareaopen(mask, area_th);

% 保持 debugInfo 输出结构，供外部调用
debugInfo = struct();
debugInfo.gray = grayD;
debugInfo.enhanced = enhanced;
debugInfo.rawMask = rawMask;
debugInfo.cleanMask = predMask;

end
