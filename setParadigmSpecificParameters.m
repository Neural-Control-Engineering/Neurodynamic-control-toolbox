function [paradigm_params] = setParadigmSpecificParameters(paradigm)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if strcmp(paradigm,"SSD_v2_Phase_0__2022_12_09") || strcmp(paradigm,"SSD_v2_Phase_I__2022_12_09") || strcmp(paradigm,"SSD_v2_Phase_II__2022_12_09") || strcmp(paradigm,"SSD_v2_Phase_III__2022_12_09") || strcmp(paradigm,"SSD_v2_Phase_0__2022_11_04") || strcmp(paradigm,"SSD_Simplified_Phase_III_2022_01_16") || strcmp(paradigm,"SSD_Simplified_Phase_III_20MIN") || strcmp(paradigm, "SSD_Only_Stim_2022_02_17")
    paradigm_params.response_window = 0.8; % 800 ms response window

elseif strcmp(paradigm,"SSD_Simplified_Phase_I_2021_12_23") || strcmp(paradigm,"SSD_Simplified_Phase_II_2021_12_25") || strcmp(paradigm,"SSD_Simplified_Phase_0_2022_09_26")
    paradigm_params.response_window = 0.8;

elseif strcmp(paradigm,"SSD_v2_Phase_0__2022_11_04")
    paradigm_params.response_window = 0.8;

elseif strcmp(paradigm,"NTEX_Phase_II_Early_Late_10ms1s__2022_01_31")
    paradigm_params.response_window = 0.8;

elseif strcmp(paradigm,"NTEX_Npxl_Phase_III__2023_03_13")
    paradigm_params.response_window = 0.8;

elseif strcmp(paradigm,"NTEX_No_Behavior_10ms1s__2023_04_14")
    paradigm_params.response_window = 0.8;

elseif strcmp(paradigm,"VPM_Phase_III__2022_08_08") || strcmp(paradigm,"VPM_Phase_0__2022_08_06")
    paradigm_params.response_window = 0.5;

else
    error(strcat("ERROR: Paradigm specific paramters (such as response window) have not yet been set for ",paradigm))
end