# Mu2e DAQ Control Room — Operator Instructions

How to set up, operate, and troubleshoot the Mu2e DAQ control room
systems: the six VNC viewport sessions, the ssh tunnels that reach
them, the desktop application launchers, and the service discovery
tools.

Built from two packages in this meta-repository:

- **[mu2edaq-controlroom-setup](mu2edaq-controlroom-setup/)** — VNC
  sessions, tunnels, desktop provisioning, GUI
- **[mu2edaq-discovery](mu2edaq-discovery/)** — service discovery
  protocol and the `mu2edaq-discover` query tool

---

## 1. The big picture

```
 your machine (Mac/Linux)         mu2egateway01.fnal.gov          DAQ hosts
┌──────────────────────────┐      ┌───────────────┐      ┌──────────────────────────┐
│ crs-remote ──── ssh -J ──┼──────┤   ProxyJump   ├──────┤ ~/controlroom/bin/       │
│ crs-tunnel ──── ssh -L ──┼──────┤  (Kerberos)   ├──────┤   start-vnc-session.sh   │
│ crs-gui (PyQt6)          │      └───────────────┘      │   vncserver :N + XFCE    │
│ vncviewer → localhost:595x                             │   discovery responder    │
└──────────────────────────┘                             └──────────────────────────┘
```

Six VNC sessions act as the DAQ viewports. Each runs a TigerVNC server
bound to **localhost only** on its DAQ host — the only way in is an ssh
tunnel through the gateway. Inside each session an XFCE desktop carries
start/stop icons for the DAQ applications assigned to it.

| Session | Host | Account | Display | Geometry | Your local port |
|---|---|---|---|---|---|
| shift-main | mu2e-mgr-01 | mu2eshift | :1 | 2560x1440 | 5951 |
| shift-aux  | mu2e-mgr-01 | mu2eshift | :2 | 1920x1080 | 5952 |
| daq-main   | mu2e-dl-01  | mu2edaq   | :1 | 2560x1440 | 5953 |
| daq-aux    | mu2e-dl-01  | mu2edaq   | :2 | 1920x1080 | 5954 |
| daq-dl2    | mu2e-dl-02  | mu2edaq   | :1 | 2560x1440 | 5955 |
| dcs-main   | mu2e-dcs-01 | mu2edcs   | :1 | 2560x1440 | 5956 |

Everything above is configured in **one file**:
`mu2edaq-controlroom-setup/config/controlroom.yaml` (sessions, hosts,
accounts, geometries, ports, gateway). Application/port assignments
live next to it in `config/apps.yaml`.

## 2. One-time setup on your machine

Prerequisites: Python 3.9+, TigerVNC viewer (`vncviewer`), Kerberos
tools (`kinit`/`klist`), and ssh access to `mu2egateway01.fnal.gov`.

```bash
cd mu2edaq-controlroom-setup
./bootstrap.sh                  # venv + PyQt6 + mu2edaq-discovery
```

Get a Kerberos ticket. Either plain `kinit you@FNAL.GOV`, or use the
keytab manager for the shared principals (keytabs in
`~/Kerberos_Keytabs/Mu2e/<principal>.keytab`):

```bash
python3 ../mu2edaq-controlroom/mu2e-krb-cron.py     # renews from keytabs
klist -s && echo "ticket OK"
```

Every `crs-*` command checks the ticket first and tells you if it is
missing.

## 3. One-time setup of the DAQ hosts

Install the control room bin area onto every (host, account) pair, then
generate the desktop icons:

```bash
venv/bin/crs-remote install --all       # ships scripts+configs over ssh
venv/bin/crs-remote provision --all     # writes ~/Desktop/*.desktop icons
```

`install` creates `~/controlroom/{bin,etc,log}` on each host, adds
`~/controlroom/bin` to the account's PATH (marker-guarded stanza in
`~/.bash_profile`), and symlinks every application's standardized
`start-<app>.sh`/`stop-<app>.sh` into the bin area. It is safe to
re-run at any time — re-run it after changing `controlroom.yaml` or
`apps.yaml` to push the new configs.

Each session account also needs a VNC password set once on its host:
`ssh -J mu2egateway01.fnal.gov <account>@<host> vncpasswd`.

## 4. Daily operation

### Start everything

```bash
cd mu2edaq-controlroom-setup
bin/start-controlroom.sh        # starts all 6 sessions + opens all tunnels
```

### Connect a viewer

```bash
venv/bin/crs-tunnel connect --session daq-main     # opens tunnel if needed,
                                                   # launches vncviewer -Shared
```

Viewers attach **shared**, so several operators can watch the same
session at once.

### Or use the GUI

```bash
venv/bin/crs-gui
```

- **Tunnels tab** — one row per session with live state (probed every
  15 s), Open / Close / Connect buttons, and open-all/close-all.
- **Discovery tab** — press **Scan** to list every running DAQ service:
  name, type, node, port, start time. Double-click a VNC row to tunnel
  in and attach a viewer. Use *Via gateway* mode (the default) from
  off-site; *Local multicast* works on the cluster network.

### Stop everything

```bash
bin/stop-controlroom.sh         # closes tunnels, stops sessions
```

### Piecemeal control

```bash
venv/bin/crs-remote start  --session daq-dl2     # one session
venv/bin/crs-remote status                       # all sessions (parseable)
venv/bin/crs-tunnel open   --host mu2e-dl-01     # all tunnels to one host
venv/bin/crs-tunnel status
venv/bin/crs-remote stop   --all
```

