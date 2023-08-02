
path_old_SSD = setPaths("Project_Somatosensory-Signal-Detection");
path_new_NtExp = setPaths("Project_Neurotransmitter-Exploration");
path_pupil_thalm = setPaths("Project_Thalamic-Pupil-Synchronization");
behavior_files = dir(fullfile(path_old_SSD.raw_behavior_data,'*.mat'));
%test_output = 'D:\temp';
%example_meta = load(fullfile(path_new_NtExp.behavior_meta_data,"243-R-mPFC-S1-NE_2022_12_29_18_29.mat"));
for i = 1:numel(behavior_files)
    meta_data = dir(fullfile(path_old_SSD.behavior_meta_data,'*.mat'));
    meta_data_files = {meta_data.name};
    if contains(behavior_files(i).name,meta_data_files)
        continue
    end
    behavior_data = load(fullfile(behavior_files(i).folder,behavior_files(i).name));
    session_time = behavior_data.Data.Tones.data(end,7);
    
    % create empty meta structure with same elements
    experimental_details = struct;
    experimental_details.pupil.pupil_fs = 0;
    experimental_details.whisker.whisker_fs = 0;
    experimental_details.photometry.photometry_fs = 0;
    experimental_details.photometry.decimation_factor = 0;
    experimental_details.photometry.channel_1_region = 'N/A';
    experimental_details.photometry.channel_2_region = 'N/A';
    experimental_details.manipulation.optogenetic_manipulation = 'N/A';
    experimental_details.manipulation.chemogenetic_manipulation = 'N/A';
    experimental_details.manipulation.chemogenetic_dose = 'N/A';

    %get pupil fs
    index_dash = strfind(behavior_files(i).name,'_');
    % change the date from yyyy_mm_dd to mmddyyyy format
    date_format_video = strcat( ...
    behavior_files(i).name(index_dash(2)+1:index_dash(3)-1), ...
    behavior_files(i).name(index_dash(3)+1:index_dash(4)-1), ...
    behavior_files(i).name(index_dash(1)+1:index_dash(2)-1));
    pupil_video_temp = dir(fullfile(path_old_SSD.raw_pupil_data, ...
        strcat('*',behavior_files(i).name(1:index_dash(1)-1), ...
        '*',date_format_video,'*')));
    %
    if numel(pupil_video_temp) == 1
        try
            pupil_vidObj = VideoReader(fullfile(pupil_video_temp(1).folder,pupil_video_temp(1).name)); %#ok<TNMLP> 
            pupil_numFrames = pupil_vidObj.NumFrames; 
            % round to interger
            pupil_fs = round(pupil_numFrames/session_time);
            experimental_details.pupil.pupil_fs = pupil_fs;
            frame_lost = pupil_fs*session_time-pupil_numFrames;
            if abs(frame_lost) > 1
                experimental_details.pupil.frame_lost = frame_lost;
            end
        catch
            experimental_details.pupil.pupil_fs = 'N/A';
            warning(strcat('Pupil video is broken for ', behavior_files(i).name))
        end
    elseif numel(pupil_video_temp) == 0
        experimental_details.pupil.pupil_fs = 'N/A';
        warning(strcat('No pupil video found for ', behavior_files(i).name))
    elseif numel(pupil_video_temp) > 1
        experimental_details.pupil.pupil_fs = 'N/A';
        warning(strcat('Multiuple pupil video found for ', behavior_files(i).name))
    end
    clear pupil_vidObj
    
    whisker_video_temp = dir(fullfile(path_old_SSD.raw_whisker_data, ...
        strcat('*',behavior_files(i).name(1:index_dash(1)-1), ...
        '*',date_format_video,'*')));
    %
    if numel(whisker_video_temp) == 1
        try
            whisker_vidObj = VideoReader(fullfile(whisker_video_temp(1).folder,whisker_video_temp(1).name)); %#ok<TNMLP> 
            whisker_numFrames = whisker_vidObj.NumFrames; 
            % round to tens digit
            whisker_fs = round(whisker_numFrames/session_time,-1);
            frame_lost = whisker_fs*session_time-whisker_numFrames;
            experimental_details.whisker.whisker_fs = whisker_fs;
            if abs(frame_lost) > 1
                experimental_details.whisker.frame_lost = frame_lost;
            end
        catch
            experimental_details.whisker.whisker_fs = 'N/A';
            warning(strcat('Whisker video is broken for ', behavior_files(i).name))
        end
    elseif numel(whisker_video_temp) == 0
        experimental_details.whisker.whisker_fs = 'N/A';
        warning(strcat('No whisker video found for ', behavior_files(i).name))
    elseif numel(whisker_video_temp) > 1
        experimental_details.whisker.whisker_fs = 'N/A';
        warning(strcat('Multiuple whisker video found for ', behavior_files(i).name))
    end
    clear whisker_vidObj

    yyyy = str2double(behavior_files(i).name(index_dash(1)+1:index_dash(2)-1));
    mm = str2double(behavior_files(i).name(index_dash(2)+1:index_dash(3)-1));
    dd = str2double(behavior_files(i).name(index_dash(3)+1:index_dash(4)-1));
    % After 2022_02_04, use doric methods to collect photometry, before that
    % pyphotometry is used
    
    if (yyyy*365+mm*30+dd) >= (2022*365+2*30+4)
        % get sampling rate by doric method
        index_dash = strfind(behavior_files(i).name,'_');
        photometry_temp = dir(fullfile(path_old_SSD.raw_photometry_data, ...
            strcat('*',behavior_files(i).name(1:index_dash(4)-1), ...
            '*')));
        if not(isempty(photometry_temp))
            photometry_data = readtable(fullfile(photometry_temp(1).folder,photometry_temp(1).name), ...
                'ReadVariableNames',false);
    
            % Due to inconsistant sampling rate, here we round to the first
            % dignificant digit to estimate the decimation_factor while for
            % doric system the sampling rate is fixed as 12000
            numSamples = sum(photometry_data{:,8} == 1);
            decimation_factor = round(12000/numSamples*session_time,1,"significant");
    
            experimental_details.photometry.photometry_fs = 12000;
            experimental_details.photometry.decimation_factor = decimation_factor;
        else
            experimental_details.photometry.photometry_fs = 'N/A';
            experimental_details.photometry.decimation_factor = 'N/A';
            warning(strcat('No photometry file found for ', behavior_files(i).name))
        end
        area_list = {'mPFC','S1','VPM','dSTR','BF'};
        injection_list = {'ACh','NE','DA','5HT','GCamp','hm4D','A1aAR-KO','Npxl'};
        channel1_avalable = true;

        for j = 1:numel(area_list)
            if contains(behavior_files(i).name, area_list{j}, IgnoreCase=true)
                % Find any brain area mentioned above, then find the first
                % injection type after it from the injection list
                index_temp = strfind(lower(behavior_files(i).name),lower(area_list{j}));
                injection_indice = zeros(size(injection_list))+100;
                for k = 1:numel(injection_list)
                    temp_index = strfind(lower(behavior_files(i).name(index_temp:end)),lower(injection_list{k}));
                    if not(isempty(temp_index))
                        injection_indice(k) = temp_index(1);
                    end
                end
                [~,closest_injection] = min(injection_indice);
                injection_type = injection_list{closest_injection};
                channel_list = {'ACh','NE','DA','5HT','GCamp'};
                chemo_list = {'hm4D'};
                other_list = {'A1aAR-KO','Npxl'};
                if contains(injection_type,channel_list, IgnoreCase=true)
                    if channel1_avalable
                        experimental_details.photometry.channel_1_region = strcat( ...
                            'R-',area_list{j},'-',injection_type);
                        channel1_avalable = false;
                    else
                        experimental_details.photometry.channel_2_region = strcat( ...
                            'R-',area_list{j},'-',injection_type);
                    end
                elseif contains(injection_type,chemo_list, IgnoreCase=true)
                    if contains(behavior_files(i).name,'Saline', IgnoreCase=true)
                        experimental_details.manipulation.chemogenetic_manipulation = 'Saline';
                        experimental_details.manipulation.chemogenetic_dose = 'N/A';
                    elseif contains(behavior_files(i).name,'Ctrl', IgnoreCase=true)
                        experimental_details.manipulation.chemogenetic_manipulation = 'Saline';
                        experimental_details.manipulation.chemogenetic_dose = 'N/A';
                    elseif contains(behavior_files(i).name,'JHU', IgnoreCase=true)
                        % Since the information about JHU dose are only recorded on
                        % notion experiment notes, I explicitly assign each day the
                        % dose value based on mouse ID and training date
                        mice_10X_JHU = {'8012-','8013-','3257-','3258-'};
                        mice_5X_JHU = {'8080-'};
                        mice_XX_JHU = {'8083-'};
                        experimental_details.manipulation.chemogenetic_manipulation = 'JHU';
                        if contains(behavior_files(i).name, mice_10X_JHU, IgnoreCase=true)
                            experimental_details.manipulation.chemogenetic_dose = '1';
                        elseif contains(behavior_files(i).name, mice_5X_JHU, IgnoreCase=true)
                            experimental_details.manipulation.chemogenetic_dose = '0.5';
                        elseif contains(behavior_files(i).name, mice_XX_JHU, IgnoreCase=true)
                            if (yyyy*365+mm*30+dd) >= (2022*365+5*30+5)
                                experimental_details.manipulation.chemogenetic_dose = '1';
                            else
                                experimental_details.manipulation.chemogenetic_dose = '0.5';
                            end
                        end
                    end
                elseif contains(injection_type, other_list, IgnoreCase=true)
                    experimental_details.manipulation.other = strcat( ...
                            'R-',area_list{j},'-',injection_type);
                end
            end
        end
    else
        date_format_pyphotometry = strcat( ...
            behavior_files(i).name(index_dash(1)+1:index_dash(2)-1),'-', ...
            behavior_files(i).name(index_dash(2)+1:index_dash(3)-1),'-', ...
            behavior_files(i).name(index_dash(3)+1:index_dash(4)-1));
        photometry_temp = dir(fullfile(path_old_SSD.raw_photometry_data, ...
            strcat('*',behavior_files(i).name(1:index_dash(1)-1), ...
            '*',date_format_pyphotometry,'*')));
        if not(isempty(photometry_temp))
            photometry_data = readtable(fullfile(photometry_temp(1).folder,photometry_temp(1).name), ...
                'ReadVariableNames',false);
            numSamples = sum(photometry_data{:,4} == 1);
            photometry_fs = round(numSamples/session_time);
    
            experimental_details.photometry.decimation_factor = 'N/A';
            experimental_details.photometry.system = 'PyPhotometry';
            experimental_details.photometry.photometry_fs = photometry_fs;
        else
            experimental_details.photometry.photometry_fs = 'N/A';
            experimental_details.photometry.decimation_factor = 'N/A';
            warning(strcat('No photometry file found for ', behavior_files(i).name))
        end
        % PyPhotometry has but one channel, and all SSD animal after
        % Nov2021 are implanted at right hemisphere
        index_hyphen = strfind(behavior_files(i).name,'-');
        region1 = strcat('R-',behavior_files(i).name(index_hyphen(1)+1:index_dash-1));
        experimental_details.photometry.channel_1_region = region1;
        experimental_details.photometry.channel_2_region = 'N/A';

        experimental_details.manipulation.optogenetic_manipulation = 'N/A';
        experimental_details.manipulation.chemogenetic_manipulation = 'N/A';
        experimental_details.manipulation.chemogenetic_dose = 'N/A';
    end
    clear photometry_temp

    save(fullfile(path_old_SSD.behavior_meta_data,behavior_files(i).name),'experimental_details')
    disp(strcat(num2str(100*i/numel(behavior_files)),'%'))
end

% aaa = load(fullfile(path_new_NtExp.behavior_meta_data,"243-R-mPFC-S1-NE_2022_12_29_18_29.mat"));
% bbb = load(fullfile(test_output,behavior_files(i).name));





