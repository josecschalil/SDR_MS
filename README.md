# 📡 SDR-Based AX.25 Digital Chat System

A complete MATLAB implementation of real-time digital communication using ADALM-Pluto SDR with AX.25 protocol over AFSK/FM modulation.

## 🎯 Features

✅ **Complete Signal Chain:** TEXT → AX.25 → AFSK → FM → SDR → FM Demod → AFSK Demod → AX.25 → TEXT  
✅ **Half-Duplex Communication:** Request-to-Send mechanism with state machine  
✅ **Multiple Device Support:** Select TX and RX Pluto radios independently  
✅ **User-Friendly GUI:** Simple interface for chat control  
✅ **Modular Design:** Each component can be tested independently  
✅ **Beginner-Friendly:** Simplified implementation with clear documentation

## 🚀 Quick Start

### 1. Prerequisites

**Hardware:**

- 2× ADALM-Pluto SDR devices
- USB cables

**Software:**

- MATLAB R2019b or later
- Communications Toolbox
- DSP System Toolbox
- PlutoSDR Support Package

### 2. Installation

```matlab
% Install PlutoSDR Support Package
supportPackageInstaller  % Search for "ADALM-Pluto"

% Navigate to project directory
cd path/to/SDR_MS

% Run application
main
```

### 3. Using the System

1. **Connect** both Pluto radios via USB
2. **Launch** application: `main`
3. **Detect** radios using GUI button
4. **Select** TX and RX radios
5. **Connect** to configure radios
6. **Start chatting!**

## 📁 Project Structure

```
SDR_MS/
├── main.m                  Main entry point
├── gui_app.m              GUI application
│
├── Signal Processing Chain:
│   ├── ax25_encode.m      AX.25 frame encoder
│   ├── ax25_decode.m      AX.25 frame decoder
│   ├── afsk_mod.m         AFSK modulator (1200/2200 Hz)
│   ├── afsk_demod.m       AFSK demodulator
│   ├── fm_mod.m           FM modulator
│   ├── fm_demod.m         FM demodulator
│
├── System Integration:
│   ├── tx_chain.m         Complete TX pipeline
│   ├── rx_chain.m         Complete RX pipeline
│   ├── half_duplex_sm.m   State machine (IDLE/TX/RX)
│   └── pluto_config.m     SDR configuration
│
├── Testing:
│   └── test_chain.m       End-to-end system test
│
└── Documentation:
    ├── USER_GUIDE.md      Complete user guide
    └── parameters.txt     Technical parameters
```

## 🔧 Technical Specifications

### RF Parameters

- **Center Frequency:** 145 MHz (VHF amateur radio band)
- **Sample Rate:** 2.4 MHz
- **Modulation:** Narrowband FM (5 kHz deviation)
- **TX Gain:** 0 dB
- **RX Gain:** 20 dB

### Digital Modulation (AFSK)

- **Mark (1):** 1200 Hz
- **Space (0):** 2200 Hz
- **Baud Rate:** 1200 bps
- **Audio Rate:** 48 kHz

### Protocol (AX.25)

- **Frame Structure:** Flag + Address + Control + PID + Info + CRC + Flag
- **CRC:** 16-bit CCITT
- **Max Payload:** 256 bytes

## 🧪 Testing

Run the test suite to verify signal processing without hardware:

```matlab
test_chain
```

Expected output:

```
✓ AX.25 Test PASSED
✓ AFSK Test PASSED
✓ FM Test PASSED
✓ COMPLETE CHAIN TEST PASSED!
```

## 📊 Data Flow Diagram

```
TRANSMITTER:
User Input → AX.25 Encode → AFSK Mod → FM Mod → Pluto SDR TX
   ↓
[Text]    [Bits+CRC]      [Audio]    [I/Q]    [RF Signal]

RECEIVER:
Pluto SDR RX → FM Demod → AFSK Demod → AX.25 Decode → Display
   ↓
[RF Signal]   [Audio]    [Bits]      [Text+CRC]      [Message]
```

## 🎮 Half-Duplex State Machine

