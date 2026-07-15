function metrics = ...
        compute_minimal_segmentation_metrics( ...
            predictedMask, groundTruth)
%COMPUTE_MINIMAL_SEGMENTATION_METRICS 计算像素级二分类指标。

    predictedMask = logical(predictedMask);
    groundTruth = logical(groundTruth);

    TP = sum(predictedMask(:) & groundTruth(:));
    FP = sum(predictedMask(:) & ~groundTruth(:));
    FN = sum(~predictedMask(:) & groundTruth(:));
    TN = sum(~predictedMask(:) & ~groundTruth(:));

    if TP + FP == 0
        if TP + FN == 0
            precision = 1;
        else
            precision = 0;
        end
    else
        precision = TP / (TP + FP);
    end

    if TP + FN == 0
        recall = 1;
    else
        recall = TP / (TP + FN);
    end

    if precision + recall == 0
        f1 = 0;
    else
        f1 = 2*precision*recall / ...
            (precision+recall);
    end

    if TP + FP + FN == 0
        crackIoU = 1;
    else
        crackIoU = TP / (TP + FP + FN);
    end

    if TN + FP + FN == 0
        backgroundIoU = 1;
    else
        backgroundIoU = TN / (TN + FP + FN);
    end

    meanIoU = mean([crackIoU backgroundIoU]);

    metrics = struct();
    metrics.TP = TP;
    metrics.FP = FP;
    metrics.FN = FN;
    metrics.TN = TN;
    metrics.Precision = precision;
    metrics.Recall = recall;
    metrics.F1 = f1;
    metrics.CrackIoU = crackIoU;
    metrics.BackgroundIoU = backgroundIoU;
    metrics.MeanIoU = meanIoU;
end
