# CRACK500 最小 Padding 滑动窗口 U-Net

## 核心设计

```text
原始图片（不缩放）
        ↓
高度、宽度分别补到最小合法尺寸
        ↓
只在右侧和下方 symmetric padding
        ↓
256×256 窗口，stride 128
        ↓
U-Net 输出每个 tile 的 crack score
        ↓
cosine weighted overlap blending
        ↓
完整 score map
        ↓
validation 选择的 threshold
        ↓
裁剪回原图尺寸
```

## 为什么不是补成正方形

例如 MATLAB 尺寸为：

```text
Height=640, Width=360
```

最小 padding：

```text
640×360 -> 640×384
```

窗口数：

```text
4×2 = 8
```

若补成正方形则需要 16 个窗口，因此最小 padding 更快。

另一种：

```text
484×648 -> 512×768
```

窗口数：

```text
3×5 = 15
```

## 数据目录

```text
road-crack-detection-matlab/
├── src/
│   ├── ui/
│   │   └── predict_crack_mask.m
│   ├── data/
│   │   └── CRACK500/
│   │       ├── train/
│   │       ├── val/
│   │       └── test/
│   └── deeplearning/
├── models/
└── results/
```

同名配对：

```text
xxx.jpg  <->  xxx.png
```

## 第一次运行

在项目根目录：

```matlab
clear functions;
rehash;
restoredefaultpath;

addpath(genpath(fullfile(pwd,'src')));

[modelFile, summaryTable, perImageTable] = ...
    run_minimal_sliding_unet_pipeline(true, true);
```

## 使用已有 patches 重新训练

```matlab
[modelFile, summaryTable, perImageTable] = ...
    run_minimal_sliding_unet_pipeline(false, true);
```

## 使用已有模型直接评估

```matlab
[modelFile, summaryTable, perImageTable] = ...
    run_minimal_sliding_unet_pipeline(false, false);
```

## UI / 单张图预测

项目对 UI 暴露统一的文件路径接口：

```matlab
maskPath = predict_crack_mask('example.jpg');
```

默认输出到：

```text
results/ui_predictions/masks/<原文件名>_mask.png
```

指定输出目录或模型文件：

```matlab
maskPath = predict_crack_mask( ...
    'example.jpg', ...
    'D:/output/masks', ...
    'D:/models/crack500_unet_minimal_sliding_256.mat');
```

## 训练 patch 标签

RGB padding 使用：

```matlab
padarray(I, ..., 'symmetric', 'post')
```

但 ground truth 不会镜像复制裂缝。

训练数据额外保存 `valid` mask：

```text
valid=1：原图真实区域
valid=0：padding 区域
```

训练时 `valid=0` 被转换成 categorical `<undefined>`，
因此 pixel classification loss 不计算 padding 区域。

## 训练 patch 筛选

默认：

```matlab
negativeToPositiveRatio = 1.0;
minimumBackgroundPerImage = 2;
```

保留全部含 crack 窗口，并从每张原图中保留一定数量的纯背景窗口。

## 模型设置

```matlab
inputSize = [256 256 3];
encoderDepth = 3;
miniBatchSize = 4;
maxEpochs = 50;
initialLearnRate = 3e-4;
```

显存不足：

```matlab
miniBatchSize = 2;
```

## 类别权重

默认：

```matlab
weightMode = "sqrt_capped";
maxCrackWeight = 8;
```

固定 5% 权重对照：

```matlab
weightMode = "fixed5percent";
```

对应 background=1、crack=19。

## 输出

派生 patches：

```text
src/data/derived/CRACK500_minimal_sliding_256/
├── train/
│   ├── images/
│   ├── masks/
│   ├── valid/
│   └── patch_metadata.csv
└── val/
```

模型：

```text
models/crack500_unet_minimal_sliding_256.mat
```

结果：

```text
results/deeplearning/minimal_sliding_256/
├── class_weights.csv
├── validation_threshold_search.csv
└── test/
    ├── predicted_masks/
    ├── overlays/
    ├── per_image_metrics.csv
    └── summary_metrics.csv
```
