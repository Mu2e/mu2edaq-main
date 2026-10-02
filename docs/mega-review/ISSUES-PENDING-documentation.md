# Staged issues — `Mu2e/mu2edaq-documentation`

Filing via `gh issue create` was blocked by the session's permission policy, so these are
staged here in the exact body format from `CONTRACT.md` §6. Each can be filed verbatim
once permission is granted; fingerprints are line-number independent, so filing later
will not duplicate against a re-run.

The `mega-review` label already exists in this repo (created 2026-09-30).

---

## 1. `[connecting] OTS gateway host disputed: mu2egateway01 vs mu2egateway02 on :8443`

Labels: `mega-review`, `bug`

**Severity:** S2 — production breakage or silent wrong behaviour; workaround exists
**Category:** bug
**Location:** `shifter/docs/connecting.md:32`, `shifter/docs/systems.md:15`, `shifter/docs/ots/README.md:16`
**Found by:** mega-review (`mu2e-sept-mega-review`), 2026-09-30

### What

Three pages give the top-level OTS URL on two different hosts, same port.

### Evidence

```
connecting.md:32   https://mu2egateway01.fnal.gov:8443/urn:xdaq-application:lid=200
systems.md:15      https://mu2egateway02.fnal.gov:8443/urn:xdaq-application:lid=200
ots/README.md:16   https://mu2egateway02.fnal.gov:8443/urn:xdaq-application:lid=200
```

`connecting.md:28` also states the general on-site rule as `https://mu2egateway01.fnal.gov:<PORT>`,
but the only other on-site URL in the docs is Grafana at `mu2egateway01:8448`. So "everything is on
gateway01" does not resolve it — the rule holds for Grafana and is contradicted for OTS by two of
the three pages. Separately, every ssh/ProxyJump path in the docs uses `mu2egateway02` except
`experts/STM/connecting.md:12`.

### Why it matters

A shifter following `connecting.md` and one following `systems.md` open run control on different
machines. One of them is wrong.

### Suggested fix

Confirm which gateway serves OTS on 8443, correct the two wrong pages, and remove the warning
admonitions added in `efc6ab6`.

<!-- mega-review-fingerprint: 7c1a4f02 -->

---

## 2. `[cold-start] Calorimeter node range disagrees three ways`

Labels: `mega-review`, `bug`

**Severity:** S2
**Category:** bug
**Location:** `shifter/docs/experts/daq/cold-start.md:55`, `shifter/docs/experts/daq/flash-firmware.md:77,86,95,205`
**Found by:** mega-review (`mu2e-sept-mega-review`), 2026-09-30

### What

Two adjacent expert pages use three different calorimeter node sets.

### Evidence

```
cold-start.md:55        calo-{01..14}              # 14 nodes, contiguous
flash-firmware.md:77    calo-{01..12} calo-14      # 13 nodes, calo-13 skipped
flash-firmware.md:86    calo-{01..12} calo-14
flash-firmware.md:95    calo-{01..12} calo-14
flash-firmware.md:205   calo-{01..12}              # 12 nodes
```

### Why it matters

`cold-start.md:55` runs `ssh root@mu2e-$node shutdown -h now` over its range. If calo-13 does not
exist — which the firmware page's deliberate skip implies — that loop stalls on an unreachable host
during a shutdown procedure.

### Suggested fix

Establish the real node set and use it consistently. If calo-13 is intentionally absent, say so
once in a note rather than silently skipping it in three places.

<!-- mega-review-fingerprint: 3b9e5d17 -->

---

## 3. `[flash-firmware] STM procedure flashes a CRV-named bitstream`

Labels: `mega-review`, `bug`

**Severity:** S2
**Category:** bug
**Location:** `shifter/docs/experts/daq/flash-firmware.md:154-159`
**Found by:** mega-review (`mu2e-sept-mega-review`), 2026-09-30

### What

The STM firmware section, run on `mu2e-stm-02`, flashes an image whose path says CRV.

### Evidence

```
## STM
Run as user `mu2eshift` on **`mu2e-stm-02`** ...
   /home/mu2ehwdev/program_all_FPGA_AL9.sh \
     /home/mu2ehwdev/DTC_Firmware/DTC2026Apr20_08_22.1_CRV_6ROC/DTC.bit
```

The CRV section above it uses a similarly-named image. Nothing on the page states whether the
image is genuinely shared between subsystems.

### Why it matters

Writing the wrong bitstream to the STM DTC is not a harmless mistake. Either the path is a
copy/paste error, or it is correct and needs a sentence saying so — a reader cannot tell which.

### Suggested fix

Confirm with the DAQ expert. If shared, add a note. If not, correct the path.

<!-- mega-review-fingerprint: e40c8a93 -->

---

## 4. `[docs] Seven TODO markers, two of which render on the live operator site`

Labels: `mega-review`, `documentation`

**Severity:** S3 (two instances were S4-visible until fixed in `efc6ab6`)
**Category:** documentation
**Location:** see list
**Found by:** mega-review (`mu2e-sept-mega-review`), 2026-09-30

### What

Unfinished content markers across the shifter site. Two rendered as visible text to operators
and have been converted to HTML comments; the remaining five are already comments but mark real
gaps, two of which are linked to from elsewhere as if they had content.

### Evidence

