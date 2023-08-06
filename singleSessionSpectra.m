% setup 
% parpool(4)
data = load('~/somat_signal_detect/Datastores/NE_dstore_cleaned02-Aug-2023.mat');
data = data.NE_dstore;

session_ids = unique(data.session_id);
for i = 1:length(session_ids)
    session_id = session_ids(i);
    fprintf('%s\n', session_id)
    avgFftByOutcome(data, session_id)
end
