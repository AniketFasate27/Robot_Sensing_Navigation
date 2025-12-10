%% Gyroscope Sensor Imperfections Simulation
% Demonstrates various non-ideal characteristics of gyroscope sensors

% Clear workspace and set random seed for reproducibility
clear; close all; clc;
rng('default');

%% Save Configuration
SAVE_PLOTS = true;              % Set to false to disable auto-saving
SAVE_FORMAT = 'png';            % Options: 'png', 'pdf', 'fig', 'eps'
SAVE_RESOLUTION = '-r300';      % DPI for raster formats
OUTPUT_DIR = 'gyro_plots';      % Output directory name

% Create output directory if saving is enabled
if SAVE_PLOTS
    if ~exist(OUTPUT_DIR, 'dir')
        mkdir(OUTPUT_DIR);
        fprintf('Created output directory: %s\n', OUTPUT_DIR);
    end
end

%% Configuration Parameters
params = gyroparams;

% Signal generation parameters
N = 1000;               % Number of samples
Fs = 100;               % Sampling rate (Hz)
Fc = 0.25;              % Sinusoidal frequency (Hz)

% Generate time vector and ideal signals
t = (0:(1/Fs):((N-1)/Fs)).';
acc = zeros(N, 3);
angvel = zeros(N, 3);
angvel(:,1) = sin(2*pi*Fc*t);

%% Note: Helper function plotGyroData is defined at the end of the file

%% 1. Ideal Gyroscope (Baseline)
imu = imuSensor('SampleRate', Fs, 'Gyroscope', params);
[~, gyroData] = imu(acc, angvel);

