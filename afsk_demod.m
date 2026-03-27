function bits = afsk_demod(audioSignal, fs, baudRate)
% AFSK_DEMOD Audio Frequency Shift Keying Demodulator
%
% Demodulates Bell 202 AFSK:
%   1200 Hz → Bit 1 (Mark)
%   2200 Hz → Bit 0 (Space)
%
% Inputs:
%   audioSignal - Received audio signal
%   fs          - Sample rate in Hz (default: 48000)
%   baudRate    - Baud rate in bps (default: 1200)
%
% Output:
%   bits - Demodulated binary vector

    if nargin < 2
        fs = 48000;
    end
    if nargin < 3
        baudRate = 1200;
    end
    
    % AFSK frequencies
    markFreq = 1200;
    spaceFreq = 2200;
    
    % Samples per bit
    samplesPerBit = round(fs / baudRate);
    
    % Design bandpass filters for each frequency
    % Mark filter (1200 Hz ± 200 Hz)
    bpMark = designfilt('bandpassiir', 'FilterOrder', 4, ...
                        'HalfPowerFrequency1', 1000, ...
                        'HalfPowerFrequency2', 1400, ...
                        'SampleRate', fs);
    
    % Space filter (2200 Hz ± 200 Hz)
    bpSpace = designfilt('bandpassiir', 'FilterOrder', 4, ...
                         'HalfPowerFrequency1', 2000, ...
                         'HalfPowerFrequency2', 2400, ...
                         'SampleRate', fs);
    
    % Filter signal through both filters
    markFiltered = filtfilt(bpMark, audioSignal);
    spaceFiltered = filtfilt(bpSpace, audioSignal);
    
    % Envelope detection (rectify and smooth)
    markEnv = abs(hilbert(markFiltered));
    spaceEnv = abs(hilbert(spaceFiltered));
    
    % Smooth envelopes
    windowSize = round(samplesPerBit / 4);
    if windowSize < 1
        windowSize = 1;
    end
    markEnv = movmean(markEnv, windowSize);
    spaceEnv = movmean(spaceEnv, windowSize);
    
    % Sample at bit centers
    numBits = floor(length(audioSignal) / samplesPerBit);
    bits = zeros(1, numBits);
    
    for i = 1:numBits
        % Sample at center of bit period
        sampleIdx = round((i - 0.5) * samplesPerBit);
        if sampleIdx < 1
            sampleIdx = 1;
        end
        if sampleIdx > length(markEnv)
            sampleIdx = length(markEnv);
        end
        
        % Compare mark vs space energy
        if markEnv(sampleIdx) > spaceEnv(sampleIdx)
            bits(i) = 1; % Mark (1200 Hz)
        else
            bits(i) = 0; % Space (2200 Hz)
        end
    end
end
