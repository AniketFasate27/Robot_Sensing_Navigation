function create_comprehensive_dashboard()
% CREATE_COMPREHENSIVE_DASHBOARD
% Creates a single comprehensive visualization with all parameters

fprintf('Creating comprehensive motor fault dashboard...\n');

base_path = 'C:\Users\anifa\Downloads\Simulink\RSN\Final\final2';
results_folder = fullfile(base_path, 'Results');

if ~exist(results_folder, 'dir')
    mkdir(results_folder);
end

motor_conditions = {'healthy', 'imbalance', 'misalignment', 'bearing_fault'};
colors = {[0 0.8 0], [1 0.5 0], [0.8 0 0], [0.5 0 0.5]};

%% Create massive dashboard
figure('Position', [10, 10, 1900, 1100]);

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
        
        %% Row organization: 4 rows (one per condition), 5 columns
        base_idx = (i-1) * 5;
        
        %% Column 1: Vibration Magnitude
        subplot(4, 5, base_idx + 1);
        plot(time, accel_mag, 'Color', colors{i}, 'LineWidth', 1.2);
        if i == 1, title('Vibration', 'FontWeight', 'bold', 'FontSize', 11); end
        if i == 4, xlabel('Time (s)', 'FontSize', 9); end
        ylabel(sprintf('%s\n(m/s²)', upper(condition)), 'FontWeight', 'bold', 'FontSize', 8);
        grid on;
        
        %% Column 2: FFT Spectrum
        subplot(4, 5, base_idx + 2);
        N = length(accel_mag);
        Fs = 100;
        Y = fft(accel_mag);
        P2 = abs(Y/N);
        P1 = P2(1:N/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        f = Fs*(0:(N/2))/N;
        
        plot(f, P1, 'Color', colors{i}, 'LineWidth', 1.2);
        xlim([0, 50]);
        if i == 1, title('FFT', 'FontWeight', 'bold', 'FontSize', 11); end
        if i == 4, xlabel('Freq (Hz)', 'FontSize', 9); end
        ylabel('Mag', 'FontSize', 8);
        grid on;
        
        %% Column 3: Gyroscope
        subplot(4, 5, base_idx + 3);
        plot(time, gyro_mag, 'Color', colors{i}, 'LineWidth', 1.2);
        if i == 1, title('Gyro', 'FontWeight', 'bold', 'FontSize', 11); end
        if i == 4, xlabel('Time (s)', 'FontSize', 9); end
        ylabel('(rad/s)', 'FontSize', 8);
        grid on;
        
        %% Column 4: 3-Axis Accel
        subplot(4, 5, base_idx + 4);
        plot(time, accel_data(:,1), 'r', 'LineWidth', 0.8); hold on;
        plot(time, accel_data(:,2), 'g', 'LineWidth', 0.8);
        plot(time, accel_data(:,3), 'b', 'LineWidth', 0.8);
        if i == 1
            title('3-Axis Accel', 'FontWeight', 'bold', 'FontSize', 11);
            legend('X', 'Y', 'Z', 'FontSize', 7);
        end
        if i == 4, xlabel('Time (s)', 'FontSize', 9); end
        ylabel('(m/s²)', 'FontSize', 8);
        grid on;
        
        %% Column 5: Statistics Box
        subplot(4, 5, base_idx + 5);
        axis off;
        
        rms_accel = sqrt(mean(accel_mag.^2));
        max_accel = max(accel_mag);
        std_accel = std(accel_mag);
        rms_gyro = sqrt(mean(gyro_mag.^2));
        
        % Find dominant frequency
        [~, peak_idx] = max(P1);
        peak_freq = f(peak_idx);
        
        stats_text = sprintf([
            '%s\n\n' ...
            'Accel RMS: %.3f\n' ...
            'Accel Max: %.3f\n' ...
            'Accel Std: %.3f\n\n' ...
            'Gyro RMS: %.3f\n\n' ...
            'Peak Freq: %.1f Hz'], ...
            upper(condition), rms_accel, max_accel, std_accel, rms_gyro, peak_freq);
        
        text(0.5, 0.5, stats_text, ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 9, ...
            'FontWeight', 'bold', ...
            'BackgroundColor', [colors{i} 0.2], ...
            'EdgeColor', colors{i}, ...
            'LineWidth', 2);
    end
end

sgtitle('Motor Fault Detection - Comprehensive Dashboard', 'FontSize', 18, 'FontWeight', 'bold');

saveas(gcf, fullfile(results_folder, 'comprehensive_dashboard.png'));
fprintf('✓\n');

close all;

fprintf('\n✓ Comprehensive dashboard created!\n');
fprintf('  Saved to: %s/comprehensive_dashboard.png\n', results_folder);

end