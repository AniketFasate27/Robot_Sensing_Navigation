% main_workflow.m
% Motor Fault Detection - MATLAB/Simulink Project

clear; clc; close all;

fprintf('\n');
fprintf('╔════════════════════════════════════════════════════╗\n');
fprintf('║  MOTOR FAULT DETECTION - MATLAB/SIMULINK PROJECT  ║\n');
fprintf('║  EECE 5554 - Robot Sensing and Navigation         ║\n');
fprintf('╚════════════════════════════════════════════════════╝\n');
fprintf('\n');

%% Set base path
base_path = 'C:\Users\anifa\Downloads\Simulink\RSN\Final\final2';
addpath(genpath(base_path));
cd(base_path);
fprintf('Working directory: %s\n\n', base_path);

% Create folders
if ~exist(fullfile(base_path, 'Data'), 'dir'), mkdir(fullfile(base_path, 'Data')); end
if ~exist(fullfile(base_path, 'Models'), 'dir'), mkdir(fullfile(base_path, 'Models')); end
if ~exist(fullfile(base_path, 'Results'), 'dir'), mkdir(fullfile(base_path, 'Results')); end

%% Configuration
config = struct();
config.motor_conditions = {'healthy', 'imbalance', 'misalignment', 'bearing_fault'};
config.Fs = 100;
config.duration = 30;
config.window_size = 1000;
config.step_size = 500;
config.num_features = 144;
config.base_path = base_path;

%% STEP 1: Generate Motor Data
fprintf('══════════════════════════════════════════════════════\n');
fprintf('STEP 1: Generating Synthetic Motor Data\n');
fprintf('══════════════════════════════════════════════════════\n\n');

motor_fault_IMU_generator_all(config);

%% STEP 2: Create Simulink Model
fprintf('\n══════════════════════════════════════════════════════\n');
fprintf('STEP 2: Creating Simulink Model\n');
fprintf('══════════════════════════════════════════════════════\n\n');

simulink_motor_fault_setup(config);

%% STEP 3: Run Simulations
fprintf('\n══════════════════════════════════════════════════════\n');
fprintf('STEP 3: Running Simulink Simulations\n');
fprintf('══════════════════════════════════════════════════════\n\n');

% Load data
data_file = fullfile(base_path, 'Data', 'IMU_data_all_conditions.mat');
if exist(data_file, 'file')
    load(data_file);
    fprintf('✓ Data loaded from: %s\n', data_file);
else
    error('Data file not found: %s', data_file);
end

% Make sure we're in base_path for simulation
cd(base_path);

model_name = 'Motor_Fault_System';
fprintf('Simulating model: %s\n', model_name);

try
    % Run with output capture
    simOut = sim(model_name, 'ReturnWorkspaceOutputs', 'on');
    fprintf('✓ Simulation complete!\n');
    
    % Check what was created
    fprintf('\nChecking simulation outputs:\n');
    evalin('base', 'whos *mag*');
    
catch ME
    fprintf('✗ Simulation error: %s\n', ME.message);
    return;
end

%% STEP 4: Extract Features
fprintf('\n══════════════════════════════════════════════════════\n');
fprintf('STEP 4: Extracting Features\n');
fprintf('══════════════════════════════════════════════════════\n\n');

features_data = extract_features_simulink(config);

%% STEP 5: Train ML Models
fprintf('\n══════════════════════════════════════════════════════\n');
fprintf('STEP 5: Training Machine Learning Models\n');
fprintf('══════════════════════════════════════════════════════\n\n');

ml_results = train_all_models(features_data);

%% STEP 6: Visualize
fprintf('\n══════════════════════════════════════════════════════\n');
fprintf('STEP 6: Creating Visualizations\n');
fprintf('══════════════════════════════════════════════════════\n\n');

visualize_results(ml_results, features_data);
compare_conditions(config);

%% Summary
fprintf('\n╔════════════════════════════════════════════════════╗\n');
fprintf('║              PROJECT COMPLETE!                     ║\n');
fprintf('╚════════════════════════════════════════════════════╝\n\n');

fprintf('RESULTS SUMMARY:\n');
fprintf('────────────────────────────────────────────────────────\n');
fprintf('Total Training Samples:  %d\n', size(features_data.features, 1));
fprintf('Features per Sample:     %d\n', config.num_features);
fprintf('Training Set Size:       %d\n', ml_results.train_size);
fprintf('Test Set Size:           %d\n', ml_results.test_size);
fprintf('Best Model:              %s\n', ml_results.best_model_name);
fprintf('Test Accuracy:           %.2f%%\n', ml_results.best_accuracy * 100);
fprintf('────────────────────────────────────────────────────────\n\n');

cd(base_path);