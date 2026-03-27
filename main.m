% SDR-Based AX.25 Digital Chat System
% Main Entry Point
%
% This script initializes the system and launches the GUI.
%
% Usage: Run this file in MATLAB to start the application
%
% Quick Start:
%   1. Connect ADALM-Pluto SDR device(s)
%   2. Run: main() in MATLAB
%   3. Click "Detect" to find radios
%   4. Select TX and RX radios
%   5. Click "Connect"
%   6. Start chatting!

function main()
    % Clear workspace
    clc;
    
    % Display banner
    fprintf('====================================\n');
    fprintf('  SDR AX.25 Digital Chat System\n');
    fprintf('====================================\n\n');
    
    % Check for required toolboxes
    checkToolboxes();
    
    % Launch GUI
    fprintf('\nStarting SDR AX.25 Chat System...\n');
    fprintf('Launching GUI...\n\n');
    
    try
        gui_app;
    catch ME
        fprintf('Error launching GUI: %s\n', ME.message);
        fprintf('\nYou can still use the command-line interface:\n');
        fprintf('  - Use tx_chain() to transmit\n');
        fprintf('  - Use rx_chain() to receive\n');
        fprintf('  - Use pluto_config() to configure SDR\n\n');
    end
end

function checkToolboxes()
    % Check for required MATLAB toolboxes
    requiredToolboxes = {
        'Communications Toolbox'
        'DSP System Toolbox'
        'Signal Processing Toolbox'
    };
    
    fprintf('Checking for required toolboxes...\n');
    for i = 1:length(requiredToolboxes)
        if license('test', requiredToolboxes{i})
            fprintf('  ✓ %s\n', requiredToolboxes{i});
        else
            warning('  ✗ %s not found', requiredToolboxes{i});
        end
    end
    fprintf('\n');
end
