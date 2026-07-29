function enabled = isMetricGroupEnabled(config, groupName)
%ISMETRICGROUPENABLED Return true when a metric group is enabled.
%
% Missing metric-selection fields default to true to preserve backward
% compatibility with configurations created before metric filtering existed.

    fieldName = matlab.lang.makeValidName(string(groupName));
    enabled = ~isfield(config, 'metrics') || ~isfield(config.metrics, 'groups') ...
        || ~isfield(config.metrics.groups, fieldName) ...
        || config.metrics.groups.(fieldName).enabled;
end
