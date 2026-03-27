%% PLUTO DIAGNOSTIC TOOL
% This script helps diagnose why Pluto radios aren't being detected

clear; clc;
fprintf('====================================\n');
fprintf('Pluto SDR Diagnostic Tool\n');
fprintf('====================================\n\n');

%% Step 1: Check MATLAB Toolboxes
fprintf('Step 1: Checking MATLAB Toolboxes\n');
fprintf('----------------------------------\n');

hasComm = license('test', 'Communication_Toolbox');
hasDSP = license('test', 'Signal_Toolbox');

if hasComm
    fprintf('✓ Communications Toolbox: Installed\n');
else
    fprintf('✗ Communications Toolbox: NOT FOUND\n');
    fprintf('  Install with: supportPackageInstaller\n');
end

if hasDSP
    fprintf('✓ DSP System Toolbox: Installed\n');
else
    fprintf('⚠ DSP System Toolbox: NOT FOUND\n');
end

fprintf('\n');

%% Step 2: Check for Pluto Support Functions
fprintf('Step 2: Checking Pluto Support Functions\n');
fprintf('------------------------------------------\n');

funcs = {'findPlutoRadio', 'sdrtx', 'sdrrx', 'comm.SDRRxPluto', 'comm.SDRTxPluto'};
foundAny = false;

for i = 1:length(funcs)
    if exist(funcs{i}, 'file') || exist(funcs{i}, 'class')
        fprintf('✓ %s: Available\n', funcs{i});
        foundAny = true;
    else
        fprintf('✗ %s: NOT FOUND\n', funcs{i});
    end
end

if ~foundAny
    fprintf('\n⚠️  NO PLUTO FUNCTIONS FOUND!\n');
    fprintf('   You need to install PlutoSDR Support Package:\n');
    fprintf('   1. Run: supportPackageInstaller\n');
    fprintf('   2. Search for "ADALM-Pluto"\n');
    fprintf('   3. Install the support package\n');
    fprintf('   4. Restart MATLAB\n');
end

fprintf('\n');

%% Step 3: Try Different Detection Methods
fprintf('Step 3: Attempting Radio Detection\n');
fprintf('-----------------------------------\n');

% Method 1: findPlutoRadio
if exist('findPlutoRadio', 'file')
    fprintf('Trying findPlutoRadio...\n');
    try
        radios = findPlutoRadio();
        if ~isempty(radios)
            fprintf('✓ Found %d radio(s):\n', length(radios));
            for i = 1:length(radios)
                fprintf('  [%d] RadioID: %s\n', i, radios(i).RadioID);
                if isfield(radios(i), 'SerialNum')
                    fprintf('      Serial: %s\n', radios(i).SerialNum);
                end
            end
        else
            fprintf('✗ No radios detected with findPlutoRadio\n');
        end
    catch ME
        fprintf('✗ Error with findPlutoRadio: %s\n', ME.message);
    end
else
    fprintf('✗ findPlutoRadio not available\n');
end

fprintf('\n');

% Method 2: Try creating SDR objects
fprintf('Trying direct SDR object creation...\n');
try
    if exist('sdrtx', 'file')
        testTx = sdrtx('Pluto');
        fprintf('✓ Can create sdrtx object\n');
        if ~isempty(testTx.DeviceName)
            fprintf('  Device: %s\n', testTx.DeviceName);
        end
        release(testTx);
    else
        fprintf('✗ sdrtx function not available\n');
    end
catch ME
    fprintf('✗ Cannot create sdrtx: %s\n', ME.message);
end

fprintf('\n');

% Method 3: System Object approach
fprintf('Trying System Object approach...\n');
try
    if exist('comm.SDRRxPluto', 'class')
        testRx = comm.SDRRxPluto();
        fprintf('✓ Can create comm.SDRRxPluto object\n');
        release(testRx);
    else
        fprintf('✗ comm.SDRRxPluto not available\n');
    end
catch ME
    fprintf('✗ Cannot create comm.SDRRxPluto: %s\n', ME.message);
end

fprintf('\n');

%% Step 4: Check System (Windows)
fprintf('Step 4: System-Level Checks\n');
fprintf('----------------------------\n');

if ispc
    fprintf('Checking Windows Device Manager...\n');
    try
        [status, result] = system('pnputil /enum-devices /connected /class USB');
        if contains(result, 'Pluto') || contains(result, 'ADALM')
            fprintf('✓ Pluto device found in Device Manager\n');
        else
            fprintf('⚠ Pluto device not found in Device Manager\n');
            fprintf('  Check: Device Manager > Universal Serial Bus devices\n');
        end
    catch
        fprintf('⚠ Could not check Device Manager\n');
    end
    
    fprintf('\n');
    fprintf('Checking for IIO USB drivers...\n');
    fprintf('If device shows as "Unknown" in Device Manager:\n');
    fprintf('  1. Download Pluto drivers from Analog Devices\n');
    fprintf('  2. Install PlutoSDR-M2k-USB-Drivers.exe\n');
    fprintf('  3. Reconnect Pluto radio\n');
    
elseif isunix
    fprintf('Checking Linux USB devices...\n');
    [status, result] = system('lsusb | grep -i "Analog Devices"');
    if status == 0 && ~isempty(result)
        fprintf('✓ Pluto device found:\n');
        fprintf('%s\n', result);
    else
        fprintf('✗ Pluto device not found with lsusb\n');
        fprintf('  Try: sudo lsusb -v | grep -i pluto\n');
    end
end

fprintf('\n');

%% Step 5: Recommendations
fprintf('========================================\n');
fprintf('DIAGNOSIS COMPLETE\n');
fprintf('========================================\n\n');

fprintf('RECOMMENDED ACTIONS:\n');
fprintf('--------------------\n\n');

if ~foundAny
    fprintf('HIGH PRIORITY:\n');
    fprintf('1. Install PlutoSDR Support Package:\n');
    fprintf('   >> supportPackageInstaller\n');
    fprintf('   Search for: ADALM-Pluto\n');
    fprintf('   Install and restart MATLAB\n\n');
end

fprintf('GENERAL TROUBLESHOOTING:\n\n');

fprintf('1. Verify Physical Connection:\n');
fprintf('   • Check USB cable is firmly connected\n');
fprintf('   • Try different USB port (USB 3.0 preferred)\n');
fprintf('   • Check Pluto LED is blinking (heartbeat)\n\n');

fprintf('2. Check Device Manager (Windows) or lsusb (Linux):\n');
fprintf('   • Should see "ADALM-PLUTO" or "PlutoSDR"\n');
fprintf('   • If "Unknown Device", reinstall drivers\n\n');

fprintf('3. Test Pluto Connection:\n');
fprintf('   • Open web browser\n');
fprintf('   • Navigate to: http://192.168.2.1\n');
fprintf('   • Should see Pluto web interface\n\n');

fprintf('4. Alternative: Use IP Address Method:\n');
fprintf('   • Find Pluto IP address\n');
fprintf('   • Use: sdrtx(''Pluto'', ''IPAddress'', ''192.168.2.1'')\n\n');

fprintf('5. Update Pluto Firmware:\n');
fprintf('   • Download latest firmware from Analog Devices\n');
fprintf('   • Update via web interface or mass storage\n\n');

fprintf('6. Restart Services:\n');
fprintf('   • Unplug Pluto, wait 10 seconds, reconnect\n');
fprintf('   • Restart MATLAB\n');
fprintf('   • Restart computer if needed\n\n');

fprintf('========================================\n');
fprintf('For more help, see:\n');
fprintf('https://wiki.analog.com/university/tools/pluto\n');
fprintf('========================================\n');
