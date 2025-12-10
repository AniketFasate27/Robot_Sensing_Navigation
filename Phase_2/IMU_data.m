%% Simulink IMU Model Setup - Using Pre-generated Data
% This script creates a Simulink model that imports IMU data from workspace
% Run the IMU data generator script FIRST before running this!

% Check if data exists
if ~exist('accel_true_ts', 'var')
    error('IMU data not found! Run the IMU_data_generator script first, or load IMU_data.mat');
end

%% Create New Simulink Model
modelName = 'IMU_From_Workspace';
close_system(modelName, 0);  % Close if already open
new_system(modelName);
open_system(modelName);

fprintf('Creating Simulink model: %s\n', modelName);

%% Method 1: Using From Workspace Blocks (Simplest)

fprintf('Adding From Workspace blocks...\n');

% Add From Workspace blocks for inputs
add_block('simulink/Sources/From Workspace', [modelName '/Accel_True'], ...
    'VariableName', 'accel_true_ts', ...
    'Position', [50, 50, 150, 80]);

add_block('simulink/Sources/From Workspace', [modelName '/Gyro_True'], ...
    'VariableName', 'gyro_true_ts', ...
    'Position', [50, 120, 150, 150]);

add_block('simulink/Sources/From Workspace', [modelName '/Orientation'], ...
    'VariableName', 'quat_ts', ...
    'Position', [50, 190, 150, 220]);

% Add IMU block
add_block('nav/IMU', [modelName '/IMU'], ...
    'Position', [250, 100, 350, 200]);

% Add Scope blocks for outputs
add_block('simulink/Sinks/Scope', [modelName '/Accel_Output'], ...
    'Position', [450, 90, 480, 120]);

add_block('simulink/Sinks/Scope', [modelName '/Gyro_Output'], ...
    'Position', [450, 150, 480, 180]);

% Connect blocks
add_line(modelName, 'Accel_True/1', 'IMU/1', 'autorouting', 'on');
add_line(modelName, 'Gyro_True/1', 'IMU/2', 'autorouting', 'on');
add_line(modelName, 'Orientation/1', 'IMU/3', 'autorouting', 'on');
add_line(modelName, 'IMU/1', 'Accel_Output/1', 'autorouting', 'on');
add_line(modelName, 'IMU/2', 'Gyro_Output/1', 'autorouting', 'on');

%% Method 2: Compare True vs Measured (Alternative Layout)

fprintf('Creating comparison model...\n');

modelName2 = 'IMU_Comparison';
close_system(modelName2, 0);
new_system(modelName2);
open_system(modelName2);

% True data inputs
add_block('simulink/Sources/From Workspace', [modelName2 '/Accel_True'], ...
    'VariableName', 'accel_true_ts', ...
    'Position', [50, 50, 150, 80]);

add_block('simulink/Sources/From Workspace', [modelName2 '/Gyro_True'], ...
    'VariableName', 'gyro_true_ts', ...
    'Position', [50, 120, 150, 150]);

% Measured data (pre-generated with sensor errors)
add_block('simulink/Sources/From Workspace', [modelName2 '/Accel_Measured'], ...
    'VariableName', 'accel_measured_ts', ...
    'Position', [50, 250, 150, 280]);

add_block('simulink/Sources/From Workspace', [modelName2 '/Gyro_Measured'], ...
    'VariableName', 'gyro_measured_ts', ...
    'Position', [50, 320, 150, 350]);

% Add comparison scopes
add_block('simulink/Sinks/Scope', [modelName2 '/Accel_Comparison'], ...
    'Position', [250, 50, 280, 80], ...
    'NumInputPorts', '2');

add_block('simulink/Sinks/Scope', [modelName2 '/Gyro_Comparison'], ...
    'Position', [250, 120, 280, 150], ...
    'NumInputPorts', '2');

% Connect comparison
add_line(modelName2, 'Accel_True/1', 'Accel_Comparison/1', 'autorouting', 'on');
add_line(modelName2, 'Accel_Measured/1', 'Accel_Comparison/2', 'autorouting', 'on');
add_line(modelName2, 'Gyro_True/1', 'Gyro_Comparison/1', 'autorouting', 'on');
add_line(modelName2, 'Gyro_Measured/1', 'Gyro_Comparison/2', 'autorouting', 'on');

%% Configure Simulation Parameters for Both Models

for mdl = {modelName, modelName2}
    % Set solver
    set_param(mdl{1}, 'Solver', 'FixedStepDiscrete');
    set_param(mdl{1}, 'FixedStep', num2str(dt));
    set_param(mdl{1}, 'StopTime', num2str(max(t)));
    
    % Set data import/export
    set_param(mdl{1}, 'LoadExternalInput', 'off');
    set_param(mdl{1}, 'LoadInitialState', 'off');
end

%% Save Models
save_system(modelName);
save_system(modelName2);

fprintf('\n=== Simulink Models Created Successfully ===\n');
fprintf('Model 1: %s.slx\n', modelName);
fprintf('  - Uses IMU block with pre-generated true data\n');
fprintf('  - IMU block adds sensor imperfections\n');
fprintf('\nModel 2: %s.slx\n', modelName2);
fprintf('  - Compares true vs measured data\n');
fprintf('  - Uses pre-generated measurements from MATLAB\n');

fprintf('\n=== To Run ===\n');
fprintf('1. Make sure IMU data is in workspace (run generator script)\n');
fprintf('2. Open either model\n');
fprintf('3. Press Ctrl+T or click Run button\n');
fprintf('4. Double-click Scope blocks to view results\n');

fprintf('\n=== Troubleshooting ===\n');
fprintf('If "From Workspace" error occurs:\n');
fprintf('  - Verify variables exist: whos accel_true_ts gyro_true_ts quat_ts\n');
fprintf('  - Or load from file: load(''IMU_data.mat'')\n');

%% Optional: Create a Dashboard Model with Live Controls

modelName3 = 'IMU_Dashboard';
close_system(modelName3, 0);
new_system(modelName3);
open_system(modelName3);

fprintf('\nCreating dashboard model with controls...\n');

% Add from workspace blocks
add_block('simulink/Sources/From Workspace', [modelName3 '/Accel_Data'], ...
    'VariableName', 'accel_measured_ts', ...
    'Position', [50, 100, 150, 130]);

add_block('simulink/Sources/From Workspace', [modelName3 '/Gyro_Data'], ...
    'VariableName', 'gyro_measured_ts', ...
    'Position', [50, 170, 150, 200]);

% Add Dashboard Scope blocks (if available)
try
    add_block('simulink/Dashboard/Dashboard Scope', [modelName3 '/Accel_Display'], ...
        'Position', [250, 50, 450, 150]);
    add_block('simulink/Dashboard/Dashboard Scope', [modelName3 '/Gyro_Display'], ...
        'Position', [250, 200, 450, 300]);
    
    add_line(modelName3, 'Accel_Data/1', 'Accel_Display/1', 'autorouting', 'on');
    add_line(modelName3, 'Gyro_Data/1', 'Gyro_Display/1', 'autorouting', 'on');
    
    set_param(modelName3, 'Solver', 'FixedStepDiscrete');
    set_param(modelName3, 'FixedStep', num2str(dt));
    set_param(modelName3, 'StopTime', num2str(max(t)));
    
    save_system(modelName3);
    fprintf('Dashboard model created: %s.slx\n', modelName3);
catch
    fprintf('Dashboard blocks not available in your Simulink version.\n');
    close_system(modelName3, 0);
end

fprintf('\n=== All Done! ===\n');
fprintf('Open %s.slx and press Run!\n', modelName);