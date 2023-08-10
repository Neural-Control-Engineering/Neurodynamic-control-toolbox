"""Based on Gabe's NDC-RFtrainer.py script.  Here using features from all times
time series data collected, rather than just a single channel of photometry data.
Craig Kelley, NEC Lab, 8/10/23"""

import numpy as np 
from matplotlib import pyplot as plt 
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from scipy.stats import skew, kurtosis

def get_features(x):
    x = x - np.mean(x)
    abs_x = np.abs(x)
    len_x = len(x)
    IEMG = np.sum(abs_x)
    MAV = IEMG/len_x
    SSI = np.sum(np.square(x))
    RMS = np.sqrt((1/len_x)*SSI)
    VAR = np.var(x)
    #no MYOP bc idk wanna set threshold
    WL = np.sum(np.array([np.abs(x[i+1] - x[i]) for i in range(len_x-1)]))
    DAMV = (1/(len_x-1))*WL
    M2 = np.sum(np.array([np.square(x[i+1] - x[i]) for i in range(len_x-1)]))
    DVARV = (1/(len_x-2))*M2
    DASDV = np.sqrt((1/(len_x-1))*DVARV)
    MAX = np.max(x)
    MIN = np.min(x)
    IASD = np.sum(np.diff(abs_x, 2))
    IATD = np.sum(np.diff(abs_x, 3))
    IEAV = np.sum(np.exp(abs_x))
    IE = np.sum(np.exp(x))
    SKEW = skew(x)
    KURT = kurtosis(x, fisher=False)
    
    ret = np.array((IEMG, MAV, SSI, RMS, VAR, WL, DAMV, M2, DVARV, DASDV, MAX, MIN, IASD, IATD, IEAV, IE, SKEW, KURT))
    return ret

mPFC = np.load('all_NE_mpfc_s1-photometry-R-mPFC-NE.npy')
som = np.load('all_NE_mpfc_s1-photometry-R-S1-NE.npy')
pupil_area = np.load('all_NE_mpfc_s1-pupil_area.npy') # one of the features for pupil area was ~10e48 => too big
response = np.load('all_NE_mpfc_s1-go_nogo.npy')

mPFC_features = np.array([get_features(row) for row in mPFC])
som_features = np.array([get_features(row) for row in som])
pupil_features = np.array([get_features(row) for row in pupil_area])

X = np.hstack((mPFC_features, som_features))
y = response

X_train, X_test, y_train, y_test = train_test_split(X, y.ravel(), test_size=0.5, random_state=42, shuffle=True)

# Initialize and train the Random Forest with default parameters on the training set
clf = RandomForestClassifier(random_state=42)
clf.fit(X_train, y_train)

# Evaluate the model on both the training and test sets
train_predictions = clf.predict(X_train)
train_accuracy = np.mean(train_predictions == y_train)

test_predictions = clf.predict(X_test)
test_accuracy = np.mean(test_predictions == y_test)

print("Training Accuracy:", train_accuracy)
print("Test Accuracy:", test_accuracy)