| Location | Marker | Note |
|---|---|---|
| `experts/runco.md:47` | `for Permission put: TODO!` | **was visible**; now a comment. The actual permission value is still unknown. |
| `experts/daq/flash-firmware.md:104` | `The TODO - add CFO.` | **was visible**; the page already has a `## CFO` section at line 33 |
| `connecting.md:210` | Windows instructions | the `## Windows` section is empty, yet `connecting.md:69` links to it |
| `ots/macros.md:54` | steal-lock flow | `### Stealing the Lock` is empty, yet `ots/README.md:66` sends readers there |
| `experts/runco.md:43` | exact steps | |
| `experts/daq/README.md:10` | bare `<!-- TODO -->` | |
| `experts/daq/cold-start.md:106` | "continue from here" | procedure is incomplete |
| `experts/crv/configure.md:33` | sentence ends mid-clause | "…can be skipped with the " |

### Why it matters

Two pages link readers to sections that contain nothing. A shifter on Windows following
`connecting.md:69` lands on an empty heading.

### Suggested fix

Fill the two linked-to sections (Windows, steal-lock) or remove the links pointing at them.

<!-- mega-review-fingerprint: 91d7be44 -->

---

## 5. `[ci] publish.yml rsyncs without --delete, so deleted pages persist on the live site`

Labels: `mega-review`, `enhancement`

**Severity:** S3
**Category:** enhancement
**Location:** `.github/workflows/publish.yml:30`
**Found by:** mega-review (`mu2e-sept-mega-review`), 2026-09-30

### What

The publish step is `rsync site/ /web/.../htdocs/online/ -vaP` with no `--delete`, so a page
removed from the repo stays served indefinitely.

### Why it matters

Stale operator procedures remain reachable and indexed after being deliberately removed — the
worst kind of documentation defect, because nothing signals it is dead.

### Suggested fix

Not done in this pass on purpose: `/online/` is the site root and it is not known whether anything
else on `mu2e-exp` lives there. `--delete` against a live experiment web root with unknown
co-tenants is the highest-blast-radius change available here.

Inventory the remote directory first. If MkDocs owns it exclusively, add `--delete`. If not,
publish into a subdirectory that MkDocs does own and add `--delete` there.

<!-- mega-review-fingerprint: 5f2c08ab -->

---

## 6. `[crv] ROC access and command set documented twice, inconsistently`

Labels: `mega-review`, `documentation`

**Severity:** S3
**Category:** documentation
**Location:** `shifter/docs/experts/crv/connecting.md:70-83`, `shifter/docs/experts/crv/roc.md:20-44`
**Found by:** mega-review (`mu2e-sept-mega-review`), 2026-09-30

### What

Two pages document the same ROC access procedure and command grammar, and disagree.

### Evidence

- Serial session name: `screen -S ttyUSB1 ...` (`connecting.md:82`) vs `screen -S roc ...` (`roc.md:37`)
- ROC port: telnet **5001** (`roc.md:22,25`; `connecting.md:76`) vs "default port is **5002**" (`firmware.md:42`)
- ROC IP table appears in both, with `connecting.md:94-101` a strict superset of `roc.md:13-16`
- Power-injector credentials and the ssh one-liner are duplicated verbatim between
  `connecting.md:51-64` and `power-injectors.md:13-28`
- `firmware.md:23,44,73` links to `connecting.md#roc-access` for ROC access, while
  `README.md:31` sends readers to `roc.md` for the same thing
- `configure.md:31` says active links are **0 and 3**; `connecting.md:87-90` lists links **0 and 1**

`firmware.md`'s `LC`/`LCA` contradiction was fixed in `efc6ab6`, but the underlying duplication
that produced it remains.

### Why it matters

Any change to a ROC IP, port, or command must be made in two places, and the two have already
drifted. The 5001/5002 discrepancy may be two real sockets (control vs programming), but nothing
says so, so it reads as a contradiction.

### Suggested fix

Make one page canonical for ROC access and have the other link to it. Reconcile the port and
active-link discrepancies with a CRV expert.

<!-- mega-review-fingerprint: c8a33e51 -->

---

## 7. `[docs] mu2edaq-operations/shifter is a stale fork of this repo`

Labels: `mega-review`, `documentation`

**Severity:** S3
**Category:** documentation
**Location:** `Mu2e/daq-operations`, `shifter/` (81 tracked files)
**Found by:** mega-review (`mu2e-sept-mega-review`), 2026-09-30

### What

`mu2edaq-operations/shifter/` contains a complete copy of this repo's 37-page shifter site,
with a byte-identical `mkdocs.yml`.

### Evidence

`diff -rq` between the two trees reports differences in only 7 files, all of them the
`audience:` front-matter normalization this repo made in `3b40dd5`
(`audience: Experts`/`experts` → `expert`). This repo is the newer, canonical copy. No GitHub
workflow builds the `daq-operations` copy.

### Why it matters

Two copies of a live operator procedure, one of which is already behind and is not published.
Anyone editing the wrong one does invisible work.

### Suggested fix

Replace `daq-operations/shifter/` with a short README pointing at `Mu2e/mu2edaq-documentation`.
Filed as its own change against `Mu2e/daq-operations` rather than folded into the doc repo.

<!-- mega-review-fingerprint: a71f3d68 -->
