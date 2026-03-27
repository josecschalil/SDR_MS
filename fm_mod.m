function fmSignal = fm_mod(audioSignal, fs_audio, fs_rf, freqDev)
% FM_MOD Frequency Modulation for NBFM
%
% Modulates baseband audio signal to FM
%
% Inputs:
%   audioSignal - Baseband audio signal (AFSK)
%   fs_audio    - Audio sample rate in Hz (default: 48000)
%   fs_rf       - RF sample rate in Hz (default: 2400000)
%   freqDev     - Frequency deviation in Hz (default: 5000)
%
% Output:
%   fmSignal - Complex baseband FM signal (I/Q)

    if nargin < 2
        fs_audio = 48000;
    end
    if nargin < 3
        fs_rf = 2400000; % 2.4 MHz for Pluto
    end
    if nargin < 4
        freqDev = 5000; % 5 kHz deviation for NBFM
    end
    
    % Resample audio to RF sample rate if needed
    if fs_audio ~= fs_rf
        [P, Q] = rat(fs_rf / fs_audio);
        audioResampled = resample(audioSignal, P, Q);
    else
        audioResampled = audioSignal;
    end
    
    % Pre-emphasis (optional - helps with noise)
    % Standard 6 dB/octave pre-emphasis
    if fs_rf >= 10000
        % Simple first-order high-pass for pre-emphasis
        tau = 75e-6; % 75 μs time constant (standard)
        alpha = tau * fs_rf / (1 + tau * fs_rf);
        audioPreemph = filter([1 -1], [1 -alpha], audioResampled);
    else
        audioPreemph = audioResampled;
    end
    
    % Normalize audio
    if max(abs(audioPreemph)) > 0
        audioPreemph = audioPreemph / max(abs(audioPreemph));
    end
    
    % FM modulation using phase integration
    % Instantaneous frequency = carrier + freqDev * audio
    % Phase = integral of instantaneous frequency
    
    % Calculate phase deviation
    phaseDev = 2 * pi * freqDev * audioPreemph / fs_rf;
    
    % Integrate to get phase (cumulative sum)
    phase = cumsum(phaseDev);
    
    % Generate complex baseband signal (I/Q)
    fmSignal = exp(1j * phase);
    
    % Normalize
    fmSignal = fmSignal / max(abs(fmSignal));
end
