%% DEBUG TRANSMISSION ISSUE
% Run this to test TX chain step-by-step

clear; clc;
fprintf('====================================\n');
fprintf('Debugging Transmission Failure\n');
fprintf('====================================\n\n');

%% Step 1: Detect and configure Pluto
fprintf('Step 1: Detecting and configuring Pluto...\n');
try
    [txSDR, rxSDR, radios] = pluto_config('usb:0', 'usb:0', 145e6, -10, 30);
    
    if ~isempty(txSDR) && ~isempty(rxSDR)
        fprintf('✓ SDR configured successfully\n');
        fprintf('  TX: %s\n', class(txSDR));
        fprintf('  RX: %s\n', class(rxSDR));
    else
        fprintf('✗ Configuration failed\n');
        return;
    end
catch ME
    fprintf('✗ Configuration error: %s\n', ME.message);
    fprintf('Stack:\n');
    disp(ME.stack);
    return;
end

fprintf('\n');

%% Step 2: Test each component individually
fprintf('Step 2: Testing signal processing components...\n');

% Test AX.25 encoding
fprintf('  Testing AX.25 encoding... ');
try
    testMsg = 'Test';
    bits = ax25_encode(testMsg, 'TEST1', 'TEST2');
    fprintf('✓ (%d bits)\n', length(bits));
catch ME
    fprintf('✗ Error: %s\n', ME.message);
    return;
end

% Test AFSK modulation
fprintf('  Testing AFSK modulation... ');
try
    fs = 48000;
    audioSignal = afsk_mod(bits, fs, 1200);
    fprintf('✓ (%d samples)\n', length(audioSignal));
catch ME
    fprintf('✗ Error: %s\n', ME.message);
    return;
end

% Test FM modulation
fprintf('  Testing FM modulation... ');
try
    fs_rf = txSDR.BasebandSampleRate;
    fmSignal = fm_mod(audioSignal, fs, fs_rf, 5000);
    fprintf('✓ (%d samples)\n', length(fmSignal));
catch ME
    fprintf('✗ Error: %s\n', ME.message);
    return;
end

fprintf('\n');

%% Step 3: Check SDR object properties
fprintf('Step 3: Checking SDR configuration...\n');
try
    fprintf('  TX SDR Properties:\n');
    fprintf('    Class: %s\n', class(txSDR));
    fprintf('    Center Frequency: %.2f MHz\n', txSDR.CenterFrequency/1e6);
    fprintf('    Sample Rate: %.2f Msps\n', txSDR.BasebandSampleRate/1e6);
    fprintf('    Gain: %d dB\n', txSDR.Gain);
    
    % Check if object is locked
    if isprop(txSDR, 'isLocked')
        fprintf('    Locked: %d\n', txSDR.isLocked);
    end
catch ME
    fprintf('  ✗ Error reading properties: %s\n', ME.message);
end

fprintf('\n');

%% Step 4: Try simple transmission test
fprintf('Step 4: Testing transmission...\n');
fprintf('  Preparing signal... ');

try
    % Create simple test signal
    testDuration = 0.1; % 100ms
    fs_rf = txSDR.BasebandSampleRate;
    numSamples = round(testDuration * fs_rf);
    
    % Simple tone at 1 kHz
    t = (0:numSamples-1) / fs_rf;
    testTone = 0.5 * exp(1j * 2 * pi * 1000 * t);
    
    fprintf('✓ (%d samples)\n', length(testTone));
    
    fprintf('  Transmitting... ');
    txSDR(testTone(:));
    fprintf('✓ Success!\n');
    
catch ME
    fprintf('✗ Error: %s\n', ME.message);
    fprintf('\n  Full error details:\n');
    disp(ME);
    fprintf('\n  Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('    %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end

fprintf('\n');

%% Step 5: Try full TX chain
fprintf('Step 5: Testing full tx_chain function...\n');
fprintf('  Calling tx_chain... ');

try
    success = tx_chain('Test Message', txSDR, 'TEST1', 'TEST2');
    
    if success
        fprintf('✓ tx_chain succeeded!\n');
    else
        fprintf('✗ tx_chain returned false\n');
    end
catch ME
    fprintf('✗ tx_chain error: %s\n', ME.message);
    fprintf('\n  Full error details:\n');
    disp(ME);
    fprintf('\n  Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('    %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end

fprintf('\n');

%% Summary
fprintf('====================================\n');
fprintf('Diagnosis Complete\n');
fprintf('====================================\n');
fprintf('\nCheck the output above to identify where the failure occurs.\n');
fprintf('Common issues:\n');
fprintf('  • SDR object is locked (need to release)\n');
fprintf('  • Sample rate mismatch\n');
fprintf('  • Signal amplitude too high/low\n');
fprintf('  • Missing ShowAdvancedProperties\n');
fprintf('  • Transmit buffer size issues\n');

% Cleanup
release(txSDR);
release(rxSDR);
