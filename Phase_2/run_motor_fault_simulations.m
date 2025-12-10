% run_motor_fault_simulations.m
% Runs all motor fault simulations and collects results

clear; clc; close all;

fprintf('\n');
fprintf('╔════════════════════════════════════════════╗\n');
fprintf('║  MOTOR FAULT DETECTION SIMULATIONS        ║\n');
fprintf('╚════════════════════════════════════════════╝\n');
fprintf('\n');

motor_conditions = {'healthy', 'imbalance', 'misalignment', 'bearing_fault'};
results = struct();

%% Run simulations for each condition
for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    model_name = sprintf('Motor_Fault_%s', condition);
    
    fprintf('Running simulation: %s\n', upper(condition));
    fprintf('────────────────────────────────────────────\n');
    
    % Load data
    load(sprintf('IMU_data_%s.mat', condition));
    
    % Run simulation
    fprintf('  Simulating...\n');
    sim_out = sim(model_name);
    
    % Extract results
    results.(condition).accel = accel_measured;
    results.(condition).gyro = gyro_measured;
    results.(condition).time = accel_measured.time;
    
    fprintf('  ✓ Simulation complete\n');
    fprintf('  Duration: %.2f seconds\n', results.(condition).time(end));
    fprintf('  Samples: %d\n\n', length(results.(condition).time));
end

%% Save all results
save('motor_fault_simulation_results.mat', 'results');
fprintf('✓ All results saved to: motor_fault_simulation_results.mat\n\n');

%% Visualize results
fprintf('Creating visualization...\n');

figure('Position', [100, 100, 1400, 900]);

for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    
    % Calculate vibration magnitude
    accel_data = results.(condition).accel.Data;
    vibration_mag = sqrt(sum(accel_data.^2, 2));
    time = results.(condition).time;
    
    % Plot
    subplot(2, 2, i);
    plot(time, vibration_mag, 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Vibration Magnitude (m/s²)');
    title(sprintf('%s Motor', upper(condition)), 'FontWeight', 'bold');
    grid on;
    
    % Add statistics
    rms_val = rms(vibration_mag);
    max_val = max(vibration_mag);
    mean_val = mean(vibration_mag);
    
    text(0.05, 0.95, sprintf('RMS: %.3f m/s²', rms_val), ...
        'Units', 'normalized', 'VerticalAlignment', 'top', 'FontWeight', 'bold');
    text(0.05, 0.88, sprintf('Max: %.3f m/s²', max_val), ...
        'Units', 'normalized', 'VerticalAlignment', 'top');
    text(0.05, 0.81, sprintf('Mean: %.3f m/s²', mean_val), ...
        'Units', 'normalized', 'VerticalAlignment', 'top');
end

sgtitle('Motor Fault Detection - Vibration Analysis', 'FontSize', 16, 'FontWeight', 'bold');

saveas(gcf, 'motor_fault_comparison.png');
fprintf('✓ Visualization saved: motor_fault_comparison.png\n\n');

%% Generate comparison table
fprintf('╔════════════════════════════════════════════╗\n');
fprintf('║         SIMULATION STATISTICS              ║\n');
fprintf('╚════════════════════════════════════════════╝\n\n');

fprintf('Condition       RMS (m/s²)  Max (m/s²)  Mean (m/s²)\n');
fprintf('─────────────────────────────────────────────────────\n');

for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    accel_data = results.(condition).accel.Data;
    vibration_mag = sqrt(sum(accel_data.^2, 2));
    
    fprintf('%-15s %10.4f  %10.4f  %11.4f\n', ...
        upper(condition), rms(vibration_mag), max(vibration_mag), mean(vibration_mag));
end

fprintf('─────────────────────────────────────────────────────\n\n');

fprintf('\n');
fprintf('╔════════════════════════════════════════════╗\n');
fprintf('║           SIMULATIONS COMPLETE!            ║\n');
fprintf('╚════════════════════════════════════════════╝\n');
fprintf('\n');