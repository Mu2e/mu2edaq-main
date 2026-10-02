# Mega-review status — 2026-09-30

Branch: `mu2e-sept-mega-review` (superproject, all 45 package repos, `mu2edaq-documentation`).

## Done

### Wave 0 — setup
- Branch created in the superproject, all 45 package repos, and `mu2edaq-documentation`
  (branched from `docs/index-audience-cleanup`, preserving the `audience:` normalization
  that makes that copy canonical relative to the `daq-operations` fork).
- `.venv-docs/` with mkdocs 1.6.1 + mkdocs-material 9.7.7 + pymdown-extensions 12.1.
  There was no mkdocs on this machine, so no build claim was verifiable before this.
- `docs/mega-review/CONTRACT.md` — manifest schema, man-page section conventions,
  severity rubric, issue template and fingerprint/dedup protocol, Tier B read prohibition.
- `docs/mega-review/QUARANTINE.md` — pre-existing dirty state, recorded not absorbed.

### Wave 1 (partial) — shifter documentation
Commit `efc6ab6` in `mu2edaq-documentation`. Site builds clean under
`mkdocs build --strict` with anchor validation on; 37 pages.

- 6 broken links/anchors/images fixed (all strict-mode failures)
- 1 live operator bug fixed: `connecting.md` bound local port 3025 twice, so the HWDev
  tunnel never opened
- 3 contradictions flagged, not guessed (OTS host, calo node range, STM/CRV bitstream)
- `background/` (3 pages) wired into nav and the index; glossary and hardware written
- 2 operator-visible TODOs removed; 6 STM pages given an H1; drifted titles corrected
- 10 pseudo-admonitions converted; `!!! important` (not a Material type) → `warning`
- vestigial `order:` key removed; whitespace, newlines, image case and modes normalized
- `check-docs.yml` (strict build on PRs) + `validation.links.anchors: warn` — the control
  whose absence let all of the above reach production
- `publish.yml`: `--strict`, pinned requirements, accurate job id

## Blocked

Three actions were denied by the session permission policy:

1. **Subagent launches** — blocks Waves 1–4 (~50 agents). This is the main blocker.
2. **`gh issue create`** — 7 issues for `mu2edaq-documentation` are staged verbatim in
   `ISSUES-PENDING-documentation.md`, fingerprints included, ready to file unchanged.
3. **`git stash`** of `mu2edaq-power-recovery/requirements.txt` — someone else's
   regenerated lockfile, left in place; it will appear in that submodule's diff.

## Not started

Waves 1 (44 remaining packages), 2, 3, 4: per-package review, manifests, docs and man
pages; cross-cutting findings; the `daq-expert` and `daq-expert-markdown` corpora; the
`PROJECT-STATUS.html` artifact.

## Findings that changed the plan

- **`mu2edaq-kerberos-standards` is a git worktree of `mu2edaq-kerberos`**, not a
  duplicate clone (`.git` is a gitdir pointer). One package, not two. It caused a real
  collision: the branch could not be created in `kerberos` because the worktree held the
  name. Resolved by returning the worktree to `feature/standards-cleanup`.
- **The "committed artifacts / secret exposure" findings were wrong** — on-disk vs tracked
  confusion. `git ls-files` returns 0 matches for all six named packages. What is real:
  `mu2edaq-config` tracks a genuine EC P-256 APNs key in three snapshot directories, but
  that repo is **private**, so it is contained rather than exposed; the source package
  gitignores it correctly. `mu2edaq-fts` has a removed `venv/` still in history (S4).
- **mkdocs 1.6 validates anchors** at INFO level; `validation.links.anchors: warn` promotes
  them under `--strict`, replacing the custom anchor-checking script the plan called for.
- **The power-injectors anchor conclusion was backwards.** The rendered id is
  `enabling-disabling-powercyling-ports` (single hyphen), so `debugging.md` was correct and
  the two pages the audit called correct were the broken ones.
- **An unrelated `diagrams/` tree appeared** in `mu2edaq-documentation` at 13:55 during this
  session — 240+ files of generated Mermaid/SVG package diagrams, not created by this work.
  Left untracked and uncommitted. It overlaps substantially with the planned
  `daq-expert-markdown` corpus and should be reconciled before Wave 3.
