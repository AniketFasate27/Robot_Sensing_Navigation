%% IMU Data Generator for Simulink Import
% Generates accelerometer and gyroscope data with realistic imperfections
% Then saves in format ready for Simulink "From Workspace" blocks

clear; close all; clc;
rng('default');

%% Simulation Parameters
Fs = 100;                   % Sampling rate (Hz)
duration = 10;              % Simulation duration (seconds)
dt = 1/Fs;                  % Time step
N = duration * Fs;          % Number of samples
t = (0:N-1)' * dt;         % Time vector (column)

%% Configure Sensor Parameters
accelParams = accelparams(...
    'MeasurementRange', 19.62, ...          % ±2g
    'Resolution', 0.598e-3, ...             % (m/s²)/LSB
    'ConstantBias', [0.049, 0.049, 0.049], ...
    'NoiseDensity', 3920e-6, ...            % 400 µg/√Hz
    'BiasInstability', 0.02, ...
    'TemperatureBias', 0.08);

gyroParams = gyroparams(...
    'MeasurementRange', 4.363, ...          % ±250°/s
    'Resolution', 8.727e-4, ...             % (rad/s)/LSB
    'ConstantBias', [0.0087, 0.0087, 0.0087], ...
    'NoiseDensity', 8.727e-4, ...           % 0.05°/s/√Hz
    'BiasInstability', 8.73e-5, ...
    'AccelerationBias', 0.178e-3);

%% Generate True Motion Signals

% Option 1: Sinusoidal Motion (Simple Test)
fprintf('Generating sinusoidal motion...\n');
accel_true = zeros(N, 3);
gyro_true = zeros(N, 3);

% Sinusoidal acceleration on X-axis
accel_true(:,1) = sin(2*pi*0.25*t);  % 0.25 Hz

% Sinusoidal rotation about Z-axis (yaw)
gyro_true(:,3) = 0.1 * sin(2*pi*0.1*t);  % rad/s

% Option 2: Step Motion (Uncomment to use instead)
% accel_true(:,1) = double(t > 2 & t < 5);  % Step input 2-5 seconds
% gyro_true(:,3) = 0.2 * double(t > 3 & t < 7);

% Option 3: Random Walk (Uncomment for complex motion)
% accel_true = cumsum(randn(N, 3) * 0.01, 1);
% gyro_true = cumsum(randn(N, 3) * 0.005, 1);

%% Create IMU Sensor and Generate Corrupted Data
imu = imuSensor('accel-gyro', ...
    'SampleRate', Fs, ...
    'Accelerometer', accelParams, ...
    'Gyroscope', gyroParams);

fprintf('Generating sensor measurements with imperfections...\n');

% Pre-allocate arrays
accel_measured = zeros(N, 3);
gyro_measured = zeros(N, 3);

% Generate measurements
for i = 1:N
    [accel_measured(i,:), gyro_measured(i,:)] = imu(accel_true(i,:), gyro_true(i,:));
end

%% Create Timeseries for Simulink (Format: [time, data])

% IMPORTANT: Simulink "From Workspace" expects data in one of these formats:
% 1. Structure with time array: struct with .time and .signals
% 2. Matrix: [time, data] where first column is time
% 3. Timeseries object (recommended)

fprintf('Creating timeseries objects for Simulink...\n');

% Create timeseries objects (RECOMMENDED METHOD)
accel_true_ts = timeseries(accel_true, t, 'Name', 'TrueAcceleration');
accel_true_ts.DataInfo.Units = 'm/s^2';

gyro_true_ts = timeseries(gyro_true, t, 'Name', 'TrueAngularVelocity');
gyro_true_ts.DataInfo.Units = 'rad/s';

accel_measured_ts = timeseries(accel_measured, t, 'Name', 'MeasuredAcceleration');
accel_measured_ts.DataInfo.Units = 'm/s^2';

gyro_measured_ts = timeseries(gyro_measured, t, 'Name', 'MeasuredAngularVelocity');
gyro_measured_ts.DataInfo.Units = 'rad/s';

% Alternative: Create matrix format [time, x, y, z]
accel_true_matrix = [t, accel_true];
gyro_true_matrix = [t, gyro_true];
accel_measured_matrix = [t, accel_measured];
gyro_measured_matrix = [t, gyro_measured];

