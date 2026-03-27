%% ALTERNATIVE PLUTO_CONFIG - Uses IP Address Method
% This version tries to connect using IP address if auto-detection fails

function [txSDR, rxSDR, availableRadios] = pluto_config_alt(txRadioID, rxRadioID, centerFreq, txGain, rxGain)
% PLUTO_CONFIG_ALT Alternative Pluto configuration using IP address
%
% Tries multiple methods to connect to Pluto radios

    % Default parameters
    if nargin < 3
        centerFreq = 145e6;
    end
    if nargin < 4
        txGain = 0;
    end
    if nargin < 5
        rxGain = 20;
    end
    
    sampleRate = 2.4e6;
    samplesPerFrame = 2^16;
    
    availableRadios = [];
    txSDR = [];
    rxSDR = [];
    
    fprintf('Alternative Pluto Configuration\n');
    fprintf('================================\n\n');
    
    %% Method 1: Try findPlutoRadio
    fprintf('Method 1: Auto-detection...\n');
    try
        if exist('findPlutoRadio', 'file')
            radios = findPlutoRadio();
            if ~isempty(radios)
                availableRadios = radios;
                fprintf('  ✓ Found %d radio(s)\n', length(radios));
            else
                fprintf('  ✗ No radios found\n');
            end
        else
            fprintf('  ✗ findPlutoRadio not available\n');
        end
    catch ME
        fprintf('  ✗ Error: %s\n', ME.message);
    end
    
    %% Method 2: Try IP address
    if isempty(availableRadios)
        fprintf('\nMethod 2: Trying IP address method...\n');
        defaultIPs = {'192.168.2.1', '192.168.3.1', 'pluto.local'};
        
        for i = 1:length(defaultIPs)
            fprintf('  Trying %s...\n', defaultIPs{i});
            try
                % Test with RX object
                if exist('sdrrx', 'file')
                    testRx = sdrrx('Pluto', 'IPAddress', defaultIPs{i});
                    fprintf('  ✓ Connected to Pluto at %s\n', defaultIPs{i});
                    release(testRx);
                    
                    % Create pseudo radio info
                    radio.RadioID = defaultIPs{i};
                    radio.IPAddress = defaultIPs{i};
                    availableRadios = radio;
                    break;
                elseif exist('comm.SDRRxPluto', 'class')
                    testRx = comm.SDRRxPluto('IPAddress', defaultIPs{i});
                    fprintf('  ✓ Connected to Pluto at %s\n', defaultIPs{i});
                    release(testRx);
                    
                    radio.RadioID = defaultIPs{i};
                    radio.IPAddress = defaultIPs{i};
                    availableRadios = radio;
                    break;
                end
            catch ME
                fprintf('  ✗ Failed: %s\n', ME.message);
            end
        end
    end
    
    %% Method 3: Try System Object approach
    if isempty(availableRadios)
        fprintf('\nMethod 3: Trying System Object approach...\n');
        try
            if exist('comm.SDRRxPluto', 'class')
                testRx = comm.SDRRxPluto();
                fprintf('  ✓ Can create System Object\n');
                release(testRx);
                
                radio.RadioID = 'usb:0';
                radio.Method = 'SystemObject';
                availableRadios = radio;
            end
        catch ME
            fprintf('  ✗ Error: %s\n', ME.message);
        end
    end
    
    %% Configure TX/RX if we found radios
    if isempty(availableRadios)
        fprintf('\n✗ Could not connect to any Pluto radios!\n');
        fprintf('\nTroubleshooting:\n');
        fprintf('  1. Run pluto_diagnostic for detailed checks\n');
        fprintf('  2. Verify Pluto is connected (LED blinking)\n');
        fprintf('  3. Check http://192.168.2.1 in browser\n');
        fprintf('  4. Install PlutoSDR Support Package\n');
        return;
    end
    
    %% Configure TX
    if nargin >= 1 && ~isempty(txRadioID)
        fprintf('\nConfiguring TX radio...\n');
        try
            % Try different methods
            if exist('sdrtx', 'file')
                if contains(txRadioID, '.')
                    txSDR = sdrtx('Pluto', 'IPAddress', txRadioID);
                else
                    txSDR = sdrtx('Pluto', 'RadioID', txRadioID);
                end
            elseif exist('comm.SDRTxPluto', 'class')
                txSDR = comm.SDRTxPluto();
                if isfield(availableRadios, 'IPAddress')
                    txSDR.IPAddress = availableRadios.IPAddress;
                end
            end
            
            % Configure parameters
            txSDR.CenterFrequency = centerFreq;
            txSDR.BasebandSampleRate = sampleRate;
            txSDR.Gain = txGain;
            
            fprintf('  ✓ TX configured: %.2f MHz\n', centerFreq/1e6);
        catch ME
            fprintf('  ✗ TX config failed: %s\n', ME.message);
            txSDR = [];
        end
    end
    
    %% Configure RX
    if nargin >= 2 && ~isempty(rxRadioID)
        fprintf('\nConfiguring RX radio...\n');
        try
            if exist('sdrrx', 'file')
                if contains(rxRadioID, '.')
                    rxSDR = sdrrx('Pluto', 'IPAddress', rxRadioID);
                else
                    rxSDR = sdrrx('Pluto', 'RadioID', rxRadioID);
                end
            elseif exist('comm.SDRRxPluto', 'class')
                rxSDR = comm.SDRRxPluto();
                if isfield(availableRadios, 'IPAddress')
                    rxSDR.IPAddress = availableRadios.IPAddress;
                end
            end
            
            % Configure parameters
            rxSDR.CenterFrequency = centerFreq;
            rxSDR.BasebandSampleRate = sampleRate;
            rxSDR.GainSource = 'Manual';
            rxSDR.Gain = rxGain;
            rxSDR.SamplesPerFrame = samplesPerFrame;
            rxSDR.OutputDataType = 'double';
            
            fprintf('  ✓ RX configured: %.2f MHz\n', centerFreq/1e6);
        catch ME
            fprintf('  ✗ RX config failed: %s\n', ME.message);
            rxSDR = [];
        end
    end
    
    fprintf('\n');
end
