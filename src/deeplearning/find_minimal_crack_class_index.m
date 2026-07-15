function crackIndex = find_minimal_crack_class_index(net)
%FIND_MINIMAL_CRACK_CLASS_INDEX 找到 semanticseg crack score 通道。

    outputLayerIndex = find(arrayfun(@(k) ...
        isa(net.Layers(k), ...
        'nnet.cnn.layer.PixelClassificationLayer'), ...
        1:numel(net.Layers)), 1, 'last');

    if isempty(outputLayerIndex)
        error('PixelClassificationLayer not found.');
    end

    classNames = string( ...
        net.Layers(outputLayerIndex).Classes);

    crackIndex = find(classNames == "crack", 1);

    if isempty(crackIndex)
        error('Crack class not found.');
    end
end
