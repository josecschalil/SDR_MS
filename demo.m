%% EXAMPLE: Quick Demo Script
% Demonstrates using the SDR AX.25 system
%
% This script shows three usage scenarios:
%   1. Testing without hardware (simulation)
%   2. Single-device loopback test
%   3. Two-device communication

clear; clc;

fprintf('====================================\n');
fprintf('SDR AX.25 Chat System - Demo\n');
fprintf('====================================\n\n');

%% Scenario 1: Simulation Test (No Hardware Required)
fprintf('═══════════════════════════════════════\n');
fprintf('Scenario 1: Simulation Test\n');
fprintf('═══════════════════════════════════════\n');
fprintf('This tests the signal processing chain without SDR hardware.\n\n');

fprintf('Running test_chain.m...\n\n');
test_chain;

input('Press Enter to continue to Scenario 2...\n');

%% Scenario 2: Single-Device Loopback (1 Pluto Required)
fprintf('\n═══════════════════════════════════════\n');
fprintf('Scenario 2: Loopback Test\n');
fprintf('═══════════════════════════════════════\n');
fprintf('This uses one Pluto for both TX and RX (requires external loopback).\n\n');

fprintf('Note: Connect TX antenna to RX antenna with attenuator!\n');
proceed = input('Have you connected loopback? (y/n): ', 's');

if strcmpi(proceed, 'y')
    try
        % Detect radios
        fprintf('\nDetecting Pluto radios...\n');
        [~, ~, radios] = pluto_config();
        
        if ~isempty(radios)
            radioID = radios(1).RadioID;
            fprintf('Using radio: %s\n\n', radioID);
            
            % Configure same radio for TX and RX
            [txSDR, rxSDR] = pluto_config(radioID, radioID, 433e6, -10, 30);
            
            % Transmit message
            testMsg = 'Loopback Test 123';
            fprintf('Transmitting: "%s"\n', testMsg);
            tx_chain(testMsg, txSDR, 'TEST1', 'TEST2');
            
            % Wait for transmission to complete
            pause(2);
            
            % Receive
            fprintf('\nReceiving...\n');
            [rxMsg, valid, src, dst] = rx_chain(rxSDR, 5);
            
            % Display results
            fprintf('\n--- Results ---\n');
            fprintf('Transmitted: "%s"\n', testMsg);
            fprintf('Received: "%s"\n', rxMsg);
            fprintf('Valid: %d\n', valid);
            fprintf('From %s to %s\n', src, dst);
            
            % Cleanup
            release(txSDR);
            release(rxSDR);
            
        else
            fprintf('No Pluto radios detected.\n');
        end
    catch ME
        fprintf('Error in loopback test: %s\n', ME.message);
    end
else
    fprintf('Skipping loopback test.\n');
end

input('\nPress Enter to continue to Scenario 3...\n');

%% Scenario 3: Two-Device Communication (2 Plutos Required)
fprintf('\n═══════════════════════════════════════\n');
fprintf('Scenario 3: Two-Device Chat\n');
fprintf('═══════════════════════════════════════\n');
fprintf('This demonstrates real communication between two Pluto radios.\n\n');

proceed = input('Do you have 2 Pluto radios connected? (y/n): ', 's');

if strcmpi(proceed, 'y')
    try
        % Detect radios
        fprintf('\nDetecting Pluto radios...\n');
        [~, ~, radios] = pluto_config();
        
        if length(radios) >= 2
            radio1 = radios(1).RadioID;
            radio2 = radios(2).RadioID;
            fprintf('Radio 1 (TX): %s\n', radio1);
            fprintf('Radio 2 (RX): %s\n\n', radio2);
            
            % Configure radios
            [txSDR, rxSDR] = pluto_config(radio1, radio2, 433e6, 0, 20);
            
            % Station 1 transmits
            fprintf('=== Station 1 → Station 2 ===\n');
            msg1 = 'Hello from Station 1!';
            fprintf('TX: "%s"\n', msg1);
            tx_chain(msg1, txSDR, 'STN1', 'STN2');
            
            % Wait and receive
            pause(1);
            fprintf('\nRX: Listening...\n');
            [rxMsg1, valid1, src1, dst1] = rx_chain(rxSDR, 3);
            
            if valid1
                fprintf('✓ Received: "%s" (from %s)\n\n', rxMsg1, src1);
            else
                fprintf('✗ No message received or CRC error\n\n');
            end
            
            % Optional: Station 2 responds
            respond = input('Send response from Station 2? (y/n): ', 's');
            if strcmpi(respond, 'y')
                % Swap TX/RX
                fprintf('\n=== Station 2 → Station 1 ===\n');
                msg2 = 'Hello from Station 2!';
                fprintf('TX: "%s"\n', msg2);
                tx_chain(msg2, rxSDR, 'STN2', 'STN1');
                
                pause(1);
                fprintf('\nRX: Listening...\n');
                [rxMsg2, valid2, src2, dst2] = rx_chain(txSDR, 3);
                
                if valid2
                    fprintf('✓ Received: "%s" (from %s)\n', rxMsg2, src2);
                else
                    fprintf('✗ No message received or CRC error\n');
                end
            end
            
            % Cleanup
            release(txSDR);
            release(rxSDR);
            
        else
            fprintf('Need 2 Pluto radios, found %d.\n', length(radios));
        end
    catch ME
        fprintf('Error in two-device test: %s\n', ME.message);
    end
else
    fprintf('Skipping two-device test.\n');
end

%% Summary
fprintf('\n════════════════════════════════════════\n');
fprintf('Demo Complete!\n');
fprintf('════════════════════════════════════════\n');
fprintf('\nNext steps:\n');
fprintf('  • Run main() to launch the GUI\n');
fprintf('  • Experiment with different frequencies\n');
fprintf('  • Try longer messages\n');
fprintf('  • Test at different distances\n\n');
fprintf('For full documentation, see USER_GUIDE.md\n');
