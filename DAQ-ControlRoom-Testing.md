# Mu2e DAQ Control Room — Testing Guide

How to verify the control room software at every level, from unit tests
you can run on a laptop to the full ssh→tunnel→VNC chain on the real
cluster. Work top to bottom: each tier assumes the ones above it pass.

Covers the two new packages —
[mu2edaq-discovery](mu2edaq-discovery/) and
[mu2edaq-controlroom-setup](mu2edaq-controlroom-setup/) — plus the
per-application integration PRs.

| Tier | What it proves | Needs |
|---|---|---|
| 1. Unit tests | Protocol, config, tunnel/argv, desktop generation | laptop |
| 2. Discovery loop | A responder is found by the CLI | laptop |
| 3. Per-app smoke | Each DAQ app announces and shuts down cleanly | laptop + each app's venv |
| 4. GUI | crs-gui tabs work, threads don't block | laptop (offscreen OK) |
| 5. Tunnel chain (mock) | ssh -J / -L plumbing via a local container | laptop + Docker/Podman |
| 6. On-cluster | The real thing, staged | cluster + Kerberos |

---

## Tier 1 — Automated unit tests

```bash
# discovery: protocol round-trips + live loopback multicast
cd mu2edaq-discovery && ./bootstrap.sh && venv/bin/pytest        # expect 13 passed

# controlroom-setup: config validation, tunnel argv, payload, .desktop gen
cd ../mu2edaq-controlroom-setup && ./bootstrap.sh && venv/bin/pytest   # expect 38 passed
```

The discovery loopback tests skip automatically where multicast on
127.0.0.1 is unavailable (some CI sandboxes); they run on macOS/Linux.

## Tier 2 — Discovery query/response loop

Two terminals, from `mu2edaq-discovery/`:

```bash
# Terminal A — a responder (this is what apps embed)
venv/bin/python -c "
from mu2edaq_discovery import Responder
import signal
Responder(name='Test', app='dashboard', port=5001, scheme='http').start()
print('announcing — Ctrl-C to stop'); signal.pause()"

# Terminal B
venv/bin/mu2edaq-discover                 # should list 'Test / dashboard / 5001'
venv/bin/mu2edaq-discover --filter app=vnc   # should be empty
venv/bin/mu2edaq-discover --json          # machine-readable
```

Pass: Terminal B lists the responder; the `app=vnc` filter excludes it.

## Tier 3 — Per-application smoke test

For each integrated app, the recipe is the same: install discovery into
its venv, launch it, confirm `mu2edaq-discover` sees it with the right
app id and port, then confirm it disappears on shutdown.

```bash
APP=mu2edaq-dashboard          # repeat per repo
cd $APP
# Stale venvs may have a broken pip shebang — always go through python -m pip:
venv/bin/python -m pip install -e ../mu2edaq-discovery

# Launch (substitute each app's real entry point + config; see table below)
venv/bin/python dashboard.py --config config/dashboard_config.yaml --no-daemon &
APP_PID=$!; sleep 4

# Discover it
../mu2edaq-discovery/venv/bin/mu2edaq-discover --filter app=dashboard --timeout 2

# Shut down and confirm it's gone
kill -TERM $APP_PID; sleep 2
../mu2edaq-discovery/venv/bin/mu2edaq-discover --filter app=dashboard --timeout 2  # No services found
```

Entry points, config flags, and how to launch each (GUI apps need
`QT_QPA_PLATFORM=offscreen` on a headless box):

| App | Launch | Config flag | Announced port |
|---|---|---|---|
| dashboard | `dashboard.py --no-daemon` | `--config` | 5001 (+ZMQ 5555 in meta) |
| diskwatcher | `diskwatcher.py` | *(no `--config`; uses default search)* | 5002 |
| fts | `mu2edaq_fts.py` | `--config` (needs source+destination set) | web port |
| heartbeatmonitor | `heartbeat_monitor.py` | **`-c`** (not `--config`) | 8081 (+UDP 9999 meta) |
| resource-manager | `server/app.py --port 8080` | `--config`/`--state` | 8080 |
| downtime-logger | `python -m downtime_logger` | `--config`/`-c` (needs `webserver.enabled`) | 8088 |
| controlcenter | `src/controlcenter.py` | `--config` | 9876 |
| dataformat-viewer | GUI — announces **only while listening** | `--config` | 7755 |
| bigredbox | `daq_alert.py` | *(none)* | 37020 |
| trigger-scalers | build first, then `./start-mu2edaq-trigger-scalers.sh` | `--config` | 5557 (+ZMQ 5556 meta) |

Notes:
- **Port override**: prefix any launch with e.g. `CRS_PORT_HTTP=5099` and
  confirm discovery reports 5099 — proves the control-room launcher's
  env override reaches the advertised port.
