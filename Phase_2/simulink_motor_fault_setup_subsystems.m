% simulink_motor_fault_setup_subsystems.m
% Creates ONE Simulink model with subsystems for each motor fault condition

clear; clc;

fprintf('==============================================\n');
fprintf('CREATING SINGLE SIMULINK MODEL WITH SUBSYSTEMS\n');
fprintf('==============================================\n\n');

motor_conditions = {'healthy', 'imbalance', 'misalignment', 'bearing_fault'};
model_name = 'Motor_Fault_System';  % Shorter name to avoid shadowing

%% Close if already open
if bdIsLoaded(model_name)
    close_system(model_name, 0);
end

%% Create main model
new_system(model_name);
open_system(model_name);

% Configure solver
set_param(model_name, 'Solver', 'ode4');
set_param(model_name, 'FixedStep', '0.01');  % 100 Hz
set_param(model_name, 'StopTime', '10');

fprintf('Creating main model: %s\n', model_name);

%% Create subsystems for each motor condition
y_positions = [50, 250, 450, 650];  % Vertical positions for subsystems

for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    subsys_name = [model_name '/' upper(condition)];
    
    fprintf('  Creating subsystem: %s\n', condition);
    
    % Create subsystem
    add_block('built-in/Subsystem', subsys_name);
    set_param(subsys_name, 'Position', [300, y_positions(i), 400, y_positions(i)+80]);
    
    % Delete default ports in subsystem
    Simulink.SubSystem.deleteContents(subsys_name);
    
    %% Add blocks inside subsystem
    
    % Input ports
    add_block('simulink/Sources/In1', [subsys_name '/Accel_In']);
    set_param([subsys_name '/Accel_In'], 'Position', [30, 30, 60, 50]);
    
    add_block('simulink/Sources/In1', [subsys_name '/Gyro_In']);
    set_param([subsys_name '/Gyro_In'], 'Port', '2');
    set_param([subsys_name '/Gyro_In'], 'Position', [30, 90, 60, 110]);
    
    % Processing: Calculate magnitude
    add_block('simulink/Math Operations/Sqrt', [subsys_name '/Accel_Sqrt']);
    set_param([subsys_name '/Accel_Sqrt'], 'Position', [200, 30, 230, 50]);
    
    add_block('simulink/Math Operations/Sqrt', [subsys_name '/Gyro_Sqrt']);
    set_param([subsys_name '/Gyro_Sqrt'], 'Position', [200, 90, 230, 110]);
    
    % Dot product for magnitude (sum of squares)
    add_block('simulink/Math Operations/Dot Product', [subsys_name '/Accel_DotProd']);
    set_param([subsys_name '/Accel_DotProd'], 'Position', [130, 25, 160, 55]);
    
    add_block('simulink/Math Operations/Dot Product', [subsys_name '/Gyro_DotProd']);
    set_param([subsys_name '/Gyro_DotProd'], 'Position', [130, 85, 160, 115]);
    
    % Output ports
    add_block('simulink/Sinks/Out1', [subsys_name '/Accel_Mag_Out']);
    set_param([subsys_name '/Accel_Mag_Out'], 'Position', [280, 30, 310, 50]);
    
    add_block('simulink/Sinks/Out1', [subsys_name '/Gyro_Mag_Out']);
    set_param([subsys_name '/Gyro_Mag_Out'], 'Port', '2');
    set_param([subsys_name '/Gyro_Mag_Out'], 'Position', [280, 90, 310, 110]);
    
    % Connect blocks inside subsystem
    add_line(subsys_name, 'Accel_In/1', 'Accel_DotProd/1');
    add_line(subsys_name, 'Accel_In/1', 'Accel_DotProd/2');
    add_line(subsys_name, 'Accel_DotProd/1', 'Accel_Sqrt/1');
    add_line(subsys_name, 'Accel_Sqrt/1', 'Accel_Mag_Out/1');
    
    add_line(subsys_name, 'Gyro_In/1', 'Gyro_DotProd/1');
    add_line(subsys_name, 'Gyro_In/1', 'Gyro_DotProd/2');
    add_line(subsys_name, 'Gyro_DotProd/1', 'Gyro_Sqrt/1');
    add_line(subsys_name, 'Gyro_Sqrt/1', 'Gyro_Mag_Out/1');
    
    %% Add input blocks in main model
    
    % From Workspace - Acceleration
    var_name = sprintf('Acceleration_%s', condition);
    add_block('simulink/Sources/From Workspace', [model_name '/Accel_' condition]);
    set_param([model_name '/Accel_' condition], 'VariableName', var_name);
    set_param([model_name '/Accel_' condition], 'Position', [50, y_positions(i), 150, y_positions(i)+30]);
    
    % From Workspace - Angular Velocity
    var_name = sprintf('AngularVelocity_%s', condition);
    add_block('simulink/Sources/From Workspace', [model_name '/Gyro_' condition]);
    set_param([model_name '/Gyro_' condition], 'VariableName', var_name);
    set_param([model_name '/Gyro_' condition], 'Position', [50, y_positions(i)+40, 150, y_positions(i)+70]);
    
    % Connect inputs to subsystem
    add_line(model_name, ['Accel_' condition '/1'], [upper(condition) '/1']);
    add_line(model_name, ['Gyro_' condition '/1'], [upper(condition) '/2']);
    
    %% Add output blocks
    
    % Scope for visualization
    add_block('simulink/Sinks/Scope', [model_name '/Scope_' condition]);
    set_param([model_name '/Scope_' condition], 'Position', [480, y_positions(i)+10, 530, y_positions(i)+60]);
    set_param([model_name '/Scope_' condition], 'NumInputPorts', '2');
    add_line(model_name, [upper(condition) '/1'], ['Scope_' condition '/1']);
    add_line(model_name, [upper(condition) '/2'], ['Scope_' condition '/2']);
    
    % To Workspace for data export - FIXED VARIABLE NAMES
    add_block('simulink/Sinks/To Workspace', [model_name '/Out_Accel_' condition]);
    set_param([model_name '/Out_Accel_' condition], 'VariableName', ['accel_mag_' condition]);
    set_param([model_name '/Out_Accel_' condition], 'SaveFormat', 'Timeseries');
    set_param([model_name '/Out_Accel_' condition], 'Position', [570, y_positions(i), 660, y_positions(i)+20]);
    add_line(model_name, [upper(condition) '/1'], ['Out_Accel_' condition '/1']);
    
    add_block('simulink/Sinks/To Workspace', [model_name '/Out_Gyro_' condition]);
    set_param([model_name '/Out_Gyro_' condition], 'VariableName', ['gyro_mag_' condition]);
    set_param([model_name '/Out_Gyro_' condition], 'SaveFormat', 'Timeseries');
    set_param([model_name '/Out_Gyro_' condition], 'Position', [570, y_positions(i)+30, 660, y_positions(i)+50]);
    add_line(model_name, [upper(condition) '/2'], ['Out_Gyro_' condition '/1']);
end

%% Save model
save_system(model_name);

fprintf('\n==============================================\n');
fprintf('SIMULINK MODEL CREATED!\n');
fprintf('==============================================\n');
fprintf('Model: %s.slx\n', model_name);
fprintf('Subsystems:\n');
for i = 1:length(motor_conditions)
    fprintf('  - %s\n', upper(motor_conditions{i}));
end
fprintf('\nTo run simulation:\n');
fprintf('  1. Load data: load(''IMU_data_all_conditions.mat'')\n');
fprintf('  2. Run: sim(''%s'')\n', model_name);
fprintf('==============================================\n\n');