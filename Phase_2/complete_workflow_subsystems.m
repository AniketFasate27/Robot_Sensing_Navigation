% complete_workflow_subsystems.m
% Complete workflow with single model and subsystems

clear; clc; close all;

fprintf('\n');
fprintf('╔════════════════════════════════════════════╗\n');
fprintf('║  MOTOR FAULT DETECTION - SUBSYSTEM MODEL  ║\n');
fprintf('╚════════════════════════════════════════════╝\n');
fprintf('\n');

%% Step 1: Generate data
fprintf('STEP 1: Generating IMU data\n');
fprintf('════════════════════════════════════════════\n');
run('motor_fault_IMU_generator_all.m');

%% Step 2: Create Simulink model
fprintf('\nSTEP 2: Creating Simulink model with subsystems\n');
fprintf('════════════════════════════════════════════\n');
run('simulink_motor_fault_setup_subsystems.m');

%% Step 3: Load data and run simulation
fprintf('\nSTEP 3: Running simulation\n');
fprintf('════════════════════════════════════════════\n');

% Load data
load('IMU_data_all_conditions.mat');

% Run simulation
model_name = 'Motor_Fault_System';
fprintf('Simulating: %s\n', model_name);
simOut = sim(model_name);

fprintf('✓ Simulation complete!\n');

%% Step 4: Visualize results
fprintf('\nSTEP 4: Creating visualizations\n');
fprintf('════════════════════════════════════════════\n');

motor_conditions = {'healthy', 'imbalance', 'misalignment', 'bearing_fault'};

% Check what variables exist in workspace
fprintf('Available variables:\n');
whos accel_mag_*
fprintf('\n');

figure('Position', [100, 100, 1400, 900]);

for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    
    % Get data from workspace
    var_name = ['accel_mag_' condition];
    
    if evalin('base', ['exist(''' var_name ''', ''var'')'])
        accel_data = evalin('base', var_name);
        
        subplot(2, 2, i);
        
        % Handle timeseries data
        if isa(accel_data, 'timeseries')
            plot(accel_data.Time, accel_data.Data, 'LineWidth', 1.5);
            rms_val = rms(accel_data.Data);
            max_val = max(accel_data.Data);
        else
            plot(accel_data.time, accel_data.signals.values, 'LineWidth', 1.5);
            rms_val = rms(accel_data.signals.values);
            max_val = max(accel_data.signals.values);
        end
        
        xlabel('Time (s)');
        ylabel('Acceleration Magnitude (m/s²)');
        title(sprintf('%s Motor', upper(condition)), 'FontWeight', 'bold');
        grid on;
        
        % Statistics
        text(0.05, 0.95, sprintf('RMS: %.3f', rms_val), ...
            'Units', 'normalized', 'VerticalAlignment', 'top', 'FontWeight', 'bold');
        text(0.05, 0.88, sprintf('Max: %.3f', max_val), ...
            'Units', 'normalized', 'VerticalAlignment', 'top');
    else
        fprintf('⚠ Warning: Variable %s not found\n', var_name);
    end
end

sgtitle('Motor Fault Detection - Subsystem Model Results', 'FontSize', 16, 'FontWeight', 'bold');
saveas(gcf, 'motor_fault_subsystems_results.png');

fprintf('✓ Visualization saved\n');

%% Step 5: Save results
fprintf('\nSTEP 5: Saving results\n');
fprintf('════════════════════════════════════════════\n');

results = struct();
for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    var_name = ['accel_mag_' condition];
    
    if evalin('base', ['exist(''' var_name ''', ''var'')'])
        results.(condition).accel_mag = evalin('base', var_name);
        results.(condition).gyro_mag = evalin('base', ['gyro_mag_' condition]);
    end
end

save('motor_fault_simulation_results.mat', 'results');
fprintf('✓ Results saved to: motor_fault_simulation_results.mat\n');

fprintf('\n');
fprintf('╔════════════════════════════════════════════╗\n');
fprintf('║           WORKFLOW COMPLETE!               ║\n');
fprintf('╚════════════════════════════════════════════╝\n');
fprintf('\n');

fprintf('Summary:\n');
fprintf('  Model: %s.slx\n', model_name);
fprintf('  Data: IMU_data_all_conditions.mat\n');
fprintf('  Results: motor_fault_simulation_results.mat\n');
fprintf('  Plot: motor_fault_subsystems_results.png\n');
fprintf('\n');