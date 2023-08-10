function sessionToNumpy(data, session_id, tbounds, outdir)
% Generates numpy files for photometry data, pupil area, outcome, 
% and animal response for a single session.  Data are trimmed based 
% on tbounds and npy files are save to outdir.
% Example:  sessionToNump(Datastore.NE_dstore, '151-mPFC-S1-NE_2022_02_12', [-2, 0], 'Analysis/npys/')
% Craig Kelley, NEC Lab, 8/10/23

    data = data(data.session_id == session_id , :);
    if ~exist(outdir, 'dir')
        mkdir(outdir)
    end

    outcomes = ["CR", "Delayed FA (CR)", "FA", "Hit", "Miss", "Near Hit (Miss)"];

    variables = {'photometry_ch1', 'photometry_ch2', 'pupil_area', 'categorical_outcome', 'go_nogo'};
    for i = 1:length(variables)
        x = data.(variables{i});
        if ~isempty(x)
            if contains(variables{i}, 'photometry') || contains(variables{i}, 'pupil_area')
                % trim channel based on tbounds 
                Fs = 1 / (x{1}(2,1) - x{1}(1,1));
                t = linspace(tbounds(1), tbounds(2), Fs*diff(tbounds));
                mat = nan(length(x), length(t));
                for j = 1:length(x)
                    t = x{j}(:,1) - data.stimulus_time(j);
                    ch = x{j}(:,2);
                    ch = ch(t > tbounds(1) & t < tbounds(2));
                    mat(j,:) = ch(1:size(mat,2));
                end
                % determine file name 
                if contains(variables{i}, 'photometry')
                    parts = strsplit(variables{i}, '_');
                    region = data.(sprintf('%s_region_%s',parts{1}, parts{2})){1};
                    fname = sprintf('%s-photometry-%s.npy', session_id, region);
                else
                    fname = sprintf('%s-pupil_area.npy', session_id);
                end
            elseif contains(variables{i}, 'outcome')
                mat = nan(1,length(x));
                for j = 1:length(outcomes)
                    mat(x == outcomes(j)) = j;
                end
                fname = sprintf('%s-%s.npy', session_id, variables{i});
            else
                mat = x;
                fname = sprintf('%s-%s.npy', session_id, variables{i});
            end
            writeNPY(mat, fullfile(outdir,fname));
        end
    end
end 