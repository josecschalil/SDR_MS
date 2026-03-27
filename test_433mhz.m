%% Test with 433 MHz (should work immediately)

clear; clc;
fprintf('Testing with 433 MHz (ISM Band)\n');
fprintf('================================\n\n');

% Test transmission at 433 MHz
fprintf('Step 1: Configuring at 433 MHz... ');
try
    [tx, rx] = pluto_config('usb:0', 'usb:0', 433e6, -10, 30);
    fprintf('✓\n');
catch ME
    fprintf('✗ Error: %s\n', ME.message);
    return;
end

fprintf('Step 2: Creating test signal... ');
fs = tx.BasebandSampleRate;
t = (0:1000-1) / fs;
sig = 0.5 * exp(1j * 2 * pi * 1000 * t);
fprintf('✓\n');

fprintf('Step 3: Transmitting at 433 MHz... ');
try
    tx(sig(:));
    fprintf('✓ SUCCESS!\n\n');
    fprintf('═══════════════════════════════════\n');
    fprintf('  433 MHz WORKS! ✓\n');
    fprintf('═══════════════════════════════════\n\n');
    fprintf('Now try the GUI:\n');
    fprintf('  >> main\n\n');
    fprintf('It will use 433 MHz by default.\n');
catch ME
    fprintf('✗ Failed: %s\n', ME.message);
end

% Cleanup
release(tx);
release(rx);
