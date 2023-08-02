function [photometry_matrix] = Dstore_generate_photometry_matrix(stim_time,photometry,time_range)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% photometry = all_r1_photometry;
% stim_time = all_stim_time;
% time_range = [-2,5];
time_star = time_range(1);
time_end = time_range(2);
photometry_matrix = zeros(numel(stim_time),(time_end-time_star)*120+1);
for i =  1:numel(stim_time)
    if height(photometry{i}) == 0
            continue
    end
    try
        stim_time_this = stim_time{i};
        time_axis = photometry{i}(:,1);
        [~,index_center] = min(abs(time_axis-stim_time_this));
        index_star = index_center+120*time_star;
        index_end = index_center+120*time_end;
    
        photometry_this = photometry{i}(index_star:index_end,2);
        photometry_matrix(i,:) = photometry_this;
    catch
        disp("stop")
    end
end

end