%% Accelerometer Sensor Imperfections Simulation
% Demonstrates various non-ideal characteristics of accelerometer sensors

% Clear workspace and set random seed for reproducibility
clear; close all; clc;
rng('default');

%% Save Configuration
SAVE_PLOTS = true;              % Set to false to disable auto-saving
SAVE_FORMAT = 'png';            % Options: 'png', 'pdf', 'fig', 'eps'
SAVE_RESOLUTION = '-r300';      % DPI for raster formats
OUTPUT_DIR = 'accel_plots';     % Output directory name

% Create output directory if saving is enabled
if SAVE_PLOTS
    if ~exist(OUTPUT_DIR, 'dir')
        mkdir(OUTPUT_DIR);
        fprintf('Created output directory: %s\n', OUTPUT_DIR);
    end
end

%% Configuration Parameters
params = accelparams;

% Signal generation parameters
N = 1000;               % Number of samples
Fs = 100;               % Sampling rate (Hz)
Fc = 0.25;              % Sinusoidal frequency (Hz)

% Generate time vector and ideal signals
t = (0:(1/Fs):((N-1)/Fs)).';
angvel = zeros(N, 3);
acc = zeros(N, 3);
acc(:,1) = sin(2*pi*Fc*t);

%% Note: Helper functions are defined at the end of the file

%% 1. Ideal Accelerometer (Baseline)
imu = imuSensor('SampleRate', Fs, 'Accelerometer', params);
[accelData, ~] = imu(acc, angvel);

