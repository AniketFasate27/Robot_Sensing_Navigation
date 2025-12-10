function simulink_motor_fault_setup(config)
% SIMULINK_MOTOR_FAULT_SETUP
% Creates Simulink model with subsystems for each motor fault condition

fprintf('Creating Simulink model with subsystems...\n\n');

model_name = 'Motor_Fault_System';
motor_conditions = config.motor_conditions;

% Get base path
if isfield(config, 'base_path')
    base_path = config.base_path;
else
    base_path = pwd;
end

%% Close existing model
if bdIsLoaded(model_name)
    close_system(model_name, 0);
end

%% Create new model
new_system(model_name);
open_system(model_name);

%% Configure solver
set_param(model_name, 'Solver', 'ode4');
set_param(model_name, 'FixedStep', num2str(1/config.Fs));
set_param(model_name, 'StopTime', num2str(config.duration));

fprintf('  Model name: %s\n', model_name);
fprintf('  Solver: Fixed-step (ode4)\n');
fprintf('  Sample time: %.4f s (%.0f Hz)\n', 1/config.Fs, config.Fs);
fprintf('  Duration: %.0f s\n\n', config.duration);

%% Create subsystems
y_positions = [50, 250, 450, 650];

for i = 1:length(motor_conditions)
    condition = motor_conditions{i};
    fprintf('  Creating subsystem: %-15s... ', condition);
    
    subsys_name = [model_name '/' upper(condition)];
    
    % Create subsystem block
    add_block('built-in/Subsystem', subsys_name);
    set_param(subsys_name, 'Position', [300, y_positions(i), 400, y_positions(i)+80]);
    
    % Clear default contents
    Simulink.SubSystem.deleteContents(subsys_name);
    
    %% Build subsystem internals
    % Input ports
    add_block('simulink/Sources/In1', [subsys_name '/Accel_In']);
    set_param([subsys_name '/Accel_In'], 'Position', [30, 30, 60, 50]);
    
    add_block('simulink/Sources/In1', [subsys_name '/Gyro_In']);
    set_param([subsys_name '/Gyro_In'], 'Port', '2');
    set_param([subsys_name '/Gyro_In'], 'Position', [30, 90, 60, 110]);
    
    % Calculate acceleration magnitude
    add_block('simulink/Math Operations/Dot Product', [subsys_name '/Accel_DotProd']);
    set_param([subsys_name '/Accel_DotProd'], 'Position', [130, 25, 160, 55]);
    
    add_block('simulink/Math Operations/Sqrt', [subsys_name '/Accel_Sqrt']);
    set_param([subsys_name '/Accel_Sqrt'], 'Position', [200, 30, 230, 50]);
    
    % Calculate gyroscope magnitude
    add_block('simulink/Math Operations/Dot Product', [subsys_name '/Gyro_DotProd']);
    set_param([subsys_name '/Gyro_DotProd'], 'Position', [130, 85, 160, 115]);
    
    add_block('simulink/Math Operations/Sqrt', [subsys_name '/Gyro_Sqrt']);
    set_param([subsys_name '/Gyro_Sqrt'], 'Position', [200, 90, 230, 110]);
    
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
    
    %% Add blocks in main model
    % From Workspace - Acceleration
    add_block('simulink/Sources/From Workspace', [model_name '/Accel_' condition]);
    set_param([model_name '/Accel_' condition], 'VariableName', sprintf('Acceleration_%s', condition));
    set_param([model_name '/Accel_' condition], 'Position', [50, y_positions(i), 150, y_positions(i)+30]);
    
    % From Workspace - Gyroscope
    add_block('simulink/Sources/From Workspace', [model_name '/Gyro_' condition]);
    set_param([model_name '/Gyro_' condition], 'VariableName', sprintf('AngularVelocity_%s', condition));
    set_param([model_name '/Gyro_' condition], 'Position', [50, y_positions(i)+40, 150, y_positions(i)+70]);
    
    % Connect to subsystem
    add_line(model_name, ['Accel_' condition '/1'], [upper(condition) '/1']);
    add_line(model_name, ['Gyro_' condition '/1'], [upper(condition) '/2']);
    
    % Scope for visualization
    add_block('simulink/Sinks/Scope', [model_name '/Scope_' condition]);
    set_param([model_name '/Scope_' condition], 'Position', [480, y_positions(i)+10, 530, y_positions(i)+60]);
    set_param([model_name '/Scope_' condition], 'NumInputPorts', '2');
    add_line(model_name, [upper(condition) '/1'], ['Scope_' condition '/1']);
    add_line(model_name, [upper(condition) '/2'], ['Scope_' condition '/2']);
    
    % CRITICAL: To Workspace blocks - SAVE TO BASE_PATH, not current folder
    add_block('simulink/Sinks/To Workspace', [model_name '/Out_Accel_' condition]);
    set_param([model_name '/Out_Accel_' condition], 'VariableName', ['accel_mag_' condition]);
    set_param([model_name '/Out_Accel_' condition], 'SaveFormat', 'Array');
    set_param([model_name '/Out_Accel_' condition], 'MaxDataPoints', 'inf');
    set_param([model_name '/Out_Accel_' condition], 'Decimation', '1');
    set_param([model_name '/Out_Accel_' condition], 'SampleTime', '-1');
    set_param([model_name '/Out_Accel_' condition], 'Position', [570, y_positions(i), 660, y_positions(i)+20]);
    add_line(model_name, [upper(condition) '/1'], ['Out_Accel_' condition '/1']);
    
    add_block('simulink/Sinks/To Workspace', [model_name '/Out_Gyro_' condition]);
    set_param([model_name '/Out_Gyro_' condition], 'VariableName', ['gyro_mag_' condition]);
    set_param([model_name '/Out_Gyro_' condition], 'SaveFormat', 'Array');
    set_param([model_name '/Out_Gyro_' condition], 'MaxDataPoints', 'inf');
    set_param([model_name '/Out_Gyro_' condition], 'Decimation', '1');
    set_param([model_name '/Out_Gyro_' condition], 'SampleTime', '-1');
    set_param([model_name '/Out_Gyro_' condition], 'Position', [570, y_positions(i)+30, 660, y_positions(i)+50]);
    add_line(model_name, [upper(condition) '/2'], ['Out_Gyro_' condition '/1']);
    
    fprintf('✓\n');
end

%% CRITICAL: Save model to BASE_PATH (not subfolder!)
model_file = fullfile(base_path, [model_name '.slx']);
save_system(model_name, model_file);
fprintf('\n✓ Simulink model created: %s\n', model_file);

end