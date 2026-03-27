%% EXAMPLE: Simple Command-Line Chat
% Minimal example showing TX and RX usage

clear; clc;

fprintf('Simple Command-Line Chat Example\n');
fprintf('=================================\n\n');

% Configuration
FREQ = 433e6;  % 433 MHz (ISM band)
MY_CALL = 'USER1';
THEIR_CALL = 'USER2';

% Detect and configure radios
fprintf('Detecting radios...\n');
[txSDR, rxSDR, radios] = pluto_config();

if isempty(radios)
    fprintf('ERROR: No Pluto radios detected!\n');
    return;
end

% If only one radio, use for both TX and RX
if length(radios) == 1
    [txSDR, rxSDR] = pluto_config(radios(1).RadioID, radios(1).RadioID, FREQ, -10, 30);
    fprintf('Using single radio in loopback mode\n');
else
    [txSDR, rxSDR] = pluto_config(radios(1).RadioID, radios(2).RadioID, FREQ, 0, 20);
    fprintf('Using two radios\n');
end

fprintf('\nReady! Type messages to send, or press Ctrl+C to exit.\n\n');

% Create state machine
sm = half_duplex_sm();
sm.enterReceiveMode();

% Simple chat loop
while true
    try
        % Check for incoming messages (non-blocking)
        fprintf('[RX Mode] Checking for messages...\n');
        [msg, valid, src, ~] = rx_chain(rxSDR, 2);
        
        if valid && ~isempty(msg)
            fprintf('\n>>> %s: %s\n\n', src, strtrim(msg));
        end
        
        % Prompt for user input
        userMsg = input('Your message (or ENTER to skip): ', 's');
        
        if ~isempty(userMsg)
            % Request transmit
            if sm.requestTransmit()
                fprintf('[TX Mode] Sending message...\n');
                tx_chain(userMsg, txSDR, MY_CALL, THEIR_CALL);
                sm.finishTransmit();
                fprintf('Message sent!\n\n');
            else
                fprintf('Cannot transmit right now.\n\n');
            end
        end
        
    catch ME
        if strcmp(ME.identifier, 'MATLAB:UndefinedFunction')
            fprintf('\nExiting...\n');
            break;
        else
            fprintf('Error: %s\n', ME.message);
        end
    end
end

% Cleanup
if ~isempty(txSDR)
    release(txSDR);
end
if ~isempty(rxSDR)
    release(rxSDR);
end

fprintf('Goodbye!\n');
