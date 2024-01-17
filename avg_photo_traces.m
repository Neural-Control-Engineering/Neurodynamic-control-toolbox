function [ch1mat, ch2mat, time] = avg_photo_traces(data, tbounds, alignTo, ver)
    % generates averages of photometry traces 
    if ~exist('alignTo', 'var')
        starts = data.stimulus_time;
    elseif strcmp(alignTo, 'stimulus')
        starts = data.stimulus_time;
    elseif strcmp(alignTo, 'response')
        starts = data.stimulus_time + data.response_time;
        data(isnan(starts),:) = [];
        starts = starts(~isnan(starts));
    else
        starts = data.stimulus_time;
    end

    time = tbounds(1):(1/120):tbounds(2);
    ch1mat = nan(size(data,1), length(time));
    ch2mat = ch1mat;
    pre = -tbounds(1);
    post = tbounds(2);

    for i = 1:size(data,1)
        
        stimTime = starts(i);
        if strcmp(ver, 'zscore')
            ch1 = data.photometry_ch1{i,1};
            ch2 = data.photometry_ch2{i,1};
        else
            ch1 = data.channel_1_photo_5hzLP_zscore{i,1};
            ch2 = data.channel_2_photo_5hzLP_zscore{i,1};
        end
        notLarger = (ch1(:,1)-(stimTime))<0;
        validIndices = find(notLarger);
        stimIndex = validIndices(end);
        segIndexStart = stimIndex-(pre*120);
        segIndexStop = stimIndex+(post*120);

        try
            ch1seg = ch1(segIndexStart:segIndexStop,:);
            ch2seg = ch2(segIndexStart:segIndexStop,:);
            ch1mat(i,:) = ch1seg(:,2);
            ch2mat(i,:) = ch2seg(:,2);
        catch 
            ch1seg = ch1(segIndexStart:end,:);
            ch2seg = ch2(segIndexStart:end,:);
            ch1mat(i,1:size(ch1seg,1)) = ch1seg(:,2);
            ch2mat(i,1:size(ch2seg,1)) = ch2seg(:,2);
        end

    end
end
% function [ch1mat, ch2mat, time] = avg_photo_traces(data, tbounds, alignTo)
%     % generates averages of photometry traces 
%     if ~exist('alignTo', 'var')
%         starts = data.stimulus_time;
%     elseif strcmp(alignTo, 'stimulus')
%         starts = data.stimulus_time;
%     elseif strcmp(alignTo, 'response')
%         starts = data.stimulus_time + data.response_time;
%         data(isnan(starts),:) = [];
%         starts = starts(~isnan(starts));
%     else
%         starts = data.stimulus_time;
%     end
%     Fss = getFs(data, 'photometry_ch1');
%     ch1mat = nan(size(data,1), round(max(Fss)*diff(tbounds)));
%     ch2mat = ch1mat;
%     time = linspace(tbounds(1), tbounds(2), round(max(Fss)*diff(tbounds)));

%     for i = 1:size(data,1)
%         t = data.photometry_ch1{i,1}(:,1) - starts(i);
%         ch1 = data.photometry_ch1{i,1}(:,2);
%         ch2 = data.photometry_ch2{i,1}(:,2);
%         ch1 = ch1(t > tbounds(1) & t < tbounds(2));
%         ch2 = ch2(t > tbounds(1) & t < tbounds(2));
%         t = t(t > tbounds(1) & t < tbounds(2));
%         % using interp1 to avoid issues with differing sample rates
%         % ch1mat(i,:) = interp1(t, ch1, time);
%         % ch2mat(i,:) = interp1(t, ch2, time);
%         try
%             ch1mat(i,:) = ch1;
%             ch2mat(i,:) = ch2;
%         catch
%             ch1mat(i,1:length(ch1)) = ch1;
%             ch2mat(i,1:length(ch2)) = ch2;
%         end
%     end
% end