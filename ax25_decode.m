function [message, valid, sourceCall, destCall] = ax25_decode(bits)
% AX25_DECODE Decode AX.25 frame to extract text message
%
% Input:
%   bits - Binary vector containing AX.25 frame
%
% Outputs:
%   message    - Decoded text string
%   valid      - Boolean indicating if frame is valid
%   sourceCall - Source callsign
%   destCall   - Destination callsign

    message = '';
    valid = false;
    sourceCall = '';
    destCall = '';
    
    % Look for flag sequences (01111110)
    flag = [0 1 1 1 1 1 1 0];
    
    % Find all flag positions
    flagPos = findFlags(bits, flag);
    
    if length(flagPos) < 2
        return; % Need at least start and end flags
    end
    
    % Extract frame between first two flags
    startIdx = flagPos(1) + 8;
    endIdx = flagPos(2) - 1;
    
    if endIdx <= startIdx
        return;
    end
    
    frameData = bits(startIdx:endIdx);
    
    % Minimum frame length check (address + control + PID + FCS)
    % 7+7+1+1+2 = 18 bytes = 144 bits
    if length(frameData) < 144
        return;
    end
    
    % Extract fields
    idx = 1;
    
    % Destination Address (7 bytes = 56 bits)
    destAddrBits = frameData(idx:idx+55);
    [destCall, ~] = decodeCallsign(destAddrBits);
    idx = idx + 56;
    
    % Source Address (7 bytes = 56 bits)
    srcAddrBits = frameData(idx:idx+55);
    [sourceCall, ~] = decodeCallsign(srcAddrBits);
    idx = idx + 56;
    
    % Control Field (1 byte = 8 bits)
    controlBits = frameData(idx:idx+7);
    idx = idx + 8;
    
    % PID Field (1 byte = 8 bits)
    pidBits = frameData(idx:idx+7);
    idx = idx + 8;
    
    % Information Field (remaining - 16 bits for FCS)
    fcsStartIdx = length(frameData) - 15;
    infoBits = frameData(idx:fcsStartIdx-1);
    
    % FCS (2 bytes = 16 bits)
    fcsBits = frameData(fcsStartIdx:end);
    
    % Verify CRC
    dataForCRC = frameData(1:fcsStartIdx-1);
    receivedFCS = [bits2byte(fcsBits(1:8)), bits2byte(fcsBits(9:16))];
    calculatedCRC = calculateCRC16(dataForCRC);
    
    % Check if CRC matches
    if isequal(receivedFCS, calculatedCRC)
        valid = true;
    else
        % CRC mismatch - might still decode message for testing
        valid = false;
    end
    
    % Decode information field to text
    numInfoBytes = length(infoBits) / 8;
    message = char(zeros(1, numInfoBytes));
    for i = 1:numInfoBytes
        startIdx = (i-1)*8 + 1;
        byte_bits = infoBits(startIdx:startIdx+7);
        message(i) = char(bits2byte(byte_bits));
    end
end

function positions = findFlags(bits, flag)
    % Find all positions where flag pattern occurs
    positions = [];
    flagLen = length(flag);
    
    for i = 1:(length(bits) - flagLen + 1)
        if isequal(bits(i:i+flagLen-1), flag)
            positions = [positions, i];
        end
    end
end

function [callsign, ssid] = decodeCallsign(addrBits)
    % Decode AX.25 address format to callsign
    % First 6 bytes are callsign (shifted right by 1)
    % 7th byte is SSID
    
    callsign = char(zeros(1, 6));
    
    % Decode 6 characters
    for i = 1:6
        startIdx = (i-1)*8 + 1;
        byte_bits = addrBits(startIdx:startIdx+7);
        char_val = bits2byte(byte_bits);
        char_val = bitshift(char_val, -1); % Shift right by 1
        callsign(i) = char(char_val);
    end
    
    % Remove trailing spaces
    callsign = strtrim(callsign);
    
    % Decode SSID byte
    ssidBits = addrBits(49:56);
    ssidByte = bits2byte(ssidBits);
    ssid = bitshift(bitand(ssidByte, 30), -1); % Extract SSID bits
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

function crc_bytes = calculateCRC16(bits)
    % Calculate CRC-16-CCITT for AX.25
    % Polynomial: 0x1021
    
    % Convert bits to bytes
    numBytes = length(bits) / 8;
    bytes = zeros(1, numBytes);
    for i = 1:numBytes
        startIdx = (i-1)*8 + 1;
        byte_bits = bits(startIdx:startIdx+7);
        bytes(i) = bits2byte(byte_bits);
    end
    
    % CRC-16-CCITT calculation
    crc = uint16(hex2dec('FFFF'));
    poly = uint16(hex2dec('1021'));
    
    for i = 1:length(bytes)
        crc = bitxor(crc, bitshift(uint16(bytes(i)), 8));
        for j = 1:8
            if bitget(crc, 16) == 1
                crc = bitxor(bitshift(crc, 1), poly);
            else
                crc = bitshift(crc, 1);
            end
            crc = bitand(crc, uint16(hex2dec('FFFF')));
        end
    end
    
    % Invert final CRC
    crc = bitcmp(crc, 'uint16');
    
    % Return as two bytes (LSB first)
    crc_bytes = [mod(crc, 256), floor(double(crc)/256)];
end