- **dataformat-viewer** only announces while the listener is active.
  Drive it headless: construct `Mu2eViewer(cfg)`, call `_start_server()`,
  scan (found), call `_stop_server()`, scan (gone).
- **trigger-scalers** is C++ — build with `cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j4`
  (Homebrew Qt5 + zeromq on macOS). Its discovery runs as a **Python
  sidecar**; that sidecar uses the system `python3`, so
  `mu2edaq-discovery` must be importable there, not just in a venv.
- **bigredbox**: send a test alert with `demo_sender.py` while it runs to
  confirm the UDP listener still works alongside the responder thread.

Pass: every app appears with the correct app id + port while running and
is absent after a clean `SIGTERM`. (Hard `kill -9` can orphan a
responder — see Troubleshooting.)

## Tier 4 — GUI (crs-gui)

On a desktop, just run `mu2edaq-controlroom-setup/venv/bin/crs-gui` and
click around. Headless verification of both tabs and the threading model:

```bash
cd mu2edaq-controlroom-setup
QT_QPA_PLATFORM=offscreen venv/bin/python - <<'PY'
import sys, time
from PyQt6.QtWidgets import QApplication
from mu2edaq_controlroom_setup.config import load_config
from mu2edaq_controlroom_setup.gui.main import MainWindow
from mu2edaq_discovery import Responder
def pump(app, s):
    end=time.monotonic()+s
    while time.monotonic()<end: app.processEvents(); time.sleep(0.02)
app=QApplication(sys.argv); win=MainWindow(load_config("config/controlroom.yaml")); win.show()
tt=win.tunnels_tab; pump(app,3)
assert tt.table.rowCount()==6
assert all(tt.table.item(r,5).text()=="closed" for r in range(6))
dt=win.discovery_tab; dt.mode_box.setCurrentIndex(1)        # Local multicast
r=Responder(name="GUI Test",app="dashboard",port=5001); r.start(); time.sleep(0.3)
dt.scan(); pump(app,4)
assert any(dt.table.item(i,1).text()=="dashboard" for i in range(dt.table.rowCount()))
r.stop(); win.close(); print("GUI PASS")
PY
```

Pass: prints `GUI PASS`. This proves the tunnels status sweep and the
discovery scan both run in worker threads and deliver results back to the
UI without blocking. The Tunnels tab needs **no Kerberos ticket** while
tunnels are closed (status short-circuits before any ssh).

## Tier 5 — Tunnel/VNC chain against a local container (no cluster)

Exercises `install → start → tunnel → vncviewer → desktop icons →
discovery` without the cluster or Kerberos, using `--ssh-config` to alias
the cluster hostnames to a local container.

1. Run a Linux container with sshd + TigerVNC + XFCE and a test user.
   Example (Podman/Docker), publishing ssh on 2222:
   ```bash
   # In the container: dnf install -y openssh-server tigervnc-server xfce4 ...
   #                   create user 'mu2edaq', set authorized_keys, start sshd
   podman run -d --name crs-test -p 2222:22 <your-image>
   ```
2. Write an ssh config that maps the gateway and every session host to
   the container, and disables GSSAPI (no Kerberos in the harness):
   ```
   # tests/fixtures/ssh_config
   Host mu2egateway01.fnal.gov
       HostName 127.0.0.1
       Port 2222
       User mu2edaq
       GSSAPIAuthentication no
       IdentityFile ~/.ssh/crs_test_key
   Host mu2e-mgr-01.fnal.gov mu2e-dl-01.fnal.gov mu2e-dl-02.fnal.gov mu2e-dcs-01.fnal.gov
       HostName 127.0.0.1
       Port 2222
       User mu2edaq
       ProxyJump mu2egateway01.fnal.gov
       GSSAPIAuthentication no
       IdentityFile ~/.ssh/crs_test_key
   ```
   (For a single-host harness, point ProxyJump at the same container.)
3. Temporarily bypass the Kerberos preflight: the `crs-*` tools call
   `klist -s` first. For the harness, either hold a dummy ticket or run
   against a build where `sshutil.check_ticket()` is stubbed. Simplest is
   to test the server-side scripts directly over the harness ssh config.
4. Drive the chain:
   ```bash
   cd mu2edaq-controlroom-setup
   F=tests/fixtures/ssh_config
   venv/bin/crs-remote install --all --ssh-config $F
   venv/bin/crs-remote start   --session daq-dl2 --ssh-config $F
   venv/bin/crs-remote status  --all --ssh-config $F      # daq-dl2 'running'
   venv/bin/crs-tunnel  open    --session daq-dl2 --ssh-config $F
   vncviewer -Shared localhost:5955                       # XFCE + desktop icons
   ssh -F $F mu2edaq@mu2e-dl-02.fnal.gov 'mu2edaq-discover --filter app=vnc --json'
   venv/bin/crs-tunnel  close   --session daq-dl2 --ssh-config $F
   venv/bin/crs-remote stop     --session daq-dl2 --ssh-config $F
   ```

