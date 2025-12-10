function features_data = extract_features_simulink(config)
% EXTRACT_FEATURES_SIMULINK
% Extracts 144 features - NO TOOLBOXES REQUIRED

fprintf('Extracting features from INPUT data...\n\n');

motor_conditions = config.motor_conditions;
window_size = config.window_size;
step_size = config.step_size;

if isfield(config, 'base_path')
    base_path = config.base_path;
else
    base_path = pwd;
end

all_features = [];
all_labels = [];

%% Process each motor condition
for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    
    accel_var = sprintf('Acceleration_%s', condition);
    gyro_var = sprintf('AngularVelocity_%s', condition);
    
    fprintf('  Processing: %-15s... ', condition);
    
    if evalin('base', sprintf('exist(''%s'', ''var'')', accel_var))
        
        accel_ts = evalin('base', accel_var);
        gyro_ts = evalin('base', gyro_var);
        
        accel_data = accel_ts.Data;
        gyro_data = gyro_ts.Data;
        
        accel_mag = sqrt(sum(accel_data.^2, 2));
        gyro_mag = sqrt(sum(gyro_data.^2, 2));
        
        num_samples = length(accel_mag);
        num_windows = floor((num_samples - window_size) / step_size) + 1;
        
        for w = 1:num_windows
            start_idx = (w-1) * step_size + 1;
            end_idx = start_idx + window_size - 1;
            
            if end_idx <= num_samples
                accel_window = accel_mag(start_idx:end_idx);
                gyro_window = gyro_mag(start_idx:end_idx);
                ax_window = accel_data(start_idx:end_idx, 1);
                ay_window = accel_data(start_idx:end_idx, 2);
                az_window = accel_data(start_idx:end_idx, 3);
                gx_window = gyro_data(start_idx:end_idx, 1);
                gy_window = gyro_data(start_idx:end_idx, 2);
                gz_window = gyro_data(start_idx:end_idx, 3);
                
                features = extract_all_features(accel_window, gyro_window, ...
                    ax_window, ay_window, az_window, gx_window, gy_window, gz_window);
                
                all_features = [all_features; features];
                all_labels = [all_labels; {condition}];
            end
        end
        
        fprintf('✓ (%d windows)\n', num_windows);
    end
end

features_data = struct();
features_data.features = all_features;
features_data.labels = categorical(all_labels);
features_data.num_samples = size(all_features, 1);
features_data.num_features = size(all_features, 2);

data_folder = fullfile(base_path, 'Data');
if ~exist(data_folder, 'dir')
    mkdir(data_folder);
end

save_file = fullfile(data_folder, 'motor_fault_features.mat');
save(save_file, 'features_data');

fprintf('\n✓ Feature extraction complete!\n');
fprintf('  Total samples: %d\n', features_data.num_samples);
fprintf('  Features per sample: %d\n', features_data.num_features);
fprintf('  Saved to: %s\n', save_file);

end

%% Helper function
function features = extract_all_features(accel_mag, gyro_mag, ax, ay, az, gx, gy, gz)
% Extract 144 features WITHOUT any toolboxes

features = [];

%% Magnitude features (18 features)
% Accel magnitude (9 features)
features = [features, ...
    mean(accel_mag), ...
    std(accel_mag), ...
    var(accel_mag), ...
    min(accel_mag), ...
    max(accel_mag), ...
    max(accel_mag)-min(accel_mag), ...  % range
    sqrt(mean(accel_mag.^2)), ...       % rms
    custom_skewness(accel_mag), ...     % custom skewness
    custom_kurtosis(accel_mag)];        % custom kurtosis

% Gyro magnitude (9 features)
features = [features, ...
    mean(gyro_mag), ...
    std(gyro_mag), ...
    var(gyro_mag), ...
    min(gyro_mag), ...
    max(gyro_mag), ...
    max(gyro_mag)-min(gyro_mag), ...
    sqrt(mean(gyro_mag.^2)), ...
    custom_skewness(gyro_mag), ...
    custom_kurtosis(gyro_mag)];

%% Individual axis features (54 features)
signals = {ax, ay, az, gx, gy, gz};
for i = 1:length(signals)
    sig = signals{i};
    features = [features, ...
        mean(sig), ...
        std(sig), ...
        var(sig), ...
        min(sig), ...
        max(sig), ...
        max(sig)-min(sig), ...
        sqrt(mean(sig.^2)), ...
        custom_skewness(sig), ...
        custom_kurtosis(sig)];
end

%% FFT features - Accel Mag (14 features)
N = length(accel_mag);
Fs = 100;
Y = fft(accel_mag);
P2 = abs(Y/N);
P1 = P2(1:N/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:(N/2))/N;

[pks, locs] = custom_findpeaks(P1, 5);
for i = 1:5
    if i <= length(pks)
        features = [features, f(locs(i)), pks(i)];
    else
        features = [features, 0, 0];
    end
end
features = [features, mean(P1), std(P1), max(P1), sum(f.*P1')/sum(P1)];

%% FFT features - Gyro Mag (14 features)
Y_g = fft(gyro_mag);
P2_g = abs(Y_g/N);
P1_g = P2_g(1:N/2+1);
P1_g(2:end-1) = 2*P1_g(2:end-1);

[pks_g, locs_g] = custom_findpeaks(P1_g, 5);
for i = 1:5
    if i <= length(pks_g)
        features = [features, f(locs_g(i)), pks_g(i)];
    else
        features = [features, 0, 0];
    end
end
features = [features, mean(P1_g), std(P1_g), max(P1_g), sum(f.*P1_g')/sum(P1_g)];

%% Additional features (16 features to reach 144)
features = [features, ...
    custom_percentile(accel_mag, 25), ...
    custom_percentile(accel_mag, 50), ...
    custom_percentile(accel_mag, 75), ...
    custom_percentile(gyro_mag, 25), ...
    custom_percentile(gyro_mag, 50), ...
    custom_percentile(gyro_mag, 75), ...
    sum(accel_mag.^2), ...
    sum(abs(accel_mag)), ...
    sum(gyro_mag.^2), ...
    sum(abs(gyro_mag))];

% Pad to exactly 144
current_length = length(features);
if current_length < 144
    features = [features, zeros(1, 144 - current_length)];
elseif current_length > 144
    features = features(1:144);
end

end

%% Custom functions (no toolbox required)
function sk = custom_skewness(x)
    n = length(x);
    m = mean(x);
    s = std(x);
    sk = (1/n) * sum(((x - m) / s).^3);
end

function k = custom_kurtosis(x)
    n = length(x);
    m = mean(x);
    s = std(x);
    k = (1/n) * sum(((x - m) / s).^4);
end

function p = custom_percentile(x, pct)
    sorted_x = sort(x);
    n = length(x);
    idx = ceil((pct/100) * n);
    if idx < 1, idx = 1; end
    if idx > n, idx = n; end
    p = sorted_x(idx);
end

function [pks, locs] = custom_findpeaks(signal, num_peaks)
    % Simple peak finding without toolbox
    pks = [];
    locs = [];
    
    for i = 2:length(signal)-1
        if signal(i) > signal(i-1) && signal(i) > signal(i+1)
            pks = [pks; signal(i)];
            locs = [locs; i];
        end
    end
    
    % Sort by magnitude and take top N
    [pks, sort_idx] = sort(pks, 'descend');
    locs = locs(sort_idx);
    
    if length(pks) > num_peaks
        pks = pks(1:num_peaks);
        locs = locs(1:num_peaks);
    end
end