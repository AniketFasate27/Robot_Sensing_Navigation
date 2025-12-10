function model = train_random_forest(features_data)
% TRAIN_RANDOM_FOREST
% Trains a Random Forest classifier (Quick version)

X = features_data.features;
y = features_data.labels;

cv = cvpartition(y, 'HoldOut', 0.2);
X_train = X(training(cv), :);
y_train = y(training(cv));

[X_train_scaled, ~, ~] = zscore(X_train);

model = TreeBagger(100, X_train_scaled, y_train, 'Method', 'classification');

fprintf('Random Forest trained: %d trees\n', model.NumTrees);

end