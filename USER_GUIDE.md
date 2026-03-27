# SDR-Based AX.25 Digital Chat System

## Overview

Real-time digital chat system using ADALM-Pluto SDR with AX.25 protocol over AFSK/FM modulation.

## Quick Start Guide

### Prerequisites

1. **Hardware:**
   - 2× ADALM-Pluto SDR devices
   - USB cables
   - Two computers (or one with two USB ports)

2. **Software:**
   - MATLAB R2019b or later
   - Communications Toolbox
   - DSP System Toolbox
   - Signal Processing Toolbox
   - PlutoSDR Support Package

### Installation

1. Install PlutoSDR Support Package:

   ```matlab
   supportPackageInstaller
   ```

   Search for "ADALM-Pluto" and install.

2. Connect Pluto radios via USB

3. Run the application:
   ```matlab
   main
   ```

### Using the GUI

1. **Device Selection:**
   - Click "🔍 Detect" to find connected Pluto radios
   - Select one radio for TX (transmit)
   - Select another radio for RX (receive)
   - Click "🔌 Connect"

2. **Setting Callsigns:**
   - Enter your callsign in "Source" field (e.g., "W1ABC")
   - Enter destination in "Dest" field (e.g., "W2DEF" or "CQ")

3. **Sending Messages:**
   - Type message in text area
   - Click "📢 Request TX" to enter transmit mode
   - Click "📤 Send" to transmit
   - System automatically returns to RX mode

4. **Receiving Messages:**
   - System automatically monitors for incoming messages
   - Received messages appear in chat history with timestamp

### Command-Line Usage

If you prefer command-line or want to run tests:

```matlab
% Configure radios
[txSDR, rxSDR, radios] = pluto_config('usb:0', 'usb:1', 145e6, 0, 20);

% Transmit a message
tx_chain('Hello World!', txSDR, 'W1ABC', 'CQ');

% Receive for 10 seconds
[msg, valid, src, dst] = rx_chain(rxSDR, 10);

% Run system tests
test_chain
```

## System Parameters

### RF Configuration

- **Center Frequency:** 145.000 MHz (configurable)
- **Sample Rate:** 2.4 MHz
- **TX Gain:** 0 dB (adjustable)
- **RX Gain:** 20 dB (adjustable)
- **Modulation:** Narrowband FM (NBFM)
- **Frequency Deviation:** 5 kHz

### Digital Modulation

- **Type:** Audio Frequency Shift Keying (AFSK)
- **Mark (bit 1):** 1200 Hz
- **Space (bit 0):** 2200 Hz
- **Baud Rate:** 1200 bps
- **Audio Sample Rate:** 48 kHz

### AX.25 Protocol

- **Frame Structure:**
  - Flag: 0x7E (01111110)
  - Address Field: Source/Dest callsigns
  - Control Field: UI frame (0x03)
  - Protocol ID: 0xF0
  - Information Field: Text message
  - Frame Check Sequence: CRC-16-CCITT
  - Flag: 0x7E

### Half-Duplex Operation

- **States:** IDLE, TRANSMIT, RECEIVE
- Only one side transmits at a time
- Request-to-Send (RTS) mechanism
- Automatic return to RX mode after transmission

## Troubleshooting

### No Radios Detected

1. Check USB connections
2. Verify Pluto drivers installed
3. Try different USB port
4. Check device manager (Windows) or lsusb (Linux)

### Cannot Connect to Radios

1. Ensure PlutoSDR Support Package is installed
2. Check radio IDs match detected devices
3. Try unplugging and reconnecting
4. Restart MATLAB

### Poor Reception Quality

1. Increase RX gain (but not too high - causes distortion)
2. Ensure both radios on same frequency
3. Check antenna connections
4. Reduce distance between radios for testing
5. Check for interference sources

### Messages Not Decoding

1. Run test_chain.m to verify signal processing
2. Check SNR (should be >10 dB)
3. Verify frequency settings match on both sides
4. Check for frequency offset (Pluto has ~1 ppm accuracy)

### GUI Not Loading

1. Check MATLAB version (needs R2019b+)
2. Use command-line interface instead
3. Check for errors in MATLAB console

## Testing Without Hardware

Run the test suite to verify signal processing:

```matlab
test_chain
```

This tests the complete chain without SDR hardware using simulated signals.

## File Structure

```
SDR_MS/
├── main.m                 - Main entry point
├── gui_app.m             - GUI application
├── ax25_encode.m         - AX.25 encoder
├── ax25_decode.m         - AX.25 decoder
├── afsk_mod.m            - AFSK modulator
├── afsk_demod.m          - AFSK demodulator
├── fm_mod.m              - FM modulator
├── fm_demod.m            - FM demodulator
├── pluto_config.m        - Pluto SDR configuration
├── half_duplex_sm.m      - Half-duplex state machine
├── tx_chain.m            - Complete TX pipeline
├── rx_chain.m            - Complete RX pipeline
├── test_chain.m          - System test suite
└── docs/
    ├── parameters.txt     - System parameters
    └── USER_GUIDE.md      - This file
```

## Advanced Usage

### Custom Frequency

```matlab
[txSDR, rxSDR] = pluto_config('usb:0', 'usb:1', 433e6, 0, 20);
```

### Adjust Gains

```matlab
txSDR.Gain = -10;  % Reduce TX power
rxSDR.Gain = 30;   % Increase RX sensitivity
```

### Save/Load IQ Data

```matlab
% Record
[txSDR, rxSDR] = pluto_config(...);
data = rxSDR();
save('recording.mat', 'data');

% Replay
load('recording.mat');
processedMsg = rx_chain_from_iq(data);
```

## Performance Notes

- **Latency:** ~500ms TX + ~500ms RX = ~1 second round-trip
- **Range:** Line-of-sight dependent on frequency and power
  - 145 MHz: Several km with good antennas
  - 433 MHz: ~1 km typical
- **Data Rate:** 1200 bps effective (AX.25 overhead)
- **Message Length:** Up to 256 bytes recommended

## Safety and Legal

⚠️ **Important Notices:**

1. **Frequency Licensing:**
   - Some frequencies require amateur radio license
   - 145 MHz is amateur radio band (license required)
   - 433 MHz varies by country
   - Check local regulations before transmitting!

2. **RF Safety:**
   - Pluto output power is low (<10 mW typically)
   - Still avoid transmitting near medical devices
   - Use appropriate antennas

3. **Interference:**
   - Monitor frequency before transmitting
   - Use appropriate power levels
   - Be a good spectrum citizen

## Support

For issues or questions:

1. Check this documentation
2. Review parameters.txt for technical details
3. Run test_chain.m to diagnose problems
4. Check MATLAB/Pluto documentation

## Credits

Based on:

- AX.25 Amateur Packet Radio Link-Layer Protocol
- Bell 202 AFSK standard
- NBFM modulation techniques
- ADALM-Pluto SDR platform

## License

Educational and experimental use.
