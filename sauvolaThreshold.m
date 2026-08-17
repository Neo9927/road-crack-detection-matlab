function mask = sauvolaThreshold(I, windowSize, k, R)
%SAUVOLATHRESHOLD True Sauvola local thresholding for dark cracks.
% I must be a double image in [0,1]. The output mask is logical crack=1.

if ~isa(I, 'double')
    I = im2double(I);
end

if mod(windowSize, 2) == 0
    windowSize = windowSize + 1;
end

localMean = imboxfilt(I, windowSize);
localMeanSq = imboxfilt(I.^2, windowSize);
localStd = sqrt(max(localMeanSq - localMean.^2, 0));

T = localMean .* (1 + k .* (localStd ./ R - 1));
mask = I < T;
end
