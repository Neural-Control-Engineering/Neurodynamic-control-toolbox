import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from scipy.signal import welch

# Feature extraction functions and other necessary utilities
def zero_crossings(x):
    return ((x[:-1] * x[1:]) < 0).sum()

def psd(x, Fs=100):
    f, Pxx_den = welch(x, fs=Fs)
    return f, Pxx_den

def get_simplified_features(x, wamp_threshold=0.01):
    abs_x = np.abs(x)
    len_x = len(x)

    IEMG = np.sum(abs_x)
    MAV = np.mean(abs_x)
    SSI = np.sum(x**2)
    VAR = np.var(x)
    RMS = np.sqrt(np.mean(x**2))
    WL = np.sum(np.abs(np.diff(x)))
    ZC = zero_crossings(x)
    SSC = np.where(np.diff(np.sign(np.diff(x))))[0].shape[0]
    WAMP = np.sum(np.abs(np.diff(x)) > wamp_threshold)

    f, Pxx_den = psd(x, Fs=fs)
    FMD = np.sum(f * Pxx_den) / np.sum(Pxx_den)
    FMM = np.max(Pxx_den)
    CF = np.sum(Pxx_den * f**2) / np.sum(Pxx_den)
    
    IASD = np.sum(np.diff(abs_x, 2))
    IATD = np.sum(np.diff(abs_x, 3))
    IEAV = np.sum(np.exp(abs_x))
    IE = np.sum(np.exp(x))

    return np.array([IEMG, MAV, SSI, RMS, VAR, WL, ZC, SSC, WAMP, FMD, FMM, CF, IASD, IATD, IEAV, IE])

# Load the data
matrix = np.load(r"C:\Users\Gabog\Downloads\NE_dstore.npy")
fs = 100
go_data = matrix[matrix[:, -1] == 1, :-1]
no_go_data = matrix[matrix[:, -1] == 0, :-1]

# Feature extraction
features_go = np.array([get_simplified_features(trial) for trial in go_data])
features_no_go = np.array([get_simplified_features(trial) for trial in no_go_data])

# Combining the data and labels
all_features = np.vstack([features_go, features_no_go])
all_labels = np.concatenate([np.ones(len(features_go)), np.zeros(len(features_no_go))])

# Creating a DataFrame for visualization
df = pd.DataFrame(all_features, columns=[
    'IEMG', 'MAV', 'SSI', 'RMS', 'VAR', 'WL', 'ZC', 'SSC', 'WAMP', 'FMD', 'FMM', 'CF', 'IASD', 'IATD', 'IEAV', 'IE'
])
df['label'] = all_labels

# Generating the scatter plot matrix
sns.pairplot(df, hue='label', diag_kind="kde", markers=["o", "s"], palette="muted")
plt.show()


# import numpy as np
# from sklearn.model_selection import train_test_split
# from sklearn.ensemble import RandomForestClassifier
# from scipy.stats import skew, kurtosis

# # Load the data
# matrix = np.load(r"C:\Users\Gabog\Downloads\NE_dstore.npy")

# from scipy.stats import skew, kurtosis
# from scipy.signal import find_peaks
# import numpy as np

# def sample_entropy(U, m, r):
#     def _maxdist(x_i, x_j):
#         return max([abs(ua - va) for ua, va in zip(x_i, x_j)])

#     def _phi(m):
#         x = np.array([U[j] for j in range(len(U) - m + 1)])
#         C = [len([1 for x_j in x if _maxdist(x_i, x_j) <= r]) / (len(U) - m) for x_i in x]
#         return sum(C) / (len(U) - m)

#     return -np.log(_phi(m + 1) / _phi(m))

# def hjorth_params(x):
#     diff_input = np.diff(x)
#     diff_diff_input = np.diff(diff_input)

#     activity = np.var(x)
#     mobility = np.sqrt(np.var(diff_input) / activity)
#     complexity = np.sqrt(np.var(diff_diff_input) / np.var(diff_input) - mobility)
    
#     return activity, mobility, complexity

# def get_comprehensive_features(x):
#     x = x - np.mean(x)
#     abs_x = np.abs(x)
#     len_x = len(x)
#     IEMG = np.sum(abs_x)
#     MAV = IEMG/len_x
#     SSI = np.sum(np.square(x))
#     RMS = np.sqrt((1/len_x)*SSI)
#     VAR = np.var(x)
#     WL = np.sum(np.array([np.abs(x[i+1] - x[i]) for i in range(len_x-1)]))
#     DAMV = (1/(len_x-1))*WL
#     M2 = np.sum(np.array([np.square(x[i+1] - x[i]) for i in range(len_x-1)]))
#     DVARV = (1/(len_x-2))*M2
#     DASDV = np.sqrt((1/(len_x-1))*DVARV)
#     MAX = np.max(x)
#     MIN = np.min(x)
#     IASD = np.sum(np.diff(abs_x, 2))
#     IATD = np.sum(np.diff(abs_x, 3))
#     IEAV = np.sum(np.exp(abs_x))
#     IE = np.sum(np.exp(x))
#     SKEW = skew(x)
#     KURT = kurtosis(x, fisher=False)

