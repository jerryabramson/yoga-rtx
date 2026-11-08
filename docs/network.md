# Wired network: Realtek RTL8159 10 GbE USB adapter

The internal Wi-Fi (MediaTek MT7925) works out of the box, at about
1.35 Gbit/s measured. The Thunderbolt dock's own Ethernet doesn't work (it
needs USB4 PCIe tunnelling; see
[acpi-findings.md](acpi-findings.md#usb4--thunderbolt)), so wired networking
uses a USB adapter.

## RTL8159 (`0bda:815a`) on a 7.0 kernel

The 7.0 kernel's `r8152` doesn't know the RTL8159 (in-kernel support arrives
in 7.2), so the adapter falls back to the generic `cdc_ncm` driver. Downloads
then cap out around 2 Gbit/s.

The fix is Realtek's own out-of-tree `r8152` driver, built by DKMS:

```sh
sudo network/install.sh ~/Downloads/r8152-v2.22.1.tar.gz
```

Then unplug and replug the adapter. The script:

- unpacks the tarball into `/usr/src/r8152-<version>` and registers it with
  DKMS (`network/dkms.conf`), so it rebuilds for new kernels. DKMS installs to
  `updates/dkms/`, which takes priority over the stock driver without deleting
  it; Realtek's own `make install` would delete it;
- installs Realtek's `50-usb-realtek-net.rules`, which switches the adapter to
  its vendor USB configuration so `r8152` binds it instead of `cdc_ncm`;
- reloads `r8152`, because a stock copy already in memory would otherwise keep
  running and leave the adapter unbound until a reboot.

`sudo network/install.sh --uninstall` removes it all, and the adapter goes back
to `cdc_ncm`.

Get the tarball from Realtek's download page for the RTL8152/RTL815x USB
Ethernet Linux driver. Tested with **v2.22.1 (2026-06-03)**. Secure Boot was
off on the reference machine; with Secure Boot on, DKMS has to sign the
module with an enrolled MOK.

### Result

Adapter on a USB 3.2 Gen 2×2 (20 Gbit/s) port, link 10000 Mb/s, iperf3 with
8 streams against a 10 GbE host:

| Driver | Download | Upload |
|---|---|---|
| `cdc_ncm` (stock 7.0) | 2.15 Gbit/s | 6.11 Gbit/s |
| `r8152` v2.22.1 (Realtek, DKMS) | **6.33 Gbit/s** | **6.9 Gbit/s** |

### Gotchas

- An inherited `ARCH=aarch64` in the environment breaks out-of-tree builds
  (`arch/aarch64/Makefile: No such file`). The kernel calls it `arm64`, which
  `dkms.conf` sets explicitly.
- Once the stock kernel reaches 7.2, its own `r8152` supports the RTL8159, and
  this DKMS module can go (`--uninstall`).
