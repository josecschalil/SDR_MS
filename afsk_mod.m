function audioSignal = afsk_mod(bits, fs, baudRate)
% AFSK_MOD Audio Frequency Shift Keying Modulator
%
% Implements Bell 202 standard AFSK modulation:
%   Bit 1 (Mark):  1200 Hz
%   Bit 0 (Space): 2200 Hz
%
% Inputs:
%   bits     - Binary vector to modulate
%   fs       - Sample rate in Hz (default: 48000)
%   baudRate - Baud rate in bps (default: 1200)
%
% Output:
%   audioSignal - Modulated audio signal

    if nargin < 2
        fs = 48000; % 48 kHz sample rate
    end
    if nargin < 3
        baudRate = 1200; % 1200 baud
    end
    
    % AFSK frequencies (Bell 202 standard)
    markFreq = 1200;   % Bit 1
    spaceFreq = 2200;  % Bit 0
    
    % Calculate samples per bit
    samplesPerBit = round(fs / baudRate);
    
    % Time vector for one bit duration
    t_bit = (0:samplesPerBit-1) / fs;
    
    % Pre-allocate output
    audioSignal = zeros(1, length(bits) * samplesPerBit);
    
    % Generate signal for each bit
    phase = 0; % Maintain phase continuity
    
    for i = 1:length(bits)
        if bits(i) == 1
            freq = markFreq;
        else
            freq = spaceFreq;
        end
        
        % Generate sinusoid with phase continuity
        segment = sin(2 * pi * freq * t_bit + phase);
        
        % Calculate phase at end of segment for continuity
        phase = mod(2 * pi * freq * t_bit(end) + phase, 2*pi);
        
        % Place in output
        startIdx = (i-1) * samplesPerBit + 1;
        endIdx = i * samplesPerBit;
        audioSignal(startIdx:endIdx) = segment;
    end
    
    % Normalize amplitude
    audioSignal = audioSignal / max(abs(audioSignal));
    
    % Apply slight filtering to reduce harmonics
    % Low-pass filter at 3 kHz
    if fs >= 8000
        lpFilt = designfilt('lowpassiir', 'FilterOrder', 4, ...
                            'HalfPowerFrequency', 3000, ...
                            'SampleRate', fs);
        audioSignal = filtfilt(lpFilt, audioSignal);
    end
    
    % Normalize again after filtering
    if max(abs(audioSignal)) > 0
        audioSignal = audioSignal / max(abs(audioSignal));
    end
end
