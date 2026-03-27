%% SIMPLE TX TEST - Minimal test to isolate issue

clear; clc;
fprintf('Simple TX Test\n');
fprintf('==============\n\n');

% Step 1: Create TX object
fprintf('Creating TX object... ');
try
    % Try method 1: sdrtx
    if exist('sdrtx', 'file')
        tx = sdrtx('Pluto', 'RadioID', 'usb:0');
        fprintf('✓ (sdrtx)\n');
    elseif exist('comm.SDRTxPluto', 'class')
        tx = comm.SDRTxPluto('RadioID', 'usb:0');
        fprintf('✓ (comm.SDRTxPluto)\n');
    else
        fprintf('✗ No TX function available\n');
        return;
    end
catch ME
    fprintf('✗ Error: %s\n', ME.message);
    return;
end

% Step 2: Configure
fprintf('Configuring... ');
try
    tx.CenterFrequency = 145e6;
    tx.BasebandSampleRate = 2.4e6;
    tx.Gain = -10;
    fprintf('✓\n');
catch ME
    fprintf('✗ Error: %s\n', ME.message);
    return;
end

% Step 3: Check properties
fprintf('\nTX Properties:\n');
fprintf('  Class: %s\n', class(tx));
fprintf('  Frequency: %.2f MHz\n', tx.CenterFrequency/1e6);
fprintf('  Sample Rate: %.2f Msps\n', tx.BasebandSampleRate/1e6);
fprintf('  Gain: %d dB\n', tx.Gain);

% Step 4: Create simple signal
fprintf('\nCreating test signal... ');
try
    fs = tx.BasebandSampleRate;
    duration = 0.1; % 100ms
    numSamples = round(duration * fs);
    t = (0:numSamples-1) / fs;
    
    % Simple 1 kHz tone
    signal = 0.5 * exp(1j * 2 * pi * 1000 * t);
    signal = signal(:); % Column vector
    
    fprintf('✓ (%d samples)\n', length(signal));
catch ME
    fprintf('✗ Error: %s\n', ME.message);
    return;
end

% Step 5: Transmit
fprintf('Transmitting... ');
try
    % Check if it's a System Object or function-based
    if isa(tx, 'comm.SDRTxPluto')
        % System Object - use step or call
        if isprop(tx, 'isLocked')
            fprintf('(System Object) ');
        end
        tx(signal); % Call method
    else
        % Function-based sdrtx
        fprintf('(function-based) ');
        tx(signal);
    end
    
    fprintf('✓ SUCCESS!\n');
    fprintf('\nTransmission worked! The issue might be in tx_chain.m\n');
    
catch ME
    fprintf('✗ FAILED\n');
    fprintf('\nError: %s\n', ME.message);
    fprintf('\nThis is the problem! Details:\n');
    disp(ME);
    
    % Common fixes
    fprintf('\nPossible Solutions:\n');
    fprintf('1. If error is about signal size:\n');
    fprintf('   - Ensure signal is column vector: signal(:)\n');
    fprintf('   - Check sample count is reasonable\n\n');
    
    fprintf('2. If error is about data type:\n');
    fprintf('   - Ensure complex double: complex(double(signal))\n\n');
    
    fprintf('3. If error is about device:\n');
    fprintf('   - Release and recreate: release(tx); tx = sdrtx(...)\n\n');
    
    fprintf('4. If error mentions "locked":\n');
    fprintf('   - Release first: release(tx)\n\n');
end

% Cleanup
fprintf('\nCleaning up... ');
try
    if isa(tx, 'comm.SDRTxPluto') || isa(tx, 'matlab.System')
        release(tx);
    end
    fprintf('✓\n');
catch
    fprintf('(no cleanup needed)\n');
end

fprintf('\n=== Test Complete ===\n');