%% Orientation Input (Required by IMU block)
% For stationary case: identity quaternion [1, 0, 0, 0]
% For moving case: integrate angular velocity to get orientation

fprintf('Creating orientation data...\n');

% Option 1: Fixed orientation (stationary)
quat_data = repmat([1, 0, 0, 0], N, 1);  % N×4 matrix
quat_ts = timeseries(quat_data, t, 'Name', 'Orientation');

% Option 2: Time-varying orientation (uncomment for rotating case)
% quat_data = zeros(N, 4);
% quat_data(1,:) = [1, 0, 0, 0];  % Initial orientation
% for i = 2:N
%     % Simple integration (for more accurate, use Runge-Kutta)
%     dq = 0.5 * quatmultiply(quat_data(i-1,:), [0, gyro_true(i,:)]);
%     quat_data(i,:) = quat_data(i-1,:) + dq * dt;
%     quat_data(i,:) = quat_data(i,:) / norm(quat_data(i,:));  % Normalize
% end
% quat_ts = timeseries(quat_data, t, 'Name', 'Orientation');

%% Plot Results for Verification
figure('Position', [100, 100, 1200, 600]);

subplot(2,2,1);
plot(t, accel_true(:,1), '--', t, accel_measured(:,1), 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Acceleration (m/s^2)');
title('Accelerometer X-axis');
legend('True', 'Measured'); grid on;

subplot(2,2,2);
plot(t, gyro_true(:,3), '--', t, gyro_measured(:,3), 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Angular Velocity (rad/s)');
title('Gyroscope Z-axis');
legend('True', 'Measured'); grid on;

subplot(2,2,3);
plot(t, accel_measured);
xlabel('Time (s)'); ylabel('Acceleration (m/s^2)');
title('Accelerometer (All Axes)');
legend('X', 'Y', 'Z'); grid on;

subplot(2,2,4);
plot(t, gyro_measured);
xlabel('Time (s)'); ylabel('Angular Velocity (rad/s)');
title('Gyroscope (All Axes)');
legend('X', 'Y', 'Z'); grid on;

sgtitle('Generated IMU Data for Simulink');

%% Save to MAT File
fprintf('Saving data to IMU_data.mat...\n');
save('IMU_data.mat', ...
    'accel_true_ts', 'gyro_true_ts', ...
    'accel_measured_ts', 'gyro_measured_ts', ...
    'quat_ts', ...
    'accel_true_matrix', 'gyro_true_matrix', ...
    'accel_measured_matrix', 'gyro_measured_matrix', ...
    'quat_data', 't', 'Fs', 'dt');

fprintf('\n=== Data Generation Complete ===\n');
fprintf('Workspace variables created:\n');
fprintf('  - accel_true_ts        : True acceleration (timeseries)\n');
fprintf('  - gyro_true_ts         : True angular velocity (timeseries)\n');
fprintf('  - accel_measured_ts    : Measured acceleration (timeseries)\n');
fprintf('  - gyro_measured_ts     : Measured angular velocity (timeseries)\n');
fprintf('  - quat_ts              : Orientation quaternion (timeseries)\n');
fprintf('\nAlternative matrix formats also available (*_matrix variables)\n');
fprintf('\nFile saved: IMU_data.mat\n');
fprintf('\n=== Next Steps ===\n');
fprintf('1. Open Simulink\n');
fprintf('2. Add "From Workspace" blocks\n');
fprintf('3. Configure each block with variable names above\n');
fprintf('4. Set Simulation Stop Time to: %.1f seconds\n', duration);
fprintf('5. Run simulation!\n');

%% Display Data Dimensions (for verification)
fprintf('\n=== Data Dimensions ===\n');
fprintf('accel_true_ts:      %d samples × %d axes\n', size(accel_true));
fprintf('gyro_true_ts:       %d samples × %d axes\n', size(gyro_true));
fprintf('quat_ts:            %d samples × %d elements\n', size(quat_data));
fprintf('Time vector:        %d samples\n', length(t));
fprintf('Sampling rate:      %.1f Hz\n', Fs);
fprintf('Duration:           %.1f seconds\n', duration);