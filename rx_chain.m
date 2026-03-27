function [message, valid, sourceCall, destCall] = rx_chain(rxSDR, duration)
% RX_CHAIN Complete reception pipeline
%
% Implements: Pluto SDR → FM Demod → AFSK Demod → AX.25 Decode → TEXT
%
% Inputs:
%   rxSDR    - Configured RX SDR object (from pluto_config)
%   duration - Reception duration in seconds (default: 5)
%
% Outputs:
%   message    - Decoded text message (empty if none received)
%   valid      - Boolean indicating if frame is valid
%   sourceCall - Source callsign
%   destCall   - Destination callsign

    message = '';
    valid = false;
    sourceCall = '';
    destCall = '';
    
    % Default duration
    if nargin < 2
        duration = 5;
    end
    
    % Validate inputs
    if isempty(rxSDR)
        warning('RX Chain: No RX SDR configured');
        return;
    end
    
    try
        % Parameters
        fs_audio = 48000;
        fs_rf = rxSDR.BasebandSampleRate;
        freqDev = 5000;
        baudRate = 1200;
        
        fprintf('\n--- RX Chain Started ---\n');
        fprintf('Listening for %.1f seconds...\n', duration);
        
        % Calculate total samples to receive
        totalSamples = round(duration * fs_rf);
        samplesPerFrame = rxSDR.SamplesPerFrame;
        numFrames = ceil(totalSamples / samplesPerFrame);
        
        % Pre-allocate buffer
        rxBuffer = complex(zeros(totalSamples, 1));
        
        % Step 1: Receive from SDR
        fprintf('Step 1: Receiving from SDR... ');
        sampleIdx = 1;
        
        for frameIdx = 1:numFrames
            frame = rxSDR();
            frameLen = length(frame);
            endIdx = min(sampleIdx + frameLen - 1, totalSamples);
            rxBuffer(sampleIdx:endIdx) = frame(1:(endIdx-sampleIdx+1));
            sampleIdx = endIdx + 1;
            
            if sampleIdx > totalSamples
                break;
            end
        end
        
        fprintf('%d samples received\n', length(rxBuffer));
        
        % Step 2: FM Demodulation
        fprintf('Step 2: FM demodulation... ');
        audioSignal = fm_demod(rxBuffer, fs_rf, fs_audio, freqDev);
        fprintf('%d audio samples\n', length(audioSignal));
        
        % Step 3: AFSK Demodulation
        fprintf('Step 3: AFSK demodulation... ');
        bits = afsk_demod(audioSignal, fs_audio, baudRate);
        fprintf('%d bits\n', length(bits));
        
        % Step 4: AX.25 Decoding
        fprintf('Step 4: AX.25 decoding... ');
        [message, valid, sourceCall, destCall] = ax25_decode(bits);
        
        if valid && ~isempty(message)
            fprintf('SUCCESS!\n');
            fprintf('\n--- Message Received ---\n');
            fprintf('From: %s  To: %s\n', sourceCall, destCall);
            fprintf('Message: "%s"\n', strtrim(message));
            fprintf('CRC: Valid\n');
            fprintf('--- RX Chain Finished ---\n\n');
        elseif ~isempty(message)
            fprintf('Decoded (CRC failed)\n');
            fprintf('\n--- Message Received (CRC Error) ---\n');
            fprintf('Message: "%s"\n', strtrim(message));
            fprintf('CRC: INVALID\n');
            fprintf('--- RX Chain Finished ---\n\n');
        else
            fprintf('No valid frame detected\n');
            fprintf('--- RX Chain Finished ---\n\n');
        end
        
    catch ME
        fprintf('RX Chain Error: %s\n', ME.message);
        fprintf('Stack trace:\n');
        for i = 1:length(ME.stack)
            fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
        end
    end
end