Pass: the viewer shows an XFCE desktop with start/stop icons; clicking a
start icon launches the app on that display; `mu2edaq-discover` on the
container lists the VNC session and any started apps.

## Tier 6 — On-cluster smoke test (staged, lowest-risk first)

Do this only after Tiers 1–4 pass. Start with the least-critical
session (`daq-dl2` on mu2e-dl-02) before touching shift machines.

Prerequisites on your machine: a valid Kerberos ticket
(`kinit you@FNAL.GOV` or the keytab manager
`mu2edaq-controlroom/mu2e-krb-cron.py`), `klist -s` clean, and
`vncviewer` installed. On each session account: a VNC password set once
(`ssh -J mu2egateway01.fnal.gov <acct>@<host> vncpasswd`).

```bash
cd mu2edaq-controlroom-setup

# 1. Install + start one safe session
venv/bin/crs-remote install --session daq-dl2
venv/bin/crs-remote start   --session daq-dl2

# 2. Verify on the host: server up, localhost-only, responder alive
venv/bin/crs-remote status  --session daq-dl2      # running | :1 | 5901 | running | alive
ssh -J mu2egateway01.fnal.gov mu2edaq@mu2e-dl-02.fnal.gov \
    'vncserver -list; ss -ltn | grep 5901'         # 5901 bound to 127.0.0.1 only

# 3. First real multicast test on the DAQ LAN
ssh -J mu2egateway01.fnal.gov mu2edaq@mu2e-dl-02.fnal.gov \
    'mu2edaq-discover --filter app=vnc'            # lists the daq-dl2 session

# 4. Tunnel in and look
venv/bin/crs-remote provision --session daq-dl2    # desktop icons
venv/bin/crs-tunnel  connect  --session daq-dl2     # opens tunnel + vncviewer

# 5. If all good, roll out the rest and check end-to-end
venv/bin/crs-remote install --all
venv/bin/crs-remote start   --all
venv/bin/crs-remote status  --all
venv/bin/crs-gui                                    # both tabs, Scan via gateway

# 6. Clean teardown — confirm no orphans
bin/stop-controlroom.sh
ssh -J mu2egateway01.fnal.gov mu2edaq@mu2e-dl-02.fnal.gov \
    'vncserver -list; ls ~/.crs/'                  # no stray Xvnc, no stale sockets
```

Watch for:
- **Multicast policy** — step 3 is the first time discovery's multicast
  group (239.255.42.99) meets the site network. If it's blocked,
  responders still answer **unicast** queries, and the GUI's *Via
  gateway* mode (which runs `mu2edaq-discover` over ssh) keeps working —
  that's the production path anyway.
- **`.k5login`** — `Permission denied` on a session host usually means
  your principal isn't authorized for that role account.
- **Discovery on the host python** — the VNC responder sidecar and the
  trigger-scalers sidecar import `mu2edaq-discovery` from the session
  account's `python3`; make sure the install put it there.

## Troubleshooting tests

| Symptom | Cause / fix |
|---|---|
| `venv/bin/pip: bad interpreter` | venv was relocated; use `venv/bin/python -m pip`, or recreate the venv. |
| App runs but `mu2edaq-discover` finds nothing | discovery not installed in that app's python; or queried before startup finished (apps with unreachable detectors, e.g. downtime-logger's `daq01`, can be slow — wait 10–12 s). |
| Stale "…Alerts/…" entry keeps appearing | an app was `kill -9`'d and its responder outlived it. Find it: `ps aux | grep -E "daq_alert|responder"`; kill the PID. Stop scripts (SIGTERM) don't leak; only hard-kills do. |
| GUI test hangs | event loop not pumped — ensure `app.processEvents()` runs while waiting on worker threads. |
| `crs-*` exits "No valid Kerberos ticket" | expected off-cluster; for the container harness test the server scripts directly or stub `check_ticket()`. |

## Current status (verified on macOS, 2026-06-15)

- Tier 1: ✅ 13 + 38 tests passing
- Tier 2: ✅ responder found by CLI
- Tier 3: ✅ all 11 announcing apps (9 Python launched, trigger-scalers
  built from source + sidecar, CFOControl is a CLI with nothing to
  announce); `CRS_PORT_*` overrides confirmed for diskwatcher (5099),
  heartbeatmonitor (8081), fts (5003), trigger-scalers (5557)
- Tier 4: ✅ crs-gui both tabs, threading verified
- Tier 5: ⬜ not yet run (needs container)
- Tier 6: ⬜ not yet run (needs cluster + Kerberos)
