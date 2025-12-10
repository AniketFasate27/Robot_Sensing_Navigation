function visualize_results(ml_results, features_data)
% VISUALIZE_RESULTS
% Creates comprehensive visualizations including vibration analysis

fprintf('Creating visualizations...\n\n');

base_path = 'C:\Users\anifa\Downloads\Simulink\RSN\Final\final2';
results_folder = fullfile(base_path, 'Results');

if ~exist(results_folder, 'dir')
    mkdir(results_folder);
end

%% 1. Confusion Matrix
fprintf('  Creating confusion matrix... ');

classes = ml_results.classes;
n_classes = length(classes);
conf_matrix = zeros(n_classes, n_classes);

for i = 1:length(ml_results.y_test)
    true_idx = find(classes == ml_results.y_test(i));
    pred_idx = find(classes == ml_results.y_pred(i));
    conf_matrix(true_idx, pred_idx) = conf_matrix(true_idx, pred_idx) + 1;
end

figure('Position', [100, 100, 800, 700]);
imagesc(conf_matrix);
colormap('parula');
colorbar;

for i = 1:n_classes
    for j = 1:n_classes
        text(j, i, num2str(conf_matrix(i,j)), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 14, 'FontWeight', 'bold', 'Color', 'white');
    end
end

set(gca, 'XTick', 1:n_classes, 'XTickLabel', classes);
set(gca, 'YTick', 1:n_classes, 'YTickLabel', classes);
xlabel('Predicted Class', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('True Class', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Confusion Matrix - %s (Accuracy: %.0f%%)', ...
    ml_results.best_model_name, ml_results.best_accuracy * 100), ...
    'FontSize', 14, 'FontWeight', 'bold');

saveas(gcf, fullfile(results_folder, 'confusion_matrix.png'));
fprintf('✓\n');

%% 2. Model Comparison
fprintf('  Creating model comparison... ');

figure('Position', [100, 100, 1000, 600]);
bar(ml_results.accuracies * 100);
set(gca, 'XTickLabel', ml_results.model_names);
ylabel('Accuracy (%)', 'FontSize', 12);
title('Model Performance Comparison', 'FontSize', 14, 'FontWeight', 'bold');
grid on;
ylim([0, 105]);

for i = 1:length(ml_results.accuracies)
    text(i, ml_results.accuracies(i)*100 + 2, ...
        sprintf('%.0f%%', ml_results.accuracies(i)*100), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 11);
end

saveas(gcf, fullfile(results_folder, 'model_comparison.png'));
fprintf('✓\n');

%% 3. Class Distribution
fprintf('  Creating class distribution... ');

figure('Position', [100, 100, 800, 600]);

class_counts = zeros(n_classes, 1);
for i = 1:n_classes
    class_counts(i) = sum(features_data.labels == classes{i});
end

bar(class_counts);
set(gca, 'XTickLabel', classes);
ylabel('Number of Samples', 'FontSize', 12);
title('Training Data Class Distribution', 'FontSize', 14, 'FontWeight', 'bold');
grid on;

for i = 1:n_classes
    text(i, class_counts(i) + 0.2, num2str(class_counts(i)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 11);
end

saveas(gcf, fullfile(results_folder, 'class_distribution.png'));
fprintf('✓\n');

fprintf('\n✓ Visualizations saved to: %s\n', results_folder);

close all;

end