function toNumpy(data, tbounds, file_name)
% Generates numpy files for photometry data, pupil area, outcome, 
% and response all trials stored within data.  Data are trimmed based 
% on tbounds.  file_name serves as a base for the output file names (e.g. file_name='example'
% will generate files of the form example*.npy).  Make sure npy-matlab is installed 
% and added to your path (e.g. addpath('~/npy-matlab/npy-matlab/')).
% Example:  sessionToNump(Datastore.NE_dstore, [-2, 0], 'Analysis/npys/example')
% Craig Kelley, NEC Lab, 8/10/23

    % right now outcomes and variables are hard coded.  Could edit to alter so 
    % they can be defined by user 
    outcomes = ["CR", "Delayed FA (CR)", "FA", "Hit", "Miss", "Near Hit (Miss)"];
    variables = {'photometry_ch1', 'photometry_ch2', 'pupil_area', 'categorical_outcome', 'go_nogo'};

    for i = 1:length(variables)
        x = data.(variables{i});
        if ~isempty(x)
            % time seris data 
            if contains(variables{i}, 'photometry') || contains(variables{i}, 'pupil_area')
                % trim channel based on tbounds 
                Fs = 1 / (x{1}(2,1) - x{1}(1,1));
                time = linspace(tbounds(1), tbounds(2), Fs*diff(tbounds));
                mat = nan(length(x), length(time));
                for j = 1:length(x)
                    t = x{j}(:,1) - data.stimulus_time(j);
                    ch = x{j}(:,2);
                    ch = ch(t >= tbounds(1) & t <= tbounds(2));
                    % if current channel is not the same size as the first, use spline 
                    % interpolation to fix 
                    if length(ch) ~= size(mat,2)
                        fprintf('%s %s needed interpolation \n', data.session_id{j}, variables{i})
                        chq = interp1(t(t >= tbounds(1) & t <= tbounds(2)), ch, time, 'spline');
                        mat(j,:) = chq;
                    else
                        mat(j,:) = ch;
                    end
                end
                % determine file name 
                if contains(variables{i}, 'photometry')
                    parts = strsplit(variables{i}, '_');
                    region = data.(sprintf('%s_region_%s',parts{1}, parts{2})){1};
                    fname = sprintf('%s-photometry-%s.npy', file_name, region);
                else
                    fname = sprintf('%s-pupil_area.npy', file_name);
                end
            % outcomes and responses
            elseif contains(variables{i}, 'outcome')
                mat = nan(1,length(x));
                for j = 1:length(outcomes)
                    mat(x == outcomes(j)) = j;
                end
                fname = sprintf('%s-%s.npy', file_name, variables{i});
            else
                mat = x;
                fname = sprintf('%s-%s.npy', file_name, variables{i});
            end
            writeNPY(mat, fname); % writes one npy file per variable
        end
    end
end 