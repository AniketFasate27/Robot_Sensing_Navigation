function motor_fault_IMU_generator_all(config)
% MOTOR_FAULT_IMU_GENERATOR_ALL
% Generates synthetic IMU data for all motor fault conditions

fprintf('Generating synthetic motor data...\n\n');

%% Extract configuration
Fs = config.Fs;
duration = config.duration;
t = 0:1/Fs:duration;
N = length(t);

motor_conditions = config.motor_conditions;

% CRITICAL: Always use base_path, not current directory
if isfield(config, 'base_path')
    base_path = config.base_path;
else
    % If no base_path, go up one level from current directory
    current_dir = pwd;
    if contains(current_dir, '1_Data_Generation')
        base_path = fileparts(current_dir);
    else
        base_path = current_dir;
    end
end

%% Generate data for each condition
for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    fprintf('  Generating: %-15s... ', condition);
    
    %% Generate fault-specific vibration patterns
    switch condition
        case 'healthy'
            Accel_X = 0.1 * randn(size(t)) + 9.8;
            Accel_Y = 0.1 * randn(size(t));
            Accel_Z = 0.1 * randn(size(t));
            Gyro_X = 0.05 * randn(size(t));
            Gyro_Y = 0.05 * randn(size(t));
            Gyro_Z = 0.05 * randn(size(t));
            
        case 'imbalance'
            motor_freq = 30;
            Accel_X = 0.5 * sin(2*pi*motor_freq*t) + 0.2 * randn(size(t)) + 9.8;
            Accel_Y = 0.5 * cos(2*pi*motor_freq*t) + 0.2 * randn(size(t));
            Accel_Z = 0.3 * sin(2*pi*motor_freq*t) + 0.2 * randn(size(t));
            Gyro_X = 0.3 * sin(2*pi*motor_freq*t) + 0.1 * randn(size(t));
            Gyro_Y = 0.3 * cos(2*pi*motor_freq*t) + 0.1 * randn(size(t));
            Gyro_Z = 0.2 * sin(2*pi*motor_freq*t) + 0.1 * randn(size(t));
            
        case 'misalignment'
            motor_freq = 30;
            Accel_X = 0.3 * sin(2*pi*motor_freq*t) + 0.4 * sin(2*pi*2*motor_freq*t) + 0.2 * randn(size(t)) + 9.8;
            Accel_Y = 0.4 * cos(2*pi*motor_freq*t) + 0.3 * cos(2*pi*2*motor_freq*t) + 0.2 * randn(size(t));
            Accel_Z = 0.3 * sin(2*pi*motor_freq*t) + 0.2 * randn(size(t));
            Gyro_X = 0.4 * sin(2*pi*motor_freq*t) + 0.1 * randn(size(t));
            Gyro_Y = 0.4 * cos(2*pi*motor_freq*t) + 0.1 * randn(size(t));
            Gyro_Z = 0.3 * sin(2*pi*2*motor_freq*t) + 0.1 * randn(size(t));
            
        case 'bearing_fault'
            motor_freq = 30;
            bearing_freq = 120;
            impulse_times = rand(1, 50) * duration;
            impulses = zeros(size(t));
            for j = 1:length(impulse_times)
                [~, idx] = min(abs(t - impulse_times(j)));
                decay = exp(-0.5*(0:min(10, N-idx))/2);
                impulses(idx:min(idx+10, N)) = 2 * decay;
            end
            Accel_X = 0.4 * sin(2*pi*motor_freq*t) + 0.6 * sin(2*pi*bearing_freq*t) + impulses + 0.3 * randn(size(t)) + 9.8;
            Accel_Y = 0.4 * cos(2*pi*motor_freq*t) + 0.5 * cos(2*pi*bearing_freq*t) + 0.3 * randn(size(t));
            Accel_Z = 0.3 * sin(2*pi*bearing_freq*t) + 0.3 * randn(size(t));
            Gyro_X = 0.5 * sin(2*pi*bearing_freq*t) + 0.2 * randn(size(t));
            Gyro_Y = 0.5 * cos(2*pi*bearing_freq*t) + 0.2 * randn(size(t));
            Gyro_Z = 0.4 * sin(2*pi*motor_freq*t) + 0.2 * randn(size(t));
    end
    
    %% Create timeseries objects
    var_name_accel = sprintf('Acceleration_%s', condition);
    var_name_gyro = sprintf('AngularVelocity_%s', condition);
    
    % Create acceleration timeseries
    ts_accel = timeseries([Accel_X', Accel_Y', Accel_Z'], t');
    ts_accel.Name = var_name_accel;
    ts_accel.DataInfo.Units = 'm/s^2';
    
    % Create gyroscope timeseries
    ts_gyro = timeseries([Gyro_X', Gyro_Y', Gyro_Z'], t');
    ts_gyro.Name = var_name_gyro;
    ts_gyro.DataInfo.Units = 'rad/s';
    
    % Assign to variables
    eval([var_name_accel ' = ts_accel;']);
    eval([var_name_gyro ' = ts_gyro;']);
    
    fprintf('✓ (%d samples)\n', N);
end

%% Save all data to BASE_PATH/Data folder (not current directory!)
fprintf('\nSaving data to Data/IMU_data_all_conditions.mat... ');

% Create Data folder in BASE directory
data_folder = fullfile(base_path, 'Data');
if ~exist(data_folder, 'dir')
    mkdir(data_folder);
    fprintf('\n  Created folder: %s\n', data_folder);
end

% Full path to save file
save_file = fullfile(data_folder, 'IMU_data_all_conditions.mat');

% Build save command
save_cmd = sprintf('save(''%s''', save_file);
for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    save_cmd = [save_cmd, sprintf(', ''Acceleration_%s'', ''AngularVelocity_%s''', condition, condition)];
end
save_cmd = [save_cmd, ', ''t'', ''Fs'', ''motor_conditions'');'];

% Execute save
eval(save_cmd);

fprintf('✓\n');
fprintf('  Saved to: %s\n', save_file);

end