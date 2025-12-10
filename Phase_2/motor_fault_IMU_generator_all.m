% motor_fault_IMU_generator_all.m
% Generates IMU data for ALL motor conditions with proper variable names

clear; clc; close all;

fprintf('==============================================\n');
fprintf('MOTOR FAULT IMU DATA GENERATOR\n');
fprintf('(All conditions in one file)\n');
fprintf('==============================================\n\n');

%% Configuration
Fs = 100;              % Sampling frequency (Hz)
duration = 10;         % Duration (seconds)
t = 0:1/Fs:duration;   % Time vector
N = length(t);

motor_conditions = {'healthy', 'imbalance', 'misalignment', 'bearing_fault'};

%% Generate data for each motor condition
for condition_idx = 1:length(motor_conditions)
    condition = motor_conditions{condition_idx};
    
    fprintf('Generating data for: %s\n', upper(condition));
    
    %% Generate acceleration data based on fault type
    switch condition
        case 'healthy'
            % Healthy motor: low amplitude, random vibration
            Accel_X = 0.1 * randn(size(t)) + 9.8;
            Accel_Y = 0.1 * randn(size(t));
            Accel_Z = 0.1 * randn(size(t));
            
            Gyro_X = 0.05 * randn(size(t));
            Gyro_Y = 0.05 * randn(size(t));
            Gyro_Z = 0.05 * randn(size(t));
            
        case 'imbalance'
            % Imbalance: periodic vibration at motor frequency
            motor_freq = 30;  % 30 Hz (1800 RPM)
            
            Accel_X = 0.5 * sin(2*pi*motor_freq*t) + 0.2 * randn(size(t)) + 9.8;
            Accel_Y = 0.5 * cos(2*pi*motor_freq*t) + 0.2 * randn(size(t));
            Accel_Z = 0.3 * sin(2*pi*motor_freq*t) + 0.2 * randn(size(t));
            
            Gyro_X = 0.3 * sin(2*pi*motor_freq*t) + 0.1 * randn(size(t));
            Gyro_Y = 0.3 * cos(2*pi*motor_freq*t) + 0.1 * randn(size(t));
            Gyro_Z = 0.2 * sin(2*pi*motor_freq*t) + 0.1 * randn(size(t));
            
        case 'misalignment'
            % Misalignment: 1x and 2x motor frequency components
            motor_freq = 30;
            
            Accel_X = 0.3 * sin(2*pi*motor_freq*t) + ...
                      0.4 * sin(2*pi*2*motor_freq*t) + 0.2 * randn(size(t)) + 9.8;
            Accel_Y = 0.4 * cos(2*pi*motor_freq*t) + ...
                      0.3 * cos(2*pi*2*motor_freq*t) + 0.2 * randn(size(t));
            Accel_Z = 0.3 * sin(2*pi*motor_freq*t) + 0.2 * randn(size(t));
            
            Gyro_X = 0.4 * sin(2*pi*motor_freq*t) + 0.1 * randn(size(t));
            Gyro_Y = 0.4 * cos(2*pi*motor_freq*t) + 0.1 * randn(size(t));
            Gyro_Z = 0.3 * sin(2*pi*2*motor_freq*t) + 0.1 * randn(size(t));
            
        case 'bearing_fault'
            % Bearing fault: high frequency impulses + harmonics
            motor_freq = 30;
            bearing_freq = 120;
            
            % Random impulses
            impulse_times = rand(1, 50) * duration;
            impulses = zeros(size(t));
            for i = 1:length(impulse_times)
                [~, idx] = min(abs(t - impulse_times(i)));
                impulses(idx:min(idx+10, N)) = 2 * exp(-0.5*(0:min(10, N-idx))/2);
            end
            
            Accel_X = 0.4 * sin(2*pi*motor_freq*t) + ...
                      0.6 * sin(2*pi*bearing_freq*t) + impulses + 0.3 * randn(size(t)) + 9.8;
            Accel_Y = 0.4 * cos(2*pi*motor_freq*t) + ...
                      0.5 * cos(2*pi*bearing_freq*t) + 0.3 * randn(size(t));
            Accel_Z = 0.3 * sin(2*pi*bearing_freq*t) + 0.3 * randn(size(t));
            
            Gyro_X = 0.5 * sin(2*pi*bearing_freq*t) + 0.2 * randn(size(t));
            Gyro_Y = 0.5 * cos(2*pi*bearing_freq*t) + 0.2 * randn(size(t));
            Gyro_Z = 0.4 * sin(2*pi*motor_freq*t) + 0.2 * randn(size(t));
    end
    
    %% Create timeseries with condition-specific variable names
    var_name_accel = sprintf('Acceleration_%s', condition);
    var_name_gyro = sprintf('AngularVelocity_%s', condition);
    var_name_orient = sprintf('Orientation_%s', condition);
    
    eval([var_name_accel ' = timeseries([Accel_X'', Accel_Y'', Accel_Z''], t'');']);
    eval([var_name_accel '.Name = ''' var_name_accel ''';']);
    eval([var_name_accel '.DataInfo.Units = ''m/s^2'';']);
    
    eval([var_name_gyro ' = timeseries([Gyro_X'', Gyro_Y'', Gyro_Z''], t'');']);
    eval([var_name_gyro '.Name = ''' var_name_gyro ''';']);
    eval([var_name_gyro '.DataInfo.Units = ''rad/s'';']);
    
    % Orientation (simplified)
    Orientation_data = repmat([1 0 0 0], N, 1);
    eval([var_name_orient ' = timeseries(Orientation_data, t'');']);
    eval([var_name_orient '.Name = ''' var_name_orient ''';']);
    
    fprintf('  ✓ Created: %s, %s, %s\n', var_name_accel, var_name_gyro, var_name_orient);
end

%% Save all variables to one file
filename = 'IMU_data_all_conditions.mat';
save(filename, 'Acceleration_*', 'AngularVelocity_*', 'Orientation_*', 't', 'Fs');

fprintf('\n==============================================\n');
fprintf('DATA GENERATION COMPLETE!\n');
fprintf('==============================================\n');
fprintf('All motor conditions saved to: %s\n', filename);
fprintf('\nVariables created:\n');
for i = 1:length(motor_conditions)
    fprintf('  - Acceleration_%s\n', motor_conditions{i});
    fprintf('  - AngularVelocity_%s\n', motor_conditions{i});
    fprintf('  - Orientation_%s\n', motor_conditions{i});
end
fprintf('\nNext step: Run simulink_motor_fault_setup_subsystems.m\n');
fprintf('==============================================\n\n');