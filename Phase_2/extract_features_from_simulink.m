% extract_features_from_simulink.m
% Extract ML features from Simulink simulation results

clear; clc;

fprintf('Extracting features from simulation results...\n\n');

% Load simulation results
load('motor_fault_simulation_results.mat', 'results');

motor_conditions = fieldnames(results);
all_features = [];
all_labels = [];

%% Extract features using sliding window
window_size = 100;   % 1 second at 100 Hz
step_size = 50;      % 50% overlap

for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    fprintf('Processing: %s\n', condition);
    
    accel_data = results.(condition).accel.Data;
    gyro_data = results.(condition).gyro.Data;
    
    num_samples = size(accel_data, 1);
    num_windows = floor((num_samples - window_size) / step_size) + 1;
    
    for w = 1:num_windows
        start_idx = (w-1) * step_size + 1;
        end_idx = start_idx + window_size - 1;
        
        accel_window = accel_data(start_idx:end_idx, :);
        gyro_window = gyro_data(start_idx:end_idx, :);
        
        % Extract features
        features = [];
        
        % Accelerometer features (each axis)
        for axis = 1:3
            signal = accel_window(:, axis);
            features = [features, ...
                mean(signal), std(signal), rms(signal), ...
                max(signal), min(signal), range(signal), ...
                skewness(signal), kurtosis(signal)];
        end
        
        % Gyroscope features (each axis)
        for axis = 1:3
            signal = gyro_window(:, axis);
            features = [features, ...
                mean(signal), std(signal), rms(signal), ...
                max(signal), min(signal), range(signal)];
        end
        
        % Combined magnitude features
        accel_mag = sqrt(sum(accel_window.^2, 2));
        gyro_mag = sqrt(sum(gyro_window.^2, 2));
        
        features = [features, ...
            mean(accel_mag), std(accel_mag), max(accel_mag), ...
            mean(gyro_mag), std(gyro_mag), max(gyro_mag)];
        
        all_features = [all_features; features];
        all_labels = [all_labels; {condition}];
    end
    
    fprintf('  Extracted %d windows\n', num_windows);
end

%% Save features
save('motor_fault_features_simulink.mat', 'all_features', 'all_labels');

fprintf('\n✓ Feature extraction complete!\n');
fprintf('  Total samples: %d\n', size(all_features, 1));
fprintf('  Features per sample: %d\n', size(all_features, 2));
fprintf('  Saved to: motor_fault_features_simulink.mat\n\n');