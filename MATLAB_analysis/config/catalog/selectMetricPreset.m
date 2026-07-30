function metrics = selectMetricPreset(catalog, presetName)
%SELECTMETRICPRESET Build metric-selection fields from a named preset.

    presetName = string(presetName);
    allIds = string({catalog.id});
    groups = unique(string({catalog.group}), 'stable');

    metrics.preset = presetName;
    metrics.selected = strings(0, 1);
    metrics.groups = struct();

    switch presetName
        case "paper_metrics"
            selected = allIds([catalog.paper]);
        otherwise
            selected = allIds;
    end

    metrics.selected = selected(:);
    for i = 1:numel(groups)
        fieldName = matlab.lang.makeValidName(groups(i));
        groupIds = allIds(string({catalog.group}) == groups(i));
        metrics.groups.(fieldName).enabled = any(ismember(groupIds, selected));
        metrics.groups.(fieldName).selected = groupIds(ismember(groupIds, selected));
    end
end
