function [paths] = setPaths(source)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% If code is being run from a mac
if ismac
    [~,user] = system('id -F');
    
    % Cody's macbook
    if strcmp(convertCharsToStrings(user(1:end-1)),'Cody Slater') % Right now this is a little strange need to account for a newline at end of mac username
        % Path for analysis code repo
        paths.repo_path = '/Users/codyslater/Documents/GitHub/Neurodyanimcs-control-toolbox';
       
        % Drive letter for raw and analyzed data in customary file structure
        paths.all_data_path = strcat('/Users/codyslater/Library/CloudStorage/GoogleDrive-cs3791@columbia.edu/My Drive/#Projects/',source);
    
    % ADD additional mac users here

    end
    
% If code is being run from a pc    
elseif ispc

    % Cody's primary PC
    if strcmp(getenv("COMPUTERNAME"),'BETADROID') %#ok<BDSCA>
        % Path for analysis code repo
        paths.repo_path = 'B:\GitHub\Neurodyanimcs-control-toolbox';
        paths.scrape_raw_data.behavior_data = "G:\Other computers\Datatron\Raw_Data";
        paths.scrape_raw_data.behavior_metadata = "G:\Other computers\Datatron\Raw_Data_Experimental_Details";
        paths.scrape_raw_data.pupil_data = "G:\Other computers\Datatron\SSD_v2 Raw Pupil Data";
        paths.scrape_raw_data.photometry_data = "G:\Other computers\Einstein\SSD_v2 Raw Photometry Data";
        paths.scrape_raw_data.whisker_data = "G:\Other computers\Optisma\SSD_v2 Raw Whisking Data";

        % Kilosort repository
        paths.neuropixel.kilosort_repo = 'B:\GitHub\Neuropixel_Analysis_Scripts';
        paths.neuropixel.workingdir = 'A:\';
    
        % Drive letter for raw and analyzed data in customary file structure
        paths.all_data_path = strcat('G:\My Drive\#Projects\',source);

    % Cody's lab office PC
    elseif strcmp(getenv("USERNAME"),'TheSingularity') %#ok<BDSCA>
        % Path for analysis code repo
        paths.repo_path = 'C:\Users\TheSingularity\Documents\GitHub\Neurodyanimcs-control-toolbox';
    
        % Drive letter for raw and analyzed data in customary file structure
        paths.all_data_path = strcat('G:\My Drive\#Projects\',source);

        % Kilosort repository
        paths.neuropixel.kilosort_repo = 'C:\Users\TheSingularity\Documents\GitHub\Neuropixel_Analysis_Scripts\Kilosort';
        paths.neuropixel.workingdir = 'C:\';

    % Kunpeng's laptop 
    elseif strcmp(getenv("COMPUTERNAME"),'LAPTOP-AOO4UDIG') %#ok<BDSCA>
        % Path for analysis code repo
        paths.repo_path = 'D:\GitHub\Neurodyanimcs-control-toolbox';
    
        % Drive letter for raw and analyzed data in customary file structure
        paths.all_data_path = strcat('H:\.shortcut-targets-by-id\1yB5u8zHl-aBucQQEQZIgnPdQ1Re2j-5E\',source);
        paths.neuropixel.kilosort_repo = 'B:\GitHub\Neuropixel_Analysis_Scripts';
        paths.neuropixel.workingdir = 'A:\';

    % Gabriel's PC 
    elseif strcmp(getenv("COMPUTERNAME"),'DESKTOP-EI7J5NI') %#ok<BDSCA>
        % Path for analysis code repo
        paths.repo_path = 'C:\Code\Neurodyanimcs-control-toolbox';
    
        % Drive letter for raw and analyzed data in customary file structure
        paths.all_data_path = strcat('G:\.shortcut-targets-by-id\1IEVe17fF9Kk50AdT4RUOVUxy_LJAvmgS\',source);

        paths.neuropixel.kilosort_repo = 'C:\Code\Neuropixel_Analysis_Scripts\Kilosort\';

        % Kilosort repository
        paths.neuropixel.kilosort_repo = 'C:\Code\Neuropixel_Analysis_Scripts\Kilosort';

    % Primus
    elseif strcmp(getenv("COMPUTERNAME"),'DESKTOP-MRI7THQ')
        % Path for analysis code repo
        paths.repo_path = 'C:\Neuromodulation_for_Pain_Analysis';

        % Kilosort repository
        paths.neuropixel.kilosort_repo = 'C:\Neuropixel_Analysis_Scripts\Kilosort';
        paths.neuropixel.workingdir = 'C:\';

        % Drive letter for raw and analyzed data in customary file structure
        paths.all_data_path = strcat('G:\My Drive\#Projects\',source);
        
    % Add additional PCs here:
    
    end
elseif isunix
    if strcmp(getenv('HOSTNAME'), 'lepidus')
        % Path for analysis code repo
        paths.repo_path = '/home/craig/Neurodynamic-control-toolbox/';

        % Path to raw and analyzed data 
        paths.all_data_path = '/home/craig/somat_signal_detect/';
        paths.neuropixel.kilosort_repo = '/home/craig/Kilosort/';
        paths.neuropixel.workingdir = pwd();
    end
end

% Paths for raw data
paths.raw_behavior_data = fullfile(paths.all_data_path,'Raw Behavior Data');
paths.behavior_meta_data = fullfile(paths.all_data_path,'Experiment Metadata');
paths.raw_photometry_data = fullfile(paths.all_data_path,'Raw Photometry Data');
paths.raw_pupil_data = fullfile(paths.all_data_path,'Raw Pupil Data');
paths.raw_whisker_data = fullfile(paths.all_data_path,'Raw Whisker Data');
paths.raw_neuropixel_data = fullfile(paths.all_data_path,'Raw Neuropixel Data');

% Paths for analyzed data
paths.processed_behavior_data = fullfile(paths.all_data_path,'Processed Behavior Data');
paths.processed_photometry_data = fullfile(paths.all_data_path,'Processed Photometry Data');
paths.processed_pupil_data = fullfile(paths.all_data_path,'Processed Pupil Data');
paths.processed_whisker_data = fullfile(paths.all_data_path,'Processed Whisker Data');
paths.processed_neuropixel_data = fullfile(paths.all_data_path,'Processed Neuropixel Data');
paths.datastore = fullfile(paths.all_data_path,"Datastores");

% Store which project data is actively being used
paths.data_source = source;

% Store neuropixel related paths
% paths.neuropixel.kilosort_params = fullfile(paths.raw_neuropixel_data,"Kilosort_params");
% paths.neuropixel.npy = fullfile(paths.neuropixel.kilosort_repo,'npy-matlab-master','npy-matlab');
% paths.neuropixel.config = convertStringsToChars(fullfile(paths.raw_neuropixel_data,'Kilosort_params'));
% 
% setenv("NEUROPIXEL_MAP_FILE",fullfile(paths.neuropixel.config,"neuropixPhase3A_kilosortChanMap.mat"))
% setenv("KILOSORT_CONFIG_FILE",fullfile(paths.neuropixel.config,"StandardConfig.m"))
end