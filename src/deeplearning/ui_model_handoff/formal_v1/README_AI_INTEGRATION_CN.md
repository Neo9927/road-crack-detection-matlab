# Formal V1 UI 模型交付说明

## 1. 交付目标

本文件夹用于将 ELEC9773 Week 7 的 Formal U-Net V1 模型交付给 MATLAB App Designer UI 模块。

UI 只需要调用两个公共函数：

```matlab
modelBundle = loadCrackModel();
[predictedMask, overlayImage, info] = ...
    predictCrackMask(inputImage, modelBundle);
```

UI 不需要调用训练、数据集构建、模型评价或 V0/V1 比较代码。

---

## 2. 文件清单

| 文件 | 用途 |
|---|---|
| `models/unet_v1_formal.mat` | Formal V1 模型制品 |
| `loadCrackModel.m` | 加载一次模型并返回统一的 `modelBundle` |
| `predictCrackMask.m` | 输入图像，返回预测 Mask、Overlay 和运行信息 |
| `demo_v1_inference.m` | 不依赖 UI 的最小运行示例 |
| `model_manifest.json` | 供人和 AI 读取的结构化版本及接口信息 |

模型文件 SHA-256：

```text
968CF6092E300CD32736C1593106429039B06B25EC7A9D948B016671B81DE0A1
```

---

## 3. MATLAB 环境

当前交付包在以下环境中开发：

```text
MATLAB R2024b
Deep Learning Toolbox
Computer Vision Toolbox
Image Processing Toolbox
```

GPU 不是接口运行的强制要求。MATLAB 可以根据本机环境选择 CPU 或兼容 GPU。

---

## 4. 模型事实

AI 集成代码不得自行猜测或修改以下信息：

```text
模型版本：Formal-V1
模型变量：trainedV1Net
网络输入：[256 256 3]
类别名称：background、crack
推理路线：整张图 resize 到 256 x 256
预测方式：semanticseg categorical prediction
输出恢复：nearest-neighbour resize 到原图尺寸
```

模型文件同时保存：

```matlab
trainedV1Net
inputSize
classNames
labelIDs
```

---

## 5. 公共接口合同

### 5.1 加载模型

应在 App Designer 的 `startupFcn` 中只加载一次：

```matlab
app.CrackModel = loadCrackModel();
```

不要在每次点击检测按钮时重新执行 `load`。

### 5.2 执行预测

```matlab
[predictedMask, overlayImage, info] = ...
    predictCrackMask(app.CurrentImage, app.CrackModel);
```

输入合同：

```text
inputImage：MATLAB 图像数组
推荐类型：uint8
允许通道：灰度、RGB或带额外通道的图像
```

输出合同：

```text
predictedMask：logical，尺寸为原图 H x W
overlayImage：uint8 RGB，尺寸为原图 H x W x 3
info：包含模型版本、输入输出尺寸、推理时间和预测裂缝比例的 struct
```

UI 模块不应直接访问 `trainedV1Net`，也不应在按钮回调中复制预处理代码。

---

## 6. App Designer 最小集成方式

在 App 的 private properties 中保存模型和当前图像：

```matlab
properties (Access = private)
    CrackModel
    CurrentImage
    PredictedMask
end
```

在 `startupFcn` 中加入交付包路径并加载模型：

```matlab
handoffFolder = fullfile(app.ProjectRoot, ...
    'code', 'matlab', 'ui_model_handoff', 'formal_v1');
addpath(handoffFolder);
app.CrackModel = loadCrackModel();
```

在检测按钮回调中调用公共接口：

```matlab
[app.PredictedMask, overlayImage, info] = ...
    predictCrackMask(app.CurrentImage, app.CrackModel);

imshow(overlayImage, 'Parent', app.ResultUIAxes);
app.StatusLabel.Text = sprintf( ...
    '%s | %.3f s', ...
    info.ModelVersion, info.InferenceTimeSeconds);
```

以上 `ProjectRoot`、`ResultUIAxes` 和 `StatusLabel` 名称应替换为实际 App 中已有的属性或组件名称。

---

## 7. 必须保留的处理顺序

Formal V1 推理过程为：

```text
输入图像
→ 灰度图转换为RGB
→ 只保留前三个通道
→ 转换为uint8
→ 整张图resize到256 x 256
→ semanticseg
→ 提取crack类别
→ 用nearest插值恢复到原图尺寸
→ 生成红色overlay
```

不要在 UI 中额外增加 CLAHE、Gaussian filter、threshold 或 morphology。这些操作没有参与 Formal V1 的训练和原始评价。

---

## 8. 已知限制

1. Formal V1 会将整张图直接缩放为 `256 x 256`，非正方形图像会发生长宽比例变化。
2. 恢复输出 Mask 尺寸不能恢复 resize 过程中已经损失的细裂缝信息。
3. 当前模型适合 Week 7 阶段的功能演示，不代表最终模型。
4. 固定 15 张 CRACK500 test crop 上的 Macro F1 为约 `0.604`，Macro IoU 为约 `0.459`；该小样本结果不是跨数据集性能保证。
5. 后续 V2 会采用原始分辨率滑动窗口，推理速度和内部实现可能变化。

---

## 9. 模型替换规则

未来替换 V2 或最终模型时：

1. 不覆盖或删除 `unet_v1_formal.mat`；
2. 在 `models` 中增加新的版本文件；
3. 更新 `model_manifest.json`；
4. 在 `loadCrackModel` 和 `predictCrackMask` 内部适配新模型；
5. 保持公共函数名称、输入和三个输出不变；
6. 重新运行最小 demo 和 UI 按钮验收测试。

只要公共接口不变，App Designer 的页面和按钮逻辑就不需要随模型版本重写。

---

## 10. 交付验收

UI 队友应确认：

- [ ] `demo_v1_inference.m` 能够独立运行；
- [ ] 模型只在 App 启动时加载一次；
- [ ] 输入灰度图和 RGB 图都能够预测；
- [ ] `predictedMask` 与原图高度和宽度一致；
- [ ] `overlayImage` 能在 `UIAxes` 中显示；
- [ ] 代码中不存在交付者电脑的绝对路径；
- [ ] UI 不直接依赖模型内部变量名；
- [ ] 状态栏能够显示模型版本和推理时间。

---

## 11. 可直接交给 AI 的集成 Prompt

```text
请将ELEC9773 Formal V1道路裂缝模型接入现有MATLAB App Designer。

只允许调用以下公共接口：
modelBundle = loadCrackModel();
[predictedMask, overlayImage, info] = predictCrackMask(inputImage, modelBundle);

要求：
1. 在startupFcn中只加载一次模型，并保存到App private property。
2. 检测按钮只调用predictCrackMask，不要复制或修改模型预处理代码。
3. 将overlayImage显示到结果UIAxes。
4. 将模型版本和推理时间显示到状态组件。
5. 不要添加CLAHE、threshold、morphology或其他额外处理。
6. 不要直接访问trainedV1Net。
7. 保持UI现有布局和其他成员代码不变。
8. 如果实际组件名称不同，只替换属性和组件名称，不改变模型接口。
```