```
    ┌──────┐
    │ IDLE │ ←──────────────┐
    └───┬──┘                │
        │                   │
        │ Request TX        │
        ↓                   │
  ┌──────────┐              │
  │ TRANSMIT │              │
  └─────┬────┘              │
        │                   │
        │ Send Complete     │
        ↓                   │
   ┌────────┐               │
   │ RECEIVE├───────────────┘
   └────────┘
```

## 🛠️ Command-Line Usage

For advanced users or debugging:

```matlab
% Configure radios
[txSDR, rxSDR] = pluto_config('usb:0', 'usb:1', 145e6, 0, 20);

% Transmit message
tx_chain('Hello World!', txSDR, 'N0CALL', 'CQ');

% Receive (10 seconds)
[msg, valid, src, dst] = rx_chain(rxSDR, 10);
if valid
    fprintf('Received from %s: %s\n', src, msg);
end
```

## 📚 Key Functions

| Function         | Purpose                          |
| ---------------- | -------------------------------- |
| `ax25_encode()`  | Convert text to AX.25 frame bits |
| `ax25_decode()`  | Decode AX.25 frame to text       |
| `afsk_mod()`     | Generate 1200/2200 Hz tones      |
| `afsk_demod()`   | Detect tones and recover bits    |
| `fm_mod()`       | Apply FM modulation              |
| `fm_demod()`     | Demodulate FM signal             |
| `tx_chain()`     | Complete transmission pipeline   |
| `rx_chain()`     | Complete reception pipeline      |
| `pluto_config()` | Configure Pluto SDR devices      |

## ⚠️ Important Notes

### Frequency Licensing

- **145 MHz requires amateur radio license** in most countries
- Check your local regulations before transmitting
- Consider using 433 MHz ISM band (check local rules)

### Safety

- Low power output (<10 mW typical)
- Avoid transmitting near sensitive equipment
- Use appropriate antennas

### Performance

- **Latency:** ~1 second round-trip
- **Range:** Varies by frequency, power, and antennas
- **Reliability:** Best with line-of-sight

## 🐛 Troubleshooting

| Issue              | Solution                                         |
| ------------------ | ------------------------------------------------ |
| No radios detected | Check USB connections, reinstall drivers         |
| Poor reception     | Increase RX gain, check frequency match          |
| CRC errors         | Reduce distance, check for interference          |
| GUI won't load     | Use command-line interface, check MATLAB version |

See **USER_GUIDE.md** for detailed troubleshooting.

## 🎓 Educational Value

This project demonstrates:

- **Digital Communications:** Modulation, demodulation, framing
- **Signal Processing:** Filtering, envelope detection, FFT
- **Protocol Implementation:** AX.25 packet radio standard
- **SDR Programming:** Real-time I/Q processing
- **State Machines:** Half-duplex coordination
- **GUI Development:** MATLAB App Designer

## 📖 Resources

- [AX.25 Protocol Specification](http://www.ax25.net/)
- [Bell 202 AFSK Standard](https://en.wikipedia.org/wiki/Bell_202_modem)
- [ADALM-Pluto Documentation](https://wiki.analog.com/university/tools/pluto)
- [MATLAB Communications Toolbox](https://www.mathworks.com/products/communications.html)

## 👨‍💻 Development Notes

**Design Philosophy:**

- Beginner-friendly (no complex sync algorithms)
- Modular (each component independently testable)
- Well-documented (extensive comments)
- Practical (real-world SDR application)

**Simplifications:**

- Basic threshold detection (no PLL)
- Simplified AX.25 (not full spec)
- Fixed parameters (no adaptive algorithms)
- Optional CRC checking

## 🚧 Future Enhancements

Possible improvements:

- [ ] Add CSMA/CD collision avoidance
- [ ] Implement automatic frequency correction
- [ ] Add forward error correction (FEC)
- [ ] Support multi-user chat rooms
- [ ] Add spectrum analyzer display
- [ ] Implement automatic gain control (AGC)

## 📄 License

Educational and experimental use. Not for commercial applications.

## 🙏 Acknowledgments

Built using:

- MATLAB Communications Toolbox
- ADALM-Pluto SDR
- AX.25 amateur packet radio protocol
- Bell 202 AFSK standard

---

**Happy Experimenting! 📡✨**
