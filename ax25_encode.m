function bits = ax25_encode(message, sourceCall, destCall)
% AX25_ENCODE Encode text message into AX.25 frame format
%
% Inputs:
%   message    - Text string to transmit
%   sourceCall - Source callsign (default: 'N0CALL')
%   destCall   - Destination callsign (default: 'CQ    ')
%
% Output:
%   bits - Binary vector of AX.25 frame
%
% Frame Structure:
%   Flag (0x7E) | Address | Control | PID | Information | FCS | Flag (0x7E)

    % Default callsigns if not provided
    if nargin < 2
        sourceCall = 'N0CALL';
    end
    if nargin < 3
        destCall = 'CQ    ';
    end
    
    % Ensure callsigns are uppercase and padded to 6 characters
    sourceCall = upper(pad(sourceCall, 6));
    destCall = upper(pad(destCall, 6));
    
    % AX.25 Flag: 0x7E (01111110)
    flag = [0 1 1 1 1 1 1 0];
    
    % Build Address Field
    % Each callsign: 6 bytes shifted left 1 bit + SSID byte
    destAddr = encodeCallsign(destCall, 0, false); % SSID=0, not last
    srcAddr = encodeCallsign(sourceCall, 0, true);  % SSID=0, last address
    
    % Control Field: UI frame (0x03 = 00000011)
    control = [1 1 0 0 0 0 0 0]; % LSB first
    
    % Protocol ID: No layer 3 (0xF0 = 11110000)
    pid = [0 0 0 0 1 1 1 1]; % LSB first
    
    % Information Field: Convert message to bytes
    messageBytes = double(message);
    infoBits = [];
    for i = 1:length(messageBytes)
        infoBits = [infoBits, byte2bits(messageBytes(i))];
    end
    
    % Build frame without FCS
    frameData = [destAddr, srcAddr, control, pid, infoBits];
    
    % Calculate FCS (CRC-16-CCITT)
    fcs = calculateCRC16(frameData);
    fcsBits = [byte2bits(fcs(1)), byte2bits(fcs(2))];
    
    % Complete frame
    bits = [flag, frameData, fcsBits, flag];
end

function callBits = encodeCallsign(callsign, ssid, isLast)
    % Encode callsign into AX.25 address format
    % Callsign characters are shifted left by 1 bit
    
    callBits = [];
    
    % Encode 6 characters
    for i = 1:6
        if i <= length(callsign)
            char_val = double(callsign(i));
        else
            char_val = 32; % Space padding
        end
        shifted = bitshift(char_val, 1); % Shift left by 1
        callBits = [callBits, byte2bits(shifted)];
    end
    
    % SSID byte: xxxCRR0L where:
    %   xxx = reserved (111)
    %   C = command/response (0)
    %   RR = SSID (00 for SSID 0)
    %   0 = reserved
    %   L = last address bit (1 if last, 0 if not)
    ssidByte = bitshift(7, 5) + bitshift(ssid, 1);
    if isLast
        ssidByte = ssidByte + 1;
    end
    callBits = [callBits, byte2bits(ssidByte)];
end

function bits = byte2bits(byte)
    % Convert byte to 8-bit array (LSB first)
    bits = zeros(1, 8);
    for i = 1:8
        bits(i) = bitget(byte, i);
    end
end

function crc_bytes = calculateCRC16(bits)
    % Calculate CRC-16-CCITT for AX.25
    % Polynomial: 0x1021 (x^16 + x^12 + x^5 + 1)
    
    % Convert bits to bytes for CRC calculation
    numBytes = length(bits) / 8;
    bytes = zeros(1, numBytes);
    for i = 1:numBytes
        startIdx = (i-1)*8 + 1;
        byte_bits = bits(startIdx:startIdx+7);
        bytes(i) = bits2byte(byte_bits);
    end
    
    % CRC-16-CCITT calculation
    crc = uint16(hex2dec('FFFF')); % Initial value
    poly = uint16(hex2dec('1021'));
    
    for i = 1:length(bytes)
        crc = bitxor(crc, bitshift(uint16(bytes(i)), 8));
        for j = 1:8
            if bitget(crc, 16) == 1
                crc = bitxor(bitshift(crc, 1), poly);
            else
                crc = bitshift(crc, 1);
            end
            crc = bitand(crc, uint16(hex2dec('FFFF'))); % Keep 16 bits
        end
    end
    
    % Invert final CRC (AX.25 convention)
    crc = bitcmp(crc, 'uint16');
    
    % Return as two bytes (LSB first)
    crc_bytes = [mod(crc, 256), floor(double(crc)/256)];
end

function byte = bits2byte(bits)
    % Convert 8-bit array (LSB first) to byte value
    byte = 0;
    for i = 1:8
        if bits(i) == 1
            byte = byte + 2^(i-1);
        end
    end
end
