function compare_conditions(config)
% COMPARE_CONDITIONS
% Comprehensive visualization of all motor conditions
% Shows: Time series, FFT, Statistics for each condition

fprintf('Creating comprehensive fault condition comparison... ');

motor_conditions = config.motor_conditions;
base_path = config.base_path;
results_folder = fullfile(base_path, 'Results');

if ~exist(results_folder, 'dir')
    mkdir(results_folder);
end

%% Figure 1: Vibration Time Series Comparison
figure('Position', [50, 50, 1600, 1000]);

for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    accel_var = sprintf('Acceleration_%s', condition);
    
    if evalin('base', sprintf('exist(''%s'', ''var'')', accel_var))
        accel_ts = evalin('base', accel_var);
        accel_data = accel_ts.Data;
        time = accel_ts.Time;
        
        % Calculate vibration magnitude
        vibration = sqrt(sum(accel_data.^2, 2));
        
        % Plot vibration
        subplot(2, 2, i);
        plot(time, vibration, 'LineWidth', 1.5);
        xlabel('Time (s)', 'FontSize', 10);
        ylabel('Vibration Magnitude (m/s²)', 'FontSize', 10);
        title(upper(condition), 'FontWeight', 'bold', 'FontSize', 12);
        grid on;
        
        % Add statistics box
        rms_val = sqrt(mean(vibration.^2));
        max_val = max(vibration);
        mean_val = mean(vibration);
        std_val = std(vibration);
        
        text(0.98, 0.95, sprintf('RMS: %.3f\nMax: %.3f\nMean: %.3f\nStd: %.3f', ...
            rms_val, max_val, mean_val, std_val), ...
            'Units', 'normalized', ...
            'VerticalAlignment', 'top', ...
            'HorizontalAlignment', 'right', ...
            'FontWeight', 'bold', ...
            'BackgroundColor', [1 1 1 0.8], ...
            'EdgeColor', 'black', ...
            'FontSize', 9);
    end
end

sgtitle('Motor Fault Detection - Vibration Comparison', ...
    'FontSize', 16, 'FontWeight', 'bold');

saveas(gcf, fullfile(results_folder, 'vibration_comparison.png'));
fprintf('✓\n');

%% Figure 2: Multi-Parameter Dashboard (Time + Frequency)
fprintf('Creating multi-parameter dashboard... ');

figure('Position', [50, 50, 1800, 1200]);

