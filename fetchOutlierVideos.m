function fetchOutlierVideos(paths)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

% Pupil
load(fullfile(paths.raw_pupil_data,"pupil_extraction_log.mat"),"pupil_extraction_log");

temp = table2array(pupil_extraction_log(pupil_extraction_log{:,3}==false & pupil_extraction_log{:,4}~=0,1));

outlier_extraction_list = strings(length(temp),1);

for i = 1:length(temp)
    outlier_extraction_list(i) = strcat("r'/mnt/g/My Drive/#Projects/Project_Neurotransmitter-Exploration/Raw Pupil Data/",temp{i},"'");
end

writematrix(outlier_extraction_list,fullfile(paths.raw_pupil_data,"outlier_extraction_list.txt"),'Delimiter',',');

% Whisker
load(fullfile(paths.raw_whisker_data,"whisker_extraction_log.mat"),"whisker_extraction_log");

temp = table2array(whisker_extraction_log(whisker_extraction_log{:,3}==false & whisker_extraction_log{:,4}~=0,1));

outlier_extraction_list = strings(length(temp),1);

for i = 1:length(temp)
    outlier_extraction_list(i) = strcat("r'/mnt/g/My Drive/#Projects/Project_Neurotransmitter-Exploration/Raw Whisker Data/",temp{i},"'");
end

writematrix(outlier_extraction_list,fullfile(paths.raw_whisker_data,"outlier_extraction_list.txt"),'Delimiter',',');

end