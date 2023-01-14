from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
from sklearn.tree import export_text
import pandas as pd
import numpy as np

final_df = pd.read_csv('final_df.csv')
final_df = final_df.iloc[:,1:]
#sales is avg of all sales per year so keep that and drop sales_year_1
#drop other columns that are useless and facility size has 95 % values 0
# get dummies for minority_owned_indicator and ZIP
final_df = pd.get_dummies(final_df, columns = ['minority_owned_indicator','ZIP'], drop_first = True)
final_df.shape

# split into train test sets
X = final_df.drop(columns=['Business_Category'])
Y = final_df['Business_Category']
X_train, X_test, y_train, y_test = train_test_split(X, Y,test_size = 0.2,stratify=Y)
X_test_acc = X_test.drop(columns=['latitude','longtitude'])
X_train = X_train.drop(columns=['latitude','longtitude'])

model = RandomForestClassifier(random_state=1,max_depth = 100, min_samples_split = 10)
model.fit(X_train, y_train)
# make predictions
yhat = model.predict(X_test_acc)
# evaluate predictions
acc = accuracy_score(y_test, yhat)
print('Accuracy for prediction to be correct : %.3f' % acc)

probs = model.predict_proba(X_test_acc)
predictions = model.classes_[np.argsort(probs)[:,9:6:-1]]

coll = []
for i in range(y_test.shape[0]):
    if y_test.iloc[i] in (predictions[i]):
        coll.append(1)
    else:
        coll.append(0)
coll = pd.Series(coll)
accuracy = coll[coll==1].shape[0]/coll.shape[0]
print('Accuracy for prediction to be in top 3 : %.3f' % accuracy)

X_test.to_csv("data.csv")

with open("model.txt", "w") as file:
    for tree in model.estimators_:
        file.write(export_text(tree, max_depth=10000, feature_names=list(X_train.columns)))
        file.write("septree\n")
