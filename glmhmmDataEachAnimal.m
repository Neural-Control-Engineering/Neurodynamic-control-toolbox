data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);

if ~exist('NT-GLM-HMM/animal_data/', 'dir')
    mkdir('NT-GLM-HMM/animal_data/')
end

for a = 1:length(animals)
    animal = num2str(animals(a));
    tmp = filterTrials(data, 'animal', animal);
    version = 'spon_photo_pupil_v2';
    genHmmGlmData(tmp, sprintf('NT-GLM-HMM/animal_data/%s_%s.mat',animal,version), version)
end
