data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
% data(cellfun(@isempty, data.photometry_ch1),:) = [];

% outdir = 'NT-GLM-HMM/animal_data_v1/';
% if ~exist(outdir, 'dir')
%     mkdir(outdir)
% end

% for a = 1:length(animals)
%     animal = num2str(animals(a));
%     tmp = filterTrials(data, 'animal', animal);
%     version = 'spon_photo_pupil_v2';
%     genHmmGlmData(tmp, sprintf('%s%s_%s.mat', outdir, animal, version), version, false, 1)
% end

N_shuffles = 10;
for n = 1:N_shuffles
    outdir = sprintf('NT-GLM-HMM/shuffles_phys/shuffle_%i/', n);
    if ~exist(outdir, 'dir')
        mkdir(outdir)
    end
    
    for a = 1:length(animals)
        animal = num2str(animals(a));
        tmp = filterTrials(data, 'animal', animal);
        version = 'spon_photo_pupil_v2';
        genHmmGlmData(tmp, sprintf('%s%s_%s.mat', outdir, animal, version), version, true, n)
    end
end