## 5. Inside a VNC session

Each desktop has paired icons per application — **Start X** and
**Stop X**. The icons call `crs-app`, which:

1. reads the app's port assignments from `~/controlroom/etc/apps.yaml`,
2. exports them as `CRS_PORT_<NAME>` environment variables,
3. execs the app's `start-<app>.sh` with `DISPLAY` already pointing at
   the session.

From a terminal inside the session the same thing is:

```bash
crs-app list                # what's installed, with port assignments
crs-app start dashboard
crs-app stop  dashboard
```

Port assignments worth knowing (set in `apps.yaml` to avoid clashes):

| App | Port(s) | Note |
|---|---|---|
| dashboard | HTTP 5001, ZMQ 5555 | |
| diskwatcher | HTTP 5002 | |
| fts | HTTP 5003 | |
| runlog-db | HTTP 8000 | |
| resource-manager | HTTP 8080 | owns 8080 |
| heartbeatmonitor | HTTP **8081**, UDP 9999 | moved off 8080 |
| downtime-logger | HTTP 8088 | |
| controlcenter | TCP 9876 | command server |
| trigger-scalers | UDP **5557**, ZMQ 5556 | moved off 5555 |
| bigredbox | UDP 37020 | |
| dataformat-viewer | TCP 7755 | |

## 6. Service discovery

Every integrated DAQ application announces itself over the
**mu2edaq-discovery** protocol (UDP multicast `239.255.42.99:28999`,
JSON query/response). VNC sessions are announced by a sidecar responder
launched with each session.

From a cluster node (or inside any VNC session):

```bash
mu2edaq-discover                       # table: name, app, host, port, id
mu2edaq-discover --filter app=vnc      # just the VNC sessions
mu2edaq-discover --json                # machine-readable
```

From your machine (multicast does not cross the gateway):

```bash
ssh -J mu2egateway01.fnal.gov mu2edaq@mu2e-dl-01.fnal.gov \
    'mu2edaq-discover --json'
```

…or just use the **Discovery tab** in `crs-gui`, which does exactly
that in *Via gateway* mode.

To make your own application discoverable:

```python
from mu2edaq_discovery import Responder
r = Responder(name="My Service", app="myservice", port=8123, scheme="http")
r.start()      # after your listening socket is bound
...
r.stop()       # on shutdown
```

Protocol details: `mu2edaq-discovery/doc/PROTOCOL.md`.

## 7. Changing the configuration

All knobs are YAML; precedence is **command line > environment (CRS_*)
> config file > defaults**.

- **Session geometry / layout** — edit `sessions:` in
  `mu2edaq-controlroom-setup/config/controlroom.yaml`, then
  `crs-remote install --all` (push configs) and restart the affected
  session.
- **Which icons appear on which desktop** — edit each app's
  `sessions:` list in `config/apps.yaml`, then
  `crs-remote install --all && crs-remote provision --all`.
- **Port assignments** — edit `ports:` in `apps.yaml`; the values reach
  the apps as `CRS_PORT_*` env vars at launch.
- **Gateway / accounts** — `controlroom.yaml` (`gateway:`,
  per-session `account:`), or `CRS_GATEWAY` for a one-off.

## 8. Troubleshooting

| Symptom | Check |
|---|---|
| `error: No valid Kerberos ticket` | `kinit you@FNAL.GOV` or run the keytab manager (section 2). |
| Tunnel opens but viewer can't connect | `crs-remote status --session <name>` — is the session `running`? Start it with `crs-remote start`. |
| `tunnel open failed … Permission denied` | Your principal isn't in the account's `.k5login` on that host, or the ticket isn't forwardable. |
| Session shows `stopped` right after start | Look at `~/controlroom/log/vnc-<name>.log` on the host (usually a missing `vncpasswd` or no XFCE installed). |
| Stale tunnel socket | `crs-tunnel close --session <name>` removes it; sockets live in `~/.crs/`. |
| Icons missing on a desktop | `crs-remote provision --session <name>`; confirm the app lists that session in `apps.yaml`. |
| App starts on the wrong port | `crs-app list` on the host shows the assignments actually installed; re-run `crs-remote install` after editing `apps.yaml`. |
| Discovery scan finds nothing on-cluster | The site network may block multicast group 239.255.42.99; responders still answer unicast queries — try from the same host first. |
| Responder shown `dead` in status | Harmless to the session; `crs-remote stop` + `start` relaunches it. |

## 9. Man pages

Every tool ships one:

```bash
man mu2edaq-controlroom-setup/man/man1/crs-tunnel.1
man mu2edaq-controlroom-setup/man/man1/crs-remote.1
man mu2edaq-controlroom-setup/man/man1/crs-gui.1
man mu2edaq-controlroom-setup/man/man1/crs-app.1
man mu2edaq-controlroom-setup/man/man1/start-vnc-session.1
man mu2edaq-controlroom-setup/man/man1/install-controlroom.1
man mu2edaq-discovery/man/mu2edaq-discover.1
```

## 10. Status of the per-application integration

The start/stop standardization and discovery support were submitted as
PRs (branch `controlroom-integration`) against: bigredbox, CFOControl,
controlcenter, dashboard, dataformat-viewer, diskwatcher,
downtime-logger, fts, heartbeatmonitor, resource-manager, runlog-db,
and trigger-scalers. Until a repo's PR is merged, its old script names
still work (the new names are added with the old kept as symlinks).
trigger-scalers uses a Python discovery sidecar pending the C++
mu2edaq-discovery library.
