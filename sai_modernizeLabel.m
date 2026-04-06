function modern = sai_modernizeLabel(label)
%SAI_MODERNIZELABEL  Map outdated ImageNet class names to modern equivalents.
%   modern = sai_modernizeLabel(label) returns a friendlier version of the
%   ImageNet label if one exists, otherwise returns the input unchanged.

    persistent labelMap
    if isempty(labelMap)
        labelMap = containers.Map('KeyType','char','ValueType','char');
        % Electronics & tech
        labelMap('cellular telephone') = 'Phone';
        labelMap('cellular phone') = 'Phone';
        labelMap('cell phone') = 'Phone';
        labelMap('iPod') = 'Music Player';
        labelMap('notebook') = 'Laptop';
        labelMap('notebook computer') = 'Laptop';
        labelMap('laptop') = 'Laptop';
        labelMap('desktop computer') = 'Computer';
        labelMap('screen') = 'Screen';
        labelMap('monitor') = 'Monitor';
        labelMap('television') = 'TV';
        labelMap('remote control') = 'Remote';
        labelMap('joystick') = 'Game Controller';
        labelMap('mouse') = 'Computer Mouse';
        labelMap('hand-held computer') = 'Tablet';
        labelMap('web site') = 'Website';
        labelMap('CRT screen') = 'Monitor';
        % Clothing & accessories
        labelMap('running shoe') = 'Sneaker';
        labelMap('jean') = 'Jeans';
        labelMap('jersey') = 'Sports Jersey';
        labelMap('sweatshirt') = 'Hoodie';
        labelMap('sunglass') = 'Sunglasses';
        labelMap('Polaroid camera') = 'Instant Camera';
        % Vehicles
        labelMap('cab') = 'Taxi';
        labelMap('minivan') = 'Van';
        labelMap('convertible') = 'Car';
        labelMap('limousine') = 'Limo';
        labelMap('recreational vehicle') = 'RV';
        labelMap('Model T') = 'Classic Car';
        % Animals (simplify breed specifics)
        labelMap('tabby') = 'Cat';
        labelMap('tabby cat') = 'Cat';
        labelMap('Egyptian cat') = 'Cat';
        labelMap('Persian cat') = 'Cat';
        labelMap('Siamese cat') = 'Cat';
        labelMap('tiger cat') = 'Cat';
        % Food & drink
        labelMap('espresso') = 'Coffee';
        labelMap('cup') = 'Cup';
        labelMap('coffee mug') = 'Mug';
        labelMap('pop bottle') = 'Soda Bottle';
        labelMap('water bottle') = 'Water Bottle';
        labelMap('wine bottle') = 'Wine Bottle';
        labelMap('beer bottle') = 'Beer Bottle';
        labelMap('beer glass') = 'Beer Glass';
        % Household
        labelMap('washbasin') = 'Sink';
        labelMap('wash basin') = 'Sink';
        labelMap('bathtub') = 'Bathtub';
        labelMap('toilet tissue') = 'Toilet Paper';
        labelMap('electric fan') = 'Fan';
        labelMap('table lamp') = 'Lamp';
        labelMap('desk') = 'Desk';
        labelMap('dining table') = 'Table';
        labelMap('rocking chair') = 'Chair';
        labelMap('folding chair') = 'Chair';
        % Office & school
        labelMap('ballpoint') = 'Pen';
        labelMap('ballpoint pen') = 'Pen';
        labelMap('fountain pen') = 'Pen';
        labelMap('pencil box') = 'Pencil Case';
        labelMap('binder') = 'Binder';
        labelMap('rubber eraser') = 'Eraser';
        labelMap('rule') = 'Ruler';
        labelMap('ruler') = 'Ruler';
        % Misc
        labelMap('gasmask') = 'Gas Mask';
        labelMap('plate') = 'Plate';
        labelMap('mixing bowl') = 'Bowl';
        labelMap('soup bowl') = 'Bowl';
    end

    name = char(label);
    % Try exact match first (case-insensitive)
    lowerName = lower(strtrim(name));
    if labelMap.isKey(lowerName)
        modern = labelMap(lowerName);
    else
        modern = name;
    end
end
