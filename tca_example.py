import numpy as np 
import tensortools as tt 
from matplotlib import pyplot as plt 
from scipy.signal import decimate 

## load files for single session 
mpfc = np.load('example_ssd2-photometry-R-mPFC(PL5)-NE.npy')
s1 = np.load('example_ssd2-photometry-R-S1-NE.npy')
pupil = np.load('example_ssd2-pupil_area.npy')

## further normalize data - doesn't help
# mpfc = mpfc * (1/(2*np.abs(np.max(mpfc))))
# s1 = s1 * (1/(2*np.abs(np.max(s1))))
# pupil = pupil * (1/(2*np.abs(np.max(pupil))))

## stick data into tensor 
data = np.empty((3,pupil.shape[1], pupil.shape[0]))
data[0,:,:] = decimate(mpfc, 12, axis=1).transpose()
data[1,:,:] = decimate(s1, 12, axis=1).transpose()
data[2,:,:] = pupil.transpose()
print('Any NaNs in data: %s' % np.any(np.isnan(data)))
print('Max of data: %s' % np.max(data))
print('Min of data: %s' % np.min(data))
print('Data shape: %s' % str(data.shape))

## dummy tensor with random entries
dummy = np.random.rand(data.shape[0], data.shape[1], data.shape[2])
## center dummy tensor to zero - still works
# dummy = (dummy - 0.5) 
print('Max of dummy: %s' % np.max(dummy))
print('Min of dummy: %s' % np.min(dummy))
print('Dummy shape: %s' % str(dummy.shape))

## fit dummy tensor 
print('Running tensor fit for dummy\n#########################')
dummy_ensemble = tt.Ensemble(fit_method="ncp_hals")
dummy_ensemble.fit(dummy, ranks=range(1,3), replicates=4)

## fit for real data
print('\nRunning tensor fit for data\n#########################')
data_ensemble = tt.Ensemble(fit_method="ncp_hals")
data_ensemble.fit(data, ranks=range(1,3), replicates=4)