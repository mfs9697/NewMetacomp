# LP2-A2 equivalence campaign G2-LP2A2-EQ-001: HOLD before the first call (PR #71)

Report (Ukrainian): [`../../G2_LP2A2_EQ_DEMONSTRATION_REPORT_UA.md`](../../G2_LP2A2_EQ_DEMONSTRATION_REPORT_UA.md).

**Status `HOLD_LP2A2_EQ_ACTIVATION_BINDING_WINDOWS_CARET`.** The campaign was authorized in PR #71 comment 7167996437 at the approved head `4d3701e1ccc91b7512db9052c927f32af52e2479`. The GO was committed alone on that head (`91667cf`) and revoked in a separate commit (`91718b0`). The wrapper `g2_lp2a2_eq_campaign` was **never called**: 0 attempts, 0 physical solves, no `outputs/g2_lp2a2_eq_v1` folder, no accepted state. Equivalence is neither established nor refuted; no C1-C11 values exist, so no comparison table and no figures were produced.

**Cause.** `g2_lp2a2_eq_go_validate.m` (line 54) runs `git rev-parse HEAD^` unquoted through MATLAB `system()`. On Windows `cmd.exe` consumes the trailing `^`, git returns `HEAD` itself, and the check `activationBinding` (parent of HEAD equals the approved head) is false for every valid activation commit. The 64 contract tests inject the git queries, so the real path was never executed. With the parent resolved via `"HEAD^"` or `HEAD~1` the same pure validator passes (diagnostic only, never used for activation). No source, policy, tolerance or pin was changed and no workaround was applied.

| File | Content |
|---|---|
| `LP2A2_EQ_HASHCHECK_PRE.json`, `_RECHECK.json`, `_POSTGO.json`, `_CLOSURE.json` | Independent Python recomputation (`scripts/g2/lp2a2/lp2a2_eq_hashcheck.py`): pins, token, evidence SHA, 20 archived hashes. Only `noGoFile` is false after the activation commit, as designed (`pass` is therefore false there) |
| `LP2A2_EQ_PROTECTED_PRE.json`, `_RECHECK.json`, `_POSTGO.json`, `_CLOSURE.json` | 541 protected files (tree `20f2d54f...`) + 158 LP2-A1 run/ledger files = 699, unchanged (`scripts/g2/lp2a2/lp2a2_eq_protected.py`) |
| `lp2a2_eq_activation_checks.m`, `.log`, `_wait1.log`, `LP2A2_EQ_ACTIVATION_CHECKS.json` | MATLAB pre-activation checks (GO absent). Attempt 1 (`_wait1`): 7.010 GiB after the context, below the 7.3 GiB activation margin, stopped. Attempt 2: 7.468 GiB, one engine, R2023a/PDE, token equal, correct-token `Run=true` refused (`G2LP2A2:HOLD_UNAUTHORIZED`), wrapper `HOLD_UNAUTHORIZED` with 0 solves, no writes |
| `make_go.py` | Generator of the GO file (exact v2 template fields, LF) |
| `lp2a2_eq_campaign_run.m`, `.log`, `LP2A2_EQ_CAMPAIGN.json` | Launch script. It stopped on its own check that the parent of HEAD equals the approved head (outcome `NOT_CALLED`), before any wrapper or driver call |
| `lp2a2_eq_go_dryvalidate.m`, `.log`, `LP2A2_EQ_GO_DRYVALIDATE.json` | Dry validation of the committed GO (pure validator, no solve): default git `pass = 0`, `failed = [activationBinding]`; git outputs for `HEAD^`, `"HEAD^"`, `HEAD~1`; replay `NO_RECORDS` |
| `LP2A2_EQ_ARCHIVE_RECORD.json` | Archive `4f60ddfd...` (22 members, 20 635 bytes) verified on the local backup folder and on the removable USB drive D:. Builder: `scripts/g2/lp2a2/lp2a2_eq_archive.py` |
| `lp2a2_eq_post_revocation.m`, `.log`, `LP2A2_EQ_POST_REVOCATION.json` | After revocation: correct-token `Run=true` for all four IDs and the wrapper refused (`HOLD_UNAUTHORIZED`, 0 solves), no write |
| `prepared_not_exercised/` | Record audit tools prepared for the campaign and never run on data (no records exist): read-only dump of stored records (`lp2a2_eq_audit_dump.m`) and an independent Python audit (`lp2a2_eq_audit.py`). Untested; to be validated before use |

Absolute local paths are sanitized (`SANITIZATION.json`); MATLAB startup path warnings are removed. Commits: GO `91667cf` (only `matlab/g2/lp2a2/G2_LP2A2_EQ_GO.json`, parent `4d3701e`), revocation `91718b0` (only its deletion; tree identical to `4d3701e`).
