% motor_fault_IMU_generator.m
% Generates synthetic IMU data representing different motor fault conditions
% Creates realistic vibration patterns for: Healthy, Imbalance, Misalignment, Bearing Fault

clear; clc; close all;

fprintf('==============================================\n');
fprintf('MOTOR FAULT IMU DATA GENERATOR\n');
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
            Accel_X = 0.1 * randn(size(t)) + 9.8;  % Mostly gravity
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
            motor_freq = 30;  % 30 Hz
            
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
            bearing_freq = 120;  % High frequency bearing defect
            
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
    
    %% Create timeseries objects for Simulink
    Acceleration = timeseries([Accel_X', Accel_Y', Accel_Z'], t');
    Acceleration.Name = 'Acceleration';
    Acceleration.DataInfo.Units = 'm/s^2';
    
    AngularVelocity = timeseries([Gyro_X', Gyro_Y', Gyro_Z'], t');
    AngularVelocity.Name = 'AngularVelocity';
    AngularVelocity.DataInfo.Units = 'rad/s';
    
    % Orientation (quaternion) - simplified
    Orientation = repmat([1 0 0 0], N, 1);  % Identity quaternion
    Orientation = timeseries(Orientation, t');
    Orientation.Name = 'Orientation';
    
    %% Save data
    filename = sprintf('IMU_data_%s.mat', condition);
    save(filename, 'Acceleration', 'AngularVelocity', 'Orientation', 't', 'Fs');
    
    fprintf('  ✓ Saved: %s\n', filename);
end

fprintf('\n==============================================\n');
fprintf('DATA GENERATION COMPLETE!\n');
fprintf('==============================================\n');
fprintf('Generated files:\n');
for i = 1:length(motor_conditions)
    fprintf('  - IMU_data_%s.mat\n', motor_conditions{i});
end
fprintf('\nNext step: Run simulink_motor_fault_setup.m\n');
fprintf('==============================================\n\n');