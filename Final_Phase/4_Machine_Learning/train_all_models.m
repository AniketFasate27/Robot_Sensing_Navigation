function ml_results = train_all_models(features_data)
% TRAIN_ALL_MODELS - Toolbox-free version
% Works with basic MATLAB only

fprintf('Training machine learning models (no toolbox version)...\n\n');

%% Load features
X = features_data.features;
y = features_data.labels;

fprintf('Dataset: %d samples, %d features\n', size(X, 1), size(X, 2));
fprintf('Classes: %s\n\n', strjoin(string(categories(y)), ', '));

%% Manual Train/Test Split (80/20)
n_samples = size(X, 1);
n_train = floor(0.8 * n_samples);

rng(42);
idx = randperm(n_samples);

train_idx = idx(1:n_train);
test_idx = idx(n_train+1:end);

X_train = X(train_idx, :);
y_train = y(train_idx);
X_test = X(test_idx, :);
y_test = y(test_idx);

fprintf('Training set: %d samples\n', n_train);
fprintf('Test set: %d samples\n\n', n_samples - n_train);

%% Standardize
mu = mean(X_train);
sigma = std(X_train);
sigma(sigma == 0) = 1;

X_train_scaled = (X_train - mu) ./ sigma;
X_test_scaled = (X_test - mu) ./ sigma;

%% Get class info
classes = categories(y);
n_classes = length(classes);

fprintf('──────────────────────────────────────────────────\n');
fprintf('TRAINING MODELS\n');
fprintf('──────────────────────────────────────────────────\n\n');

%% Model 1: K-Nearest Neighbors
fprintf('1. K-Nearest Neighbors (k=3)... ');

k = 3;
y_pred_knn = cell(length(y_test), 1);

for i = 1:length(y_test)
    test_point = X_test_scaled(i, :);
    distances = sqrt(sum((X_train_scaled - test_point).^2, 2));
    
    [~, nearest_idx] = sort(distances);
    k_nearest = nearest_idx(1:min(k, length(nearest_idx)));
    
    k_labels = y_train(k_nearest);
    
    votes = zeros(n_classes, 1);
    for c = 1:n_classes
        votes(c) = sum(k_labels == classes{c});
    end
    
    [~, winner] = max(votes);
    y_pred_knn{i} = char(classes{winner});
end

y_pred_knn = categorical(y_pred_knn);
accuracy_knn = sum(y_pred_knn == y_test) / length(y_test);
fprintf('✓ (%.0f%%)\n', accuracy_knn * 100);

%% Model 2: Nearest Class Mean
fprintf('2. Nearest Class Mean Classifier... ');

class_means = zeros(n_classes, size(X_train_scaled, 2));
for i = 1:n_classes
    class_idx = (y_train == classes{i});
    if sum(class_idx) > 0
        class_means(i, :) = mean(X_train_scaled(class_idx, :));
    end
end

y_pred_mean = cell(length(y_test), 1);

for i = 1:length(y_test)
    test_point = X_test_scaled(i, :);
    distances = sqrt(sum((class_means - test_point).^2, 2));
    [~, nearest_class] = min(distances);
    y_pred_mean{i} = char(classes{nearest_class});
end

y_pred_mean = categorical(y_pred_mean);
accuracy_mean = sum(y_pred_mean == y_test) / length(y_test);
fprintf('✓ (%.0f%%)\n', accuracy_mean * 100);

%% Model 3: Minimum Distance Classifier
fprintf('3. Minimum Distance Classifier... ');

y_pred_mindist = cell(length(y_test), 1);

for i = 1:length(y_test)
    test_point = X_test_scaled(i, :);
    
    min_dist = inf;
    best_class = 1;
    
    for c = 1:n_classes
        class_idx = (y_train == classes{c});
        class_points = X_train_scaled(class_idx, :);
        
        if ~isempty(class_points)
            distances = sqrt(sum((class_points - test_point).^2, 2));
            avg_dist = mean(distances);
            
            if avg_dist < min_dist
                min_dist = avg_dist;
                best_class = c;
            end
        end
    end
    
    y_pred_mindist{i} = char(classes{best_class});
end

y_pred_mindist = categorical(y_pred_mindist);
accuracy_mindist = sum(y_pred_mindist == y_test) / length(y_test);
fprintf('✓ (%.0f%%)\n', accuracy_mindist * 100);

%% Find best model
fprintf('\n──────────────────────────────────────────────────\n');
fprintf('MODEL COMPARISON\n');
fprintf('──────────────────────────────────────────────────\n\n');

model_names = {'K-Nearest Neighbors', 'Nearest Class Mean', 'Minimum Distance'};
accuracies = [accuracy_knn, accuracy_mean, accuracy_mindist];
predictions = {y_pred_knn, y_pred_mean, y_pred_mindist};

[best_acc, best_idx] = max(accuracies);
best_model_name = model_names{best_idx};
best_y_pred = predictions{best_idx};

fprintf('%-25s: %.2f%%\n', model_names{1}, accuracies(1) * 100);
fprintf('%-25s: %.2f%%\n', model_names{2}, accuracies(2) * 100);
fprintf('%-25s: %.2f%%\n', model_names{3}, accuracies(3) * 100);

fprintf('\n──────────────────────────────────────────────────\n');
fprintf('BEST MODEL: %s (%.2f%%)\n', best_model_name, best_acc * 100);
fprintf('──────────────────────────────────────────────────\n\n');

%% Classification Report
fprintf('Classification Report:\n');
fprintf('──────────────────────────────────────────────────\n');

for i = 1:length(classes)
    class_name = classes{i};
    
    tp = sum((y_test == class_name) & (best_y_pred == class_name));
    fp = sum((y_test ~= class_name) & (best_y_pred == class_name));
    fn = sum((y_test == class_name) & (best_y_pred ~= class_name));
    support = sum(y_test == class_name);
    
    if (tp + fp) > 0
        precision = tp / (tp + fp) * 100;
    else
        precision = 0;
    end
    
    if (tp + fn) > 0
        recall = tp / (tp + fn) * 100;
    else
        recall = 0;
    end
    
    if (precision + recall) > 0
        f1 = 2 * (precision * recall) / (precision + recall);
    else
        f1 = 0;
    end
    
    fprintf('%-15s: P=%.0f%% R=%.0f%% F1=%.0f%% (n=%d)\n', ...
        class_name, precision, recall, f1, support);
end

%% Package results
ml_results = struct();
ml_results.model_names = model_names;
ml_results.accuracies = accuracies;
ml_results.best_model_name = best_model_name;
ml_results.best_accuracy = best_acc;
ml_results.y_test = y_test;
ml_results.y_pred = best_y_pred;
ml_results.train_size = n_train;
ml_results.test_size = length(y_test);
ml_results.mu = mu;
ml_results.sigma = sigma;
ml_results.class_means = class_means;
ml_results.classes = classes;

%% Save
% Get base_path from evalin since config isn't passed
if evalin('base', 'exist(''config'', ''var'')')
    base_path = evalin('base', 'config.base_path');
else
    base_path = pwd;
    % Go up one level if we're in a subfolder
    if contains(base_path, '4_Machine_Learning')
        base_path = fileparts(base_path);
    end
end

models_folder = fullfile(base_path, 'Models');
if ~exist(models_folder, 'dir')
    mkdir(models_folder);
end

save_file = fullfile(models_folder, 'motor_fault_detector.mat');
save(save_file, 'ml_results');

fprintf('\n✓ Model saved to: %s\n', save_file);

end