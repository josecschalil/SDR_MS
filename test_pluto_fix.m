%% Quick Test - Verify Pluto Detection Works
% Run this to confirm the fix

clear; clc;
fprintf('Testing Pluto Detection Fix\n');
fprintf('============================\n\n');

% Test 1: Call pluto_config with no arguments
fprintf('Test 1: Calling pluto_config() with no arguments\n');
try
    [~, ~, radios] = pluto_config();
    
    if ~isempty(radios)
        fprintf('✓ SUCCESS! Detected %d radio(s):\n', length(radios));
        for i = 1:length(radios)
            fprintf('  [%d] RadioID: %s\n', i, radios(i).RadioID);
            if isfield(radios(i), 'SerialNum')
                fprintf('      Serial: %s\n', radios(i).SerialNum);
            end
        end
    else
        fprintf('✗ No radios detected\n');
    end
catch ME
    fprintf('✗ Error: %s\n', ME.message);
end

fprintf('\n');

% Test 2: Launch GUI
fprintf('Test 2: Launching GUI...\n');
fprintf('The GUI should now detect your Pluto radio!\n');
fprintf('Click the "Detect" button to verify.\n\n');

try
    main
    fprintf('✓ GUI launched successfully!\n');
catch ME
    fprintf('✗ GUI error: %s\n', ME.message);
end