plotAccelData(t, acc(:,1), accelData(:,1), 'Ideal Accelerometer Data', ...
    '01_ideal', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 2. Measurement Range Saturation
imu = imuSensor('SampleRate', Fs, 'Accelerometer', params);
imu.Accelerometer.MeasurementRange = 0.5; % m/s^2
[accelData, ~] = imu(acc, angvel);

plotAccelData(t, acc(:,1), accelData(:,1), 'Saturated Accelerometer Data', ...
    '02_saturated', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 3. Quantization Effects
imu = imuSensor('SampleRate', Fs, 'Accelerometer', params);
imu.Accelerometer.Resolution = 0.5; % (m/s^2)/LSB
[accelData, ~] = imu(acc, angvel);

plotAccelData(t, acc(:,1), accelData(:,1), 'Quantized Accelerometer Data', ...
    '03_quantized', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 4. Axes Misalignment
imu = imuSensor('SampleRate', Fs, 'Accelerometer', params);
xMisalignment = 2; % percent
imu.Accelerometer.AxesMisalignment = [xMisalignment, 0, 0];
[accelData, ~] = imu(acc, angvel);

fig = figure;
plot(t, acc(:,1:2), '--', t, accelData(:,1:2), 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Acceleration (m/s^2)');
title('Misaligned Accelerometer Data');
legend('X Truth', 'Y Truth', 'X Accel', 'Y Accel');
grid on;
if SAVE_PLOTS
    savePlot_helper(fig, '04_misaligned', OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);
end

%% 5. Constant Bias
imu = imuSensor('SampleRate', Fs, 'Accelerometer', params);
xBias = 0.4; % m/s^2
imu.Accelerometer.ConstantBias = [xBias, 0, 0];
[accelData, ~] = imu(acc, angvel);

plotAccelData(t, acc(:,1), accelData(:,1), 'Biased Accelerometer Data', ...
    '05_biased', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 6. White Noise
imu = imuSensor('SampleRate', Fs, 'Accelerometer', params);
imu.Accelerometer.NoiseDensity = 0.03; % (m/s^2)/sqrt(Hz)
[accelData, ~] = imu(acc, angvel);

plotAccelData(t, acc(:,1), accelData(:,1), 'White Noise Accelerometer Data', ...
    '06_white_noise', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 7. Bias Instability
imu = imuSensor('SampleRate', Fs, 'Accelerometer', params);
imu.Accelerometer.BiasInstability = 0.02; % m/s^2
[accelData, ~] = imu(acc, angvel);

plotAccelData(t, acc(:,1), accelData(:,1), 'Bias Instability Accelerometer Data', ...
    '07_bias_instability', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 8. Random Walk (Velocity Random Walk)
imu = imuSensor('SampleRate', Fs, 'Accelerometer', params);
imu.Accelerometer.RandomWalk = 0.05; % (m/s^2)*sqrt(Hz)
[accelData, ~] = imu(acc, angvel);

plotAccelData(t, acc(:,1), accelData(:,1), 'Random Walk Accelerometer Data', ...
    '08_random_walk', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 9. Temperature-Induced Bias
imu = imuSensor('SampleRate', Fs, 'Accelerometer', params);
imu.Accelerometer.TemperatureBias = 0.08; % (m/s^2)/(degrees C)
imu.Temperature = 35; % degrees C
[accelData, ~] = imu(acc, angvel);

plotAccelData(t, acc(:,1), accelData(:,1), 'Temperature-Biased Accelerometer Data', ...
    '09_temp_biased', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 10. Temperature Scale Factor (Time-Varying Temperature)
imu = imuSensor('SampleRate', Fs, 'Accelerometer', params);
imu.Accelerometer.TemperatureScaleFactor = 2.5; % %/(degrees C)

standardTemperature = 25; % degrees C
temperatureSlope = 2; % (degrees C)/s
temperature = temperatureSlope*t + standardTemperature;

accelData = zeros(N, 3);
for i = 1:N
    imu.Temperature = temperature(i);
    [accelData(i,:), ~] = imu(acc(i,:), angvel(i,:));
end

plotAccelData(t, acc(:,1), accelData(:,1), 'Temperature-Scaled Accelerometer Data', ...
    '10_temp_scaled', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 11. Gravity Effect (Tilt Sensitivity)
imu = imuSensor('SampleRate', Fs, 'Accelerometer', params);

% Simulate a tilted accelerometer experiencing gravity
acc_with_gravity = zeros(N, 3);
acc_with_gravity(:,1) = sin(2*pi*Fc*t);  % Dynamic acceleration
acc_with_gravity(:,3) = 9.81;            % Gravity component
[accelData, ~] = imu(acc_with_gravity, angvel);

fig = figure;
plot(t, acc_with_gravity(:,1), '--', t, accelData(:,1), 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Acceleration (m/s^2)');
title('Accelerometer with Gravity Component');
legend('X Truth (no gravity)', 'X Accel (with gravity in Z)');
grid on;
if SAVE_PLOTS
    savePlot_helper(fig, '11_gravity_effect', OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);
end

%% Summary Comparison
% Create a subplot showing multiple imperfections side-by-side
fig = figure('Position', [100, 100, 1200, 800]);

imperfections = {'Ideal', 'Saturated', 'Quantized', 'Biased', ...
                 'White Noise', 'Random Walk'};
              
for i = 1:6
    subplot(2, 3, i);
    % Recompute each case for comparison
    imu = imuSensor('SampleRate', Fs, 'Accelerometer', params);
    
    switch i
        case 1 % Ideal
            % No modifications
        case 2 % Saturated
            imu.Accelerometer.MeasurementRange = 0.5;
        case 3 % Quantized
            imu.Accelerometer.Resolution = 0.5;
        case 4 % Biased
            imu.Accelerometer.ConstantBias = [0.4, 0, 0];
        case 5 % White Noise
            imu.Accelerometer.NoiseDensity = 0.03;
        case 6 % Random Walk
            imu.Accelerometer.RandomWalk = 0.05;
    end
    
    [accelData, ~] = imu(acc, angvel);
    plot(t, acc(:,1), '--', t, accelData(:,1), 'LineWidth', 1.2);
    xlabel('Time (s)'); ylabel('Acceleration (m/s^2)');
    title(imperfections{i});
    legend('Truth', 'Measured', 'Location', 'best');
    grid on;
end

sgtitle('Accelerometer Imperfections Comparison');

if SAVE_PLOTS
    savePlot_helper(fig, '12_summary_comparison', OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);
end

fprintf('\nAccelerometer simulation complete!\n');
fprintf('Generated 12 plots');
if SAVE_PLOTS
    fprintf(' and saved to: %s\n', OUTPUT_DIR);
else
    fprintf('\n');
end

%% Helper Functions
function plotAccelData(t, truth, measured, titleStr, filename, enableSave, outputDir, saveFormat, saveResolution)
    % Create and optionally save an accelerometer data comparison plot
    fig = figure;
    plot(t, truth, '--', t, measured, 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Acceleration (m/s^2)');
    title(titleStr);
    legend('Ground Truth', 'Accelerometer');
    grid on;
    
    if enableSave
        savePlot_helper(fig, filename, outputDir, saveFormat, saveResolution);
    end
end

function savePlot_helper(fig, filename, outputDir, saveFormat, saveResolution)
    % Save a figure with specified format and resolution
    filepath = fullfile(outputDir, [filename '.' saveFormat]);
    
    switch lower(saveFormat)
        case 'png'
            print(fig, filepath, '-dpng', saveResolution);
        case 'pdf'
            print(fig, filepath, '-dpdf', '-fillpage');
        case 'eps'
            print(fig, filepath, '-depsc', saveResolution);
        case 'fig'
            savefig(fig, filepath);
        otherwise
            warning('Unknown format %s, saving as PNG', saveFormat);
            print(fig, fullfile(outputDir, [filename '.png']), '-dpng', saveResolution);
    end
    
    fprintf('  Saved: %s\n', filepath);
end