# ELEC9773 Final U-Net Ensemble UI Package

This folder contains the frozen final four-model crack segmentation ensemble.

## UI call

Add this folder to the MATLAB path once, then call:

```matlab
[predictedMask, crackProbability, info] = ...
    predictCrackEnsemble(inputImage, "auto");
```

- `inputImage`: RGB/grayscale array, or an image path.
- `predictedMask`: logical mask in the original image size.
- `crackProbability`: crack probability map in the original image size.
- `info.ElapsedSeconds`: total inference time.

The model file is loaded once and cached by the prediction function. Do not
load the model separately for every UI button press.

## Adaptive large-image call used by CrackVision

`predictCrackEnsembleAdaptive.m` is the UI deployment entry point. It keeps
normal CRACK500-sized images on the original whole-image path and
automatically uses overlapped tiled inference when the image would otherwise
be reduced below two-thirds scale:

```matlab
[predictedMask, crackProbability, info] = ...
    predictCrackEnsembleAdaptive(inputImage, "auto");
```

- Landscape tile: `360 x 640`; portrait tile: `640 x 360`
- Overlap: `25%`
- Merge: smooth probability blending before the frozen threshold
- `info.InferenceMode`: `"whole"` or `"tiled"`
- `info.TileGrid` and `info.TileCount`: tiled execution details

The helper preserves the original `predictCrackEnsemble` function unchanged.

## Frozen configuration

- Models: Focal ResNet-18 + Hard-RS + Photometric + Transfer
- Weights: `0.660 / 0.102 / 0.102 / 0.136`
- TTA: identity, horizontal flip, vertical flip
- Threshold: `0.33`
- Minimum connected-component area: `0`
- Protocol: `TestCrop-optimised / development-exposed`

## MATLAB requirements

- Deep Learning Toolbox
- Image Processing Toolbox
- Computer Vision Toolbox
- Parallel Computing Toolbox only when GPU inference is used

The trained ResNet weights are already inside the model file. No pretrained
network support package or Internet download is required.
