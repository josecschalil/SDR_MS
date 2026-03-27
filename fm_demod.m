function audioSignal = fm_demod(fmSignal, fs_rf, fs_audio, freqDev)
% FM_DEMOD Frequency Demodulation for NBFM
%
% Demodulates FM signal to recover baseband audio
%
% Inputs:
%   fmSignal - Complex baseband FM signal (I/Q)
%   fs_rf    - RF sample rate in Hz (default: 2400000)
%   fs_audio - Audio sample rate in Hz (default: 48000)
%   freqDev  - Frequency deviation in Hz (default: 5000)
%
% Output:
%   audioSignal - Demodulated audio signal

    if nargin < 2
        fs_rf = 2400000;
    end
    if nargin < 3
        fs_audio = 48000;
    end
    if nargin < 4
        freqDev = 5000;
    end
    
    % FM demodulation using phase differentiation
    % Extract instantaneous phase
    phase = unwrap(angle(fmSignal));
    
    % Differentiate phase to get frequency
    % f(t) = (1/2π) * dφ/dt
    phaseDiff = diff(phase);
    freq = phaseDiff * fs_rf / (2 * pi);
    
    % Normalize by frequency deviation
    audioDemod = freq / freqDev;
    
    % Pad to match input length
    audioDemod = [audioDemod, audioDemod(end)];
    
    % De-emphasis (inverse of pre-emphasis)
    % Standard 75 μs time constant
    tau = 75e-6;
    alpha = 1 / (1 + tau * fs_rf);
    audioDeemph = filter(alpha, [1, alpha-1], audioDemod);
    
    % Low-pass filter to remove high-frequency noise
    % Cutoff at 3 kHz (AFSK bandwidth)
    if fs_rf >= 10000
        lpFilt = designfilt('lowpassiir', 'FilterOrder', 6, ...
                            'HalfPowerFrequency', 3000, ...
                            'SampleRate', fs_rf);
        audioFiltered = filtfilt(lpFilt, audioDeemph);
    else
        audioFiltered = audioDeemph;
    end
    
    % Downsample to audio sample rate
    if fs_rf ~= fs_audio
        [P, Q] = rat(fs_audio / fs_rf);
        audioSignal = resample(audioFiltered, P, Q);
    else
        audioSignal = audioFiltered;
    end
    
    % Normalize output
    if max(abs(audioSignal)) > 0
        audioSignal = audioSignal / max(abs(audioSignal));
    end
end
