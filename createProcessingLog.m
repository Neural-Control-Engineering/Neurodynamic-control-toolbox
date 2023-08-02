function createProcessingLog(params)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

params.log_name = 'photometry_extraction_log';
params.path = 'G:\My Drive\#Projects\Project_Neurotransmitter-Exploration\Raw Photometry Data';
params.Headers = {'Name','Processed'};
params.VariableTypes = {'string','logical'};

photometry_extraction_log = table('Size',[0,length(params.Headers)],'VariableNames',params.Headers,'VariableTypes',params.VariableTypes);

save(strcat(params.path,"\",params.log_name,'.mat'),'photometry_extraction_log');

end