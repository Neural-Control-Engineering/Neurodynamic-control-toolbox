data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
data(cellfun(@isempty, data.photometry_ch1),:) = [];

if ~exist('NT-GLM-HMM/animal_data_v1/', 'dir')
    mkdir('NT-GLM-HMM/animal_data_v1/')
end

for a = 1:length(animals)
    animal = num2str(animals(a));
    tmp = filterTrials(data, 'animal', animal);
    version = 'spon_photo_pupil_v2';
    genHmmGlmData(tmp, sprintf('NT-GLM-HMM/animal_data_v1/%s_%s.mat',animal,version), version)
end
