function outputLength = ...
        aligned_sliding_length(inputLength, windowSize, stride)
%ALIGNED_SLIDING_LENGTH 计算滑窗完整覆盖所需的最小长度。
%
% 满足：
%   outputLength >= inputLength
%   outputLength >= windowSize
%   mod(outputLength-windowSize, stride) == 0

    if inputLength <= windowSize
        outputLength = windowSize;
        return;
    end

    numberOfSteps = ceil( ...
        (inputLength - windowSize) / stride);

    outputLength = ...
        windowSize + numberOfSteps * stride;
end
