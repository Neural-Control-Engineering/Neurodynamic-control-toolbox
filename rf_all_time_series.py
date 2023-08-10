import numpy as np 
from matplotlib import pyplot as plt 
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier

mPFC = np.load('all_NE_mpfc_s1-photometry-R-mPFC-NE.npy')
som = np.load('all_NE_mpfc_s1-photometry-R-S1-NE.npy')
pupil_area = np.load('all_NE_mpfc_s1-pupil_area.npy')
response = np.load('all_NE_mpfc_s1-go_nogo.npy')

matrix = np.hstack((mPFC, som, pupil_area, response))

X = np.array([row[:-1] for row in matrix])
y = matrix[:,-1]

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.5, random_state=42, shuffle=True)

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