#     ZCR = ((x[:-1] * x[1:]) < 0).sum()
#     SSC = len(np.where(np.diff(np.sign(np.diff(x))))[0])
#     # SampE = sample_entropy(x, m=2, r=0.2*np.std(x))
#     activity, mobility, complexity = hjorth_params(x)
    
#     ret = np.array((IEMG, MAV, SSI, RMS, VAR, WL, DAMV, M2, DVARV, DASDV, MAX, MIN, IASD, IATD, IEAV, IE, SKEW, KURT,
#                     ZCR, SSC, activity, mobility, complexity))
#     return ret


# # Extract basic features
# def get_features(x):
#     x = x - np.mean(x)
#     abs_x = np.abs(x)
#     len_x = len(x)
#     IEMG = np.sum(abs_x)
#     MAV = IEMG/len_x
#     SSI = np.sum(np.square(x))
#     RMS = np.sqrt((1/len_x)*SSI)
#     VAR = np.var(x)
#     #no MYOP bc idk wanna set threshold
#     WL = np.sum(np.array([np.abs(x[i+1] - x[i]) for i in range(len_x-1)]))
#     DAMV = (1/(len_x-1))*WL
#     M2 = np.sum(np.array([np.square(x[i+1] - x[i]) for i in range(len_x-1)]))
#     DVARV = (1/(len_x-2))*M2
#     DASDV = np.sqrt((1/(len_x-1))*DVARV)
#     MAX = np.max(x)
#     MIN = np.min(x)
#     IASD = np.sum(np.diff(abs_x, 2))
#     IATD = np.sum(np.diff(abs_x, 3))
#     IEAV = np.sum(np.exp(abs_x))
#     IE = np.sum(np.exp(x))
#     SKEW = skew(x)
#     KURT = kurtosis(x, fisher=False)
    
#     ret = np.array((IEMG, MAV, SSI, RMS, VAR, WL, DAMV, M2, DVARV, DASDV, MAX, MIN, IASD, IATD, IEAV, IE, SKEW, KURT))
#     return ret

# for i in range(len(matrix[:, 0])):
#     matrix[i, :-1] = matrix[i, :-1] - np.mean(matrix[i, :-1])

# X = np.array([row[:-1] for row in matrix])
# y = matrix[:, -1]

# # Split the data into training (80%) and testing (20%) sets with shuffling
# X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.5, random_state=42, shuffle=True)

# # Initialize and train the Random Forest with default parameters on the training set
# clf = RandomForestClassifier(random_state=42)
# clf.fit(X_train, y_train)

# # Evaluate the model on both the training and test sets
# train_predictions = clf.predict(X_train)
# train_accuracy = np.mean(train_predictions == y_train)

# test_predictions = clf.predict(X_test)
# test_accuracy = np.mean(test_predictions == y_test)

# print("Training Accuracy:", train_accuracy)
# print("Test Accuracy:", test_accuracy)

# import matplotlib.pyplot as plt

# # Feature names for the basic features
# feature_names = ['IEMG', 'MAV', 'SSI', 'RMS', 'VAR', 'WL', 'DAMV', 'M2', 'DVARV', 'DASDV', 'MAX', 'MIN', 'IASD', 'IATD', 'IEAV', 'IE', 'SKEW', 'KURT',
#                     'ZCR', 'SSC', 'activity', 'mobility', 'complexity']
# #['IEMG', 'MAV', 'SSI', 'RMS', 'VAR', 'WL', 'DAMV', 'M2', 'DVARV', 'DASDV', 'MAX', 'MIN', 'IASD', 'IATD', 'IEAV', 'IE']

# # Extract feature importances from the trained Random Forest model
# importances = clf.feature_importances_

# # Pair the feature names with their importance values
# feature_importance = list(zip(feature_names, importances))

# # Sort features by importance
# sorted_feature_importance = sorted(feature_importance, key=lambda x: x[1], reverse=True)

# # Separate the features and their importance values for visualization
# features, importance_values = zip(*sorted_feature_importance)

# # Visualize using a bar chart
# plt.figure(figsize=(10,6))
# plt.bar(features, importance_values, align='center')
# plt.xlabel('Features')
# plt.ylabel('Importance')
# plt.title('Feature Importance using Random Forest')
# plt.show()


