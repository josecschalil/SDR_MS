function [txSDR, rxSDR, availableRadios] = pluto_config(txRadioID, rxRadioID, centerFreq, txGain, rxGain)
% PLUTO_CONFIG Configure ADALM-Pluto SDR devices
%
% Inputs:
%   txRadioID  - Radio ID for transmitter (optional)
%   rxRadioID  - Radio ID for receiver (optional)
%   centerFreq - Center frequency in Hz (default: 145e6)
%   txGain     - TX gain in dB (default: 0)
%   rxGain     - RX gain in dB (default: 20)
%
% Outputs:
%   txSDR           - Configured TX SDR object
%   rxSDR           - Configured RX SDR object
%   availableRadios - Structure with info about detected radios

    % Default parameters
    if nargin < 3
        centerFreq = 145e6; % 145 MHz
    end
    if nargin < 4
        txGain = 0; % dB
    end
    if nargin < 5
        rxGain = 20; % dB
    end
    
    % SDR parameters
    sampleRate = 2.4e6; % 2.4 MHz
    samplesPerFrame = 2^16; % 65536 samples
    
    % Find available Pluto radios
    fprintf('Detecting ADALM-Pluto radios...\n');
    availableRadios = [];
    
    try
        % Try to find radios using Communications Toolbox
        if exist('findPlutoRadio', 'file')
            radios = findPlutoRadio();
            if ~isempty(radios)
                availableRadios = radios;
                fprintf('Found %d Pluto radio(s):\n', length(radios));
                for i = 1:length(radios)
                    fprintf('  [%d] RadioID: %s\n', i, radios(i).RadioID);
                end
            else
                fprintf('No Pluto radios detected.\n');
            end
        else
            warning('findPlutoRadio not available. Make sure Communications Toolbox and PlutoSDR Support are installed.');
        end
    catch ME
        warning('Error detecting radios: %s', ME.message);
    end
    
    % Configure TX SDR
    txSDR = [];
    if nargin >= 1 && ~isempty(txRadioID)
        try
            fprintf('\nConfiguring TX radio: %s\n', txRadioID);
            txSDR = sdrtx('Pluto', 'RadioID', txRadioID);
            txSDR.CenterFrequency = centerFreq;
            txSDR.BasebandSampleRate = sampleRate;
            txSDR.Gain = txGain;
            txSDR.ShowAdvancedProperties = true;
            fprintf('  Center Frequency: %.2f MHz\n', centerFreq/1e6);
            fprintf('  Sample Rate: %.2f Msps\n', sampleRate/1e6);
            fprintf('  TX Gain: %d dB\n', txGain);
        catch ME
            warning('Failed to configure TX radio: %s', ME.message);
            txSDR = [];
        end
    else
        fprintf('\nNo TX radio specified.\n');
    end
    
    % Configure RX SDR
    rxSDR = [];
    if nargin >= 2 && ~isempty(rxRadioID)
        try
            fprintf('\nConfiguring RX radio: %s\n', rxRadioID);
            rxSDR = sdrrx('Pluto', 'RadioID', rxRadioID);
            rxSDR.CenterFrequency = centerFreq;
            rxSDR.BasebandSampleRate = sampleRate;
            rxSDR.GainSource = 'Manual';
            rxSDR.Gain = rxGain;
            rxSDR.SamplesPerFrame = samplesPerFrame;
            rxSDR.OutputDataType = 'double';
            rxSDR.ShowAdvancedProperties = true;
            fprintf('  Center Frequency: %.2f MHz\n', centerFreq/1e6);
            fprintf('  Sample Rate: %.2f Msps\n', sampleRate/1e6);
            fprintf('  RX Gain: %d dB\n', rxGain);
            fprintf('  Samples/Frame: %d\n', samplesPerFrame);
        catch ME
            warning('Failed to configure RX radio: %s', ME.message);
            rxSDR = [];
        end
    else
        fprintf('\nNo RX radio specified.\n');
    end
    
    fprintf('\nConfiguration complete.\n');
end

function radios = detectPlutoRadios()
    % Helper function to detect Pluto radios
    % Returns structure with RadioID and SerialNo
    
    radios = [];
    
    % This is a placeholder - actual implementation depends on
    % Communications Toolbox being properly installed
    try
        if exist('findPlutoRadio', 'file')
            radios = findPlutoRadio();
        end
    catch
        % Return empty if detection fails
    end
end
