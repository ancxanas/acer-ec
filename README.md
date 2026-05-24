# acer-ec — Acer EC communication framework

[!CAUTION]
> **This is experimental software.** Writing incorrect values can overheat your
> laptop. Fan 1 (CPU) is EC-protected and manual duty control has no effect.
> Use at your own risk.

## Supported hardware

- **Laptop** — Acer Aspire A715-79G (i7-13620H, RTX 3050)
- **EC** — ITE 8222 (ACPI EC at `0x62/0x66`)
- **ACPI WMI** — 3 GUIDs (ABBC0F6B, ABBC0F6C, ABBC0F6D)

Likely compatible with any Acer/Nitro/Predator laptop built on the same EC
firmware platform. Tested on **Fedora 44** with kernel **6.14.x**.

## What it does

| Sysfs file | Access | Description |
|---|---|---|
| `profile` | RW (1-4) | Fan profile: 1=quiet, 2=balanced, 3=performance, 4=gaming |
| `fan1_duty` | RO | Fan 1 duty cycle (0-255), EC-managed |
| `fan2_duty` | RO | Fan 2 duty cycle (0-255) |
| `fan1_rpm` | RO | Fan 1 speed (real RPM) |
| `fan2_rpm` | RO | Fan 2 speed (real RPM) |
| `fan3_rpm` | RO | Always 0 (unused slot) |
| `fan4_rpm` | RO | Always 0 (unused slot) |
| `fan1_duty_set` | WO | Write Fan 1 duty (experimental — likely no effect) |
| `fan2_duty_set` | WO | Write Fan 2 duty (0-255, e.g. `echo 0 > fan2_duty_set`) |
| `tmp_temp` | RO | ACPI temperature (°C) |
| `dthl_val` | RO | Throttle level (bitmask) |
| `dtbp_val` | RO | Turbo boost power band |
| `airp_val` | RO | Airplane / temperature band |
| `winf_val` | RO | Windows interface flags |
| `rinf_val` | RO | Radio info flags |
| `all` | RO | One-shot dump of all values |

### Examples

```bash
# Set balanced profile
echo 2 > /sys/kernel/acer_fanctl/profile

# Set GPU fan to 100% (max)
echo 255 > /sys/kernel/acer_fanctl/fan2_duty_set

# Stop GPU fan (0% duty, fan coasts)
echo 0 > /sys/kernel/acer_fanctl/fan2_duty_set

# Read everything
cat /sys/kernel/acer_fanctl/all
```

## Architecture

Two kernel modules, loaded in order:

```
acer_ec_core.ko      # infrastructure — ioremap + ACPI handle
    ↓ depends
acer_fanctl.ko       # consumer — sysfs interface
```

- `acer_ec_core` exports `ec_core_read8`, `ec_core_read16`, `ec_core_scmd`
- `acer_fanctl` uses the core API, never touches hardware directly
- Future modules (keyboard backlight, battery limits) can also use the core

## Install

```bash
git clone https://github.com/YOUR_USER/acer-ec.git
cd acer-ec
chmod +x install.sh
sudo ./install.sh
```

### Manual rebuild after kernel update

```bash
sudo make -C /lib/modules/$(uname -r)/build M=$(pwd) clean modules
sudo make modules_install INSTALL_MOD_PATH=/
sudo depmod -a
sudo modprobe -r acer_fanctl acer_ec_core
sudo modprobe acer_fanctl
```

Or install via DKMS:

```bash
sudo dkms add .
sudo dkms install acer-ec/0.1
```

## Uninstall

```bash
sudo ./uninstall.sh
```

## Files

```
acer-ec/
├── src/
│   ├── acer_ec_core.c
│   ├── acer_ec_core.h
│   └── acer_fanctl.c
├── dkms.conf
├── Makefile
├── install.sh
├── uninstall.sh
├── LICENSE              (GPL-2.0)
├── README.md
└── docs/
    └── reverse-engineering.md
```

## Limitations

- **Fan 1 (CPU) is EC-protected.** Manual duty writes via `fan1_duty_set` are
  accepted but the EC firmware overwrites DUT1 within ~500ms. Use `profile`
  switching for indirect CPU fan control.
- **No `dracut --force` needed.** Modules are loaded after rootfs via
  `modules-load.d`. Initramfs inclusion is unnecessary.
- **RPM values** are converted from raw tachometer periods. Formula:
  `RPM = 60,000,000 / raw`. Raw values ~40000 → ~1500 RPM.

## License

GNU General Public License v2.0 — see [LICENSE](LICENSE).
