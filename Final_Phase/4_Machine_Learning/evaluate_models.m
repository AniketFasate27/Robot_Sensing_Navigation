function evaluate_models(ml_results)
% EVALUATE_MODELS
% Displays detailed evaluation of trained models

fprintf('\nDETAILED MODEL EVALUATION\n');
fprintf('════════════════════════════════════════════════\n\n');

for i = 1:length(ml_results.model_names)
    fprintf('%d. %s: %.2f%%\n', i, ml_results.model_names{i}, ...
        ml_results.accuracies(i) * 100);
end

fprintf('\nBest Performing Model: %s\n', ml_results.best_model_name);
fprintf('Test Accuracy: %.2f%%\n', ml_results.best_accuracy * 100);

end