for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    accel_var = sprintf('Acceleration_%s', condition);
    gyro_var = sprintf('AngularVelocity_%s', condition);
    
    if evalin('base', sprintf('exist(''%s'', ''var'')', accel_var))
        accel_ts = evalin('base', accel_var);
        gyro_ts = evalin('base', gyro_var);
        
        accel_data = accel_ts.Data;
        gyro_data = gyro_ts.Data;
        time = accel_ts.Time;
        
        % Calculate magnitudes
        accel_mag = sqrt(sum(accel_data.^2, 2));
        gyro_mag = sqrt(sum(gyro_data.^2, 2));
        
        % Row for this condition
        base_row = (i-1) * 3;
        
        %% Column 1: Acceleration Time Series
        subplot(4, 3, base_row + 1);
        plot(time, accel_mag, 'LineWidth', 1.2);
        if i == 1
            title('Acceleration Magnitude', 'FontWeight', 'bold');
        end
        ylabel(sprintf('%s\n(m/s²)', upper(condition)), 'FontWeight', 'bold', 'FontSize', 9);
        if i == 4
            xlabel('Time (s)');
        end
        grid on;
        
        %% Column 2: FFT Spectrum
        subplot(4, 3, base_row + 2);
        
        N = length(accel_mag);
        Fs = 100;
        Y = fft(accel_mag);
        P2 = abs(Y/N);
        P1 = P2(1:N/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        f = Fs*(0:(N/2))/N;
        
        plot(f, P1, 'LineWidth', 1.2);
        xlim([0, 50]);
        if i == 1
            title('Frequency Spectrum', 'FontWeight', 'bold');
        end
        ylabel('Magnitude', 'FontSize', 9);
        if i == 4
            xlabel('Frequency (Hz)');
        end
        grid on;
        
        %% Column 3: Gyroscope Magnitude
        subplot(4, 3, base_row + 3);
        plot(time, gyro_mag, 'LineWidth', 1.2, 'Color', [0.8 0.4 0]);
        if i == 1
            title('Gyroscope Magnitude', 'FontWeight', 'bold');
        end
        ylabel('(rad/s)', 'FontSize', 9);
        if i == 4
            xlabel('Time (s)');
        end
        grid on;
    end
end

sgtitle('Motor Fault Detection - Multi-Parameter Analysis', ...
    'FontSize', 16, 'FontWeight', 'bold');

saveas(gcf, fullfile(results_folder, 'multi_parameter_dashboard.png'));
fprintf('✓\n');

%% Figure 3: Statistical Comparison
fprintf('Creating statistical comparison... ');

figure('Position', [50, 50, 1400, 800]);

stats_matrix = zeros(length(motor_conditions), 6);
stat_labels = {'RMS Accel', 'Max Accel', 'Mean Accel', 'RMS Gyro', 'Max Gyro', 'Mean Gyro'};

for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    accel_var = sprintf('Acceleration_%s', condition);
    gyro_var = sprintf('AngularVelocity_%s', condition);
    
    if evalin('base', sprintf('exist(''%s'', ''var'')', accel_var))
        accel_ts = evalin('base', accel_var);
        gyro_ts = evalin('base', gyro_var);
        
        accel_data = accel_ts.Data;
        gyro_data = gyro_ts.Data;
        
        accel_mag = sqrt(sum(accel_data.^2, 2));
        gyro_mag = sqrt(sum(gyro_data.^2, 2));
        
        stats_matrix(i, :) = [
            sqrt(mean(accel_mag.^2)), ...
            max(accel_mag), ...
            mean(accel_mag), ...
            sqrt(mean(gyro_mag.^2)), ...
            max(gyro_mag), ...
            mean(gyro_mag)
        ];
    end
end

% Plot grouped bar chart
bar(stats_matrix);
set(gca, 'XTickLabel', motor_conditions);
ylabel('Value', 'FontSize', 12);
title('Statistical Comparison Across Motor Conditions', 'FontSize', 14, 'FontWeight', 'bold');
legend(stat_labels, 'Location', 'northwest', 'FontSize', 9);
grid on;

saveas(gcf, fullfile(results_folder, 'statistical_comparison.png'));
fprintf('✓\n');

%% Figure 4: 3-Axis Acceleration for Each Condition
fprintf('Creating 3-axis acceleration comparison... ');

figure('Position', [50, 50, 1800, 1200]);

for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    accel_var = sprintf('Acceleration_%s', condition);
    
    if evalin('base', sprintf('exist(''%s'', ''var'')', accel_var))
        accel_ts = evalin('base', accel_var);
        accel_data = accel_ts.Data;
        time = accel_ts.Time;
        
        % Plot 3 axes
        subplot(4, 3, (i-1)*3 + 1);
        plot(time, accel_data(:,1), 'r', 'LineWidth', 1);
        ylabel(sprintf('%s\nAx (m/s²)', upper(condition)), 'FontSize', 9);
        if i == 1, title('X-Axis Acceleration', 'FontWeight', 'bold'); end
        if i == 4, xlabel('Time (s)'); end
        grid on;
        
        subplot(4, 3, (i-1)*3 + 2);
        plot(time, accel_data(:,2), 'g', 'LineWidth', 1);
        ylabel('Ay (m/s²)', 'FontSize', 9);
        if i == 1, title('Y-Axis Acceleration', 'FontWeight', 'bold'); end
        if i == 4, xlabel('Time (s)'); end
        grid on;
        
        subplot(4, 3, (i-1)*3 + 3);
        plot(time, accel_data(:,3), 'b', 'LineWidth', 1);
        ylabel('Az (m/s²)', 'FontSize', 9);
        if i == 1, title('Z-Axis Acceleration', 'FontWeight', 'bold'); end
        if i == 4, xlabel('Time (s)'); end
        grid on;
    end
end

sgtitle('3-Axis Acceleration - All Motor Conditions', 'FontSize', 16, 'FontWeight', 'bold');
saveas(gcf, fullfile(results_folder, '3axis_acceleration.png'));
fprintf('✓\n');

%% Figure 5: FFT Comparison (All Conditions on One Plot)
fprintf('Creating FFT comparison... ');

figure('Position', [50, 50, 1400, 700]);

colors = {'g', [1 0.5 0], 'r', [0.5 0 0.5]};
legend_names = {};

for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    accel_var = sprintf('Acceleration_%s', condition);
    
    if evalin('base', sprintf('exist(''%s'', ''var'')', accel_var))
        accel_ts = evalin('base', accel_var);
        accel_data = accel_ts.Data;
        accel_mag = sqrt(sum(accel_data.^2, 2));
        
        % FFT
        N = length(accel_mag);
        Fs = 100;
        Y = fft(accel_mag);
        P2 = abs(Y/N);
        P1 = P2(1:N/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        f = Fs*(0:(N/2))/N;
        
        plot(f, P1, 'Color', colors{i}, 'LineWidth', 2); hold on;
        legend_names{i} = upper(condition);
    end
end

xlim([0, 50]);
xlabel('Frequency (Hz)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Magnitude', 'FontSize', 12, 'FontWeight', 'bold');
title('FFT Spectrum Comparison - All Motor Conditions', 'FontSize', 14, 'FontWeight', 'bold');
legend(legend_names, 'Location', 'northeast', 'FontSize', 11);
grid on;

saveas(gcf, fullfile(results_folder, 'fft_comparison.png'));
fprintf('✓\n');

fprintf('\n✓ All visualizations saved to: %s\n', results_folder);

close all;

end