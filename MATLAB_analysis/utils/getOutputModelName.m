function outputModel = getOutputModelName(inputModel, config)
%GETOUTPUTMODELNAME Convert input model labels to standardized output labels.

    inputModel = string(inputModel);
    outputModel = inputModel;

    if nargin >= 2 && isstruct(config) && isfield(config, 'labels')
        adInput = string(config.labels.models.ad);
        adOutput = string(config.labels.outputs.ad);
        controlInput = string(config.labels.models.control);
        if strcmpi(inputModel, adInput) || strcmpi(inputModel, "APP")
            outputModel = adOutput;
        elseif strcmpi(inputModel, controlInput)
            outputModel = "WT";
        end
    elseif strcmpi(inputModel, "APP")
        outputModel = "AD";
    end
end
