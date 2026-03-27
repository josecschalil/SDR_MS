function success = tx_chain(message, txSDR, sourceCall, destCall)
% TX_CHAIN Complete transmission pipeline
%
% Implements: TEXT → AX.25 → AFSK → FM → Pluto SDR
%
% Inputs:
%   message    - Text message to transmit
%   txSDR      - Configured TX SDR object (from pluto_config)
%   sourceCall - Source callsign (optional, default: 'N0CALL')
%   destCall   - Destination callsign (optional, default: 'CQ')
%
% Output:
%   success - Boolean indicating transmission success

    success = false;
    
    % Default callsigns
    if nargin < 3
        sourceCall = 'N0CALL';
    end
    if nargin < 4
        destCall = 'CQ';
    end
    
    % Validate inputs
    if isempty(message)
        warning('TX Chain: Message is empty');
        return;
    end
    
    if isempty(txSDR)
        warning('TX Chain: No TX SDR configured');
        return;
    end
    
    try
        % Parameters
        fs_audio = 48000;
        fs_rf = txSDR.BasebandSampleRate;
        freqDev = 5000;
        baudRate = 1200;
        
        fprintf('\n--- TX Chain Started ---\n');
        fprintf('Message: "%s"\n', message);
        fprintf('From: %s  To: %s\n', sourceCall, destCall);
        
        % Step 1: AX.25 Encoding
        fprintf('Step 1: AX.25 encoding... ');
        bits = ax25_encode(message, sourceCall, destCall);
        fprintf('%d bits\n', length(bits));
        
        % Add preamble (alternating 1010... for clock recovery)
        preambleLen = 48; % 48 bits = ~40 ms at 1200 baud
        preamble = repmat([1 0], 1, preambleLen/2);
        
        % Add postamble
        postambleLen = 24;
        postamble = repmat([1 0], 1, postambleLen/2);
        
        bits = [preamble, bits, postamble];
        fprintf('         With preamble/postamble: %d bits\n', length(bits));
        
        % Step 2: AFSK Modulation
        fprintf('Step 2: AFSK modulation... ');
        audioSignal = afsk_mod(bits, fs_audio, baudRate);
        fprintf('%d samples (%.2f sec)\n', length(audioSignal), length(audioSignal)/fs_audio);
        
        % Step 3: FM Modulation
        fprintf('Step 3: FM modulation... ');
        fmSignal = fm_mod(audioSignal, fs_audio, fs_rf, freqDev);
        fprintf('%d samples\n', length(fmSignal));
        
        % Ensure signal is normalized for transmission
        fmSignal = 0.9 * fmSignal / max(abs(fmSignal));
        
        % Step 4: Transmit via SDR
        fprintf('Step 4: Transmitting via SDR...\n');
        
        % Add silence before and after for clean transmission
        silenceSamples = round(0.1 * fs_rf); % 100 ms silence
        silence = zeros(silenceSamples, 1);
        txSignal = [silence; fmSignal(:); silence];
        
        % Transmit
        txSDR(txSignal);
        
        fprintf('Transmission complete!\n');
        fprintf('--- TX Chain Finished ---\n\n');
        
        success = true;
        
    catch ME
        fprintf('TX Chain Error: %s\n', ME.message);
        fprintf('Stack trace:\n');
        for i = 1:length(ME.stack)
            fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
        end
        success = false;
    end
end