plotGyroData(t, angvel(:,1), gyroData(:,1), 'Ideal Gyroscope Data', ...
    '01_ideal', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 2. Measurement Range Saturation
imu = imuSensor('SampleRate', Fs, 'Gyroscope', params);
imu.Gyroscope.MeasurementRange = 0.5; % rad/s
[~, gyroData] = imu(acc, angvel);

plotGyroData(t, angvel(:,1), gyroData(:,1), 'Saturated Gyroscope Data', ...
    '02_saturated', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 3. Quantization Effects
imu = imuSensor('SampleRate', Fs, 'Gyroscope', params);
imu.Gyroscope.Resolution = 0.5; % (rad/s)/LSB
[~, gyroData] = imu(acc, angvel);

plotGyroData(t, angvel(:,1), gyroData(:,1), 'Quantized Gyroscope Data', ...
    '03_quantized', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 4. Axes Misalignment
imu = imuSensor('SampleRate', Fs, 'Gyroscope', params);
xMisalignment = 2; % percent
imu.Gyroscope.AxesMisalignment = [xMisalignment, 0, 0];
[~, gyroData] = imu(acc, angvel);

fig = figure;
plot(t, angvel(:,1:2), '--', t, gyroData(:,1:2), 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Angular Velocity (rad/s)');
title('Misaligned Gyroscope Data');
legend('X Truth', 'Y Truth', 'X Gyro', 'Y Gyro');
grid on;
if SAVE_PLOTS
    savePlot_helper(fig, '04_misaligned', OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);
end

%% 5. Constant Bias
imu = imuSensor('SampleRate', Fs, 'Gyroscope', params);
xBias = 0.4; % rad/s
imu.Gyroscope.ConstantBias = [xBias, 0, 0];
[~, gyroData] = imu(acc, angvel);

plotGyroData(t, angvel(:,1), gyroData(:,1), 'Biased Gyroscope Data', ...
    '05_biased', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 6. White Noise
imu = imuSensor('SampleRate', Fs, 'Gyroscope', params);
imu.Gyroscope.NoiseDensity = 0.0125; % (rad/s)/sqrt(Hz)
[~, gyroData] = imu(acc, angvel);

plotGyroData(t, angvel(:,1), gyroData(:,1), 'White Noise Gyroscope Data', ...
    '06_white_noise', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 7. Bias Instability
imu = imuSensor('SampleRate', Fs, 'Gyroscope', params);
imu.Gyroscope.BiasInstability = 0.02; % rad/s
[~, gyroData] = imu(acc, angvel);

plotGyroData(t, angvel(:,1), gyroData(:,1), 'Bias Instability Gyroscope Data', ...
    '07_bias_instability', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 8. Random Walk
imu = imuSensor('SampleRate', Fs, 'Gyroscope', params);
imu.Gyroscope.RandomWalk = 0.091; % (rad/s)*sqrt(Hz)
[~, gyroData] = imu(acc, angvel);

plotGyroData(t, angvel(:,1), gyroData(:,1), 'Random Walk Gyroscope Data', ...
    '08_random_walk', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 9. Temperature-Induced Bias
imu = imuSensor('SampleRate', Fs, 'Gyroscope', params);
imu.Gyroscope.TemperatureBias = 0.06; % (rad/s)/(degrees C)
imu.Temperature = 35; % degrees C
[~, gyroData] = imu(acc, angvel);

plotGyroData(t, angvel(:,1), gyroData(:,1), 'Temperature-Biased Gyroscope Data', ...
    '09_temp_biased', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 10. Temperature Scale Factor (Time-Varying Temperature)
imu = imuSensor('SampleRate', Fs, 'Gyroscope', params);
imu.Gyroscope.TemperatureScaleFactor = 3.2; % %/(degrees C)

standardTemperature = 25; % degrees C
temperatureSlope = 2; % (degrees C)/s
temperature = temperatureSlope*t + standardTemperature;

gyroData = zeros(N, 3);
for i = 1:N
    imu.Temperature = temperature(i);
    [~, gyroData(i,:)] = imu(acc(i,:), angvel(i,:));
end

plotGyroData(t, angvel(:,1), gyroData(:,1), 'Temperature-Scaled Gyroscope Data', ...
    '10_temp_scaled', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% 11. Acceleration-Induced Bias
imu = imuSensor('SampleRate', Fs, 'Gyroscope', params);
imu.Gyroscope.AccelerationBias = 0.3; % (rad/s)/(m/s^2)

acc_with_accel = zeros(N, 3);
acc_with_accel(:,1) = 1; % 1 m/s^2 acceleration
[~, gyroData] = imu(acc_with_accel, angvel);

plotGyroData(t, angvel(:,1), gyroData(:,1), 'Acceleration-Biased Gyroscope Data', ...
    '11_accel_biased', SAVE_PLOTS, OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);

%% Summary Comparison (Optional)
% Create a subplot showing multiple imperfections side-by-side
fig = figure('Position', [100, 100, 1200, 800]);

imperfections = {'Ideal', 'Saturated', 'Quantized', 'Biased', ...
                 'White Noise', 'Random Walk'};
              
for i = 1:6
    subplot(2, 3, i);
    % Recompute each case for comparison
    imu = imuSensor('SampleRate', Fs, 'Gyroscope', params);
    
    switch i
        case 1 % Ideal
            % No modifications
        case 2 % Saturated
            imu.Gyroscope.MeasurementRange = 0.5;
        case 3 % Quantized
            imu.Gyroscope.Resolution = 0.5;
        case 4 % Biased
            imu.Gyroscope.ConstantBias = [0.4, 0, 0];
        case 5 % White Noise
            imu.Gyroscope.NoiseDensity = 0.0125;
        case 6 % Random Walk
            imu.Gyroscope.RandomWalk = 0.091;
    end
    
    [~, gyroData] = imu(acc, angvel);
    plot(t, angvel(:,1), '--', t, gyroData(:,1), 'LineWidth', 1.2);
    xlabel('Time (s)'); ylabel('Angular Velocity (rad/s)');
    title(imperfections{i});
    legend('Truth', 'Measured', 'Location', 'best');
    grid on;
end

sgtitle('Gyroscope Imperfections Comparison');

if SAVE_PLOTS
    savePlot_helper(fig, '12_summary_comparison', OUTPUT_DIR, SAVE_FORMAT, SAVE_RESOLUTION);
end

fprintf('\nGyroscope simulation complete!\n');
fprintf('Generated 12 plots');
if SAVE_PLOTS
    fprintf(' and saved to: %s\n', OUTPUT_DIR);
else
    fprintf('\n');
end

%% Helper Functions
function plotGyroData(t, truth, measured, titleStr, filename, enableSave, outputDir, saveFormat, saveResolution)
    % Create and optionally save a gyroscope data comparison plot
    fig = figure;
    plot(t, truth, '--', t, measured, 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Angular Velocity (rad/s)');
    title(titleStr);
    legend('Ground Truth', 'Gyroscope');
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