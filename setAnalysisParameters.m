function [analysis_params] = setAnalysisParameters(opt_windows)
%SETANALYSISPARAMETERS(windows) Define values that will be referenced for analysis
%   For now, no user input provided. Will parameterize in future. For now
%   will set the defaults below:

% Check for which input is provided
if ~isfield(opt_windows,'response_window'); opt_windows.response_window = 0.800; end
if ~isfield(opt_windows,'before_event'); opt_windows.before_event = 2; end
if ~isfield(opt_windows,'after_event'); opt_windows.after_event = 6; end
if ~isfield(opt_windows,'event_baseline'); opt_windows.event_baseline = 0.5; end
if ~isfield(opt_windows,'drop_buffer_start'); opt_windows.drop_buffer_start = 120; end
if ~isfield(opt_windows,'drop_buffer_end'); opt_windows.drop_buffer_end = 120; end
% (2022-12-22) add two new parameters: (1) MA_window change the window when
% using filtfilt to preprocess isosbestic signal(405), with second as unit.
% (2) debug_mode authorize some functions to plot prelimanary plots to
% evaluate those function and processed data 
if ~isfield(opt_windows,'MA_window'); opt_windows.MA_window = 0.1; end
if ~isfield(opt_windows,'debug_mode'); opt_windows.debug_mode = false; end

analysis_params.response_window = opt_windows.response_window;
analysis_params.before_event = opt_windows.before_event;
analysis_params.after_event = opt_windows.after_event;
analysis_params.baseline = opt_windows.event_baseline;
analysis_params.drop_buffer_start = opt_windows.drop_buffer_start;
analysis_params.drop_buffer_end = opt_windows.drop_buffer_end;
%
analysis_params.MA_window = opt_windows.MA_window;
analysis_params.debug_mode = opt_windows.debug_mode;

% Number of properties to include in the combined processed data
analysis_params.num_of_properties = 60;

end

