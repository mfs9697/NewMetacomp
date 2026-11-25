# LP2-A3 campaign G2-LP2A3-001 — evidence

- **Authorization:** https://github.com/mfs9697/NewMetacomp/pull/75#issuecomment-7175877170
- **Readiness review:** https://github.com/mfs9697/NewMetacomp/pull/75#pullrequestreview-6065556000
- **Approved head:** `2348ba1`
- **GO commit:** `3097929`, GO file only
- **Revocation commit:** `db9d230`, tree identical to `2348ba1`
- **Memorandum (Ukrainian):** [`../../G2_LP2A3_DEMONSTRATION_MEMO_UA.md`](../../G2_LP2A3_DEMONSTRATION_MEMO_UA.md)

## Outcome

- 1 entry-point call and 4 case calls, finishing as `CAMPAIGN_CLOSED_VERIFIED`.
- Ledger: 11 admissions.
- 10 physical solves, all completed and accepted.

| Case | Accepted states | Terminal |
|---|---|---|
| H | S9–S11 | `CAMPAIGN_LIMIT_REACHED` |
| stiff13 | S9–S11 | `CAMPAIGN_LIMIT_REACHED` |
| soft2 | S9–S11 | `CAMPAIGN_LIMIT_REACHED` |
| soft1 | S9 | S10 `NUMERICAL_HOLD` |

The soft1 S10 stop was a default-rung mesh failure, `globalNeighborRatioAtMost1p8`. It happened before any solve, and there was no fallback and no retry.

## Records

The campaign records themselves are not in git:
- `outputs/g2_lp2a3_paths_v1/run_lp2a3_s9_s11_v1`: 83 files;
- `outputs/g2_lp2a3_campaign_ledger/G2-LP2A3-001`: 26 files.

They are kept in archive `NewMetacomp_G2_LP2A3_Records_20261126.zip`:
- SHA-256 `e089d749737f6c5259e6ad391c785b6ac222a636ca4716aaefbbde2fd5186dc6`;
- 135 members;
- copies on the internal SSD and on the removable USB drive (volume 8E4B6EC7), both verified member by member.

## Notes on the evidence

- **Paths:** local paths are sanitized (`SANITIZATION.json` in each folder).
- **Logs:** UTF-16 launcher logs were converted to UTF-8 before sanitization. The originals are in the archive.

## Folder contents

| Folder | Content |
|---|---|
| `pre/` | Python hashcheck 18/18 and the 723 protected files plus manifest (`44c54678…`); pre-start record (8.615 GiB, D: present); MATLAB activation checks (R2023a, PDE 3.10, 1 process, 7.835 GiB, correct-token refusal, no writes) |
| `campaign/` | Pre-start record before the campaign (8.666 GiB); entry-point pre-check; controller summary `LP2A3_CAMPAIGN.json`; copy of the committed GO (`3097929`) |
| `post/` | Post-revocation refusals (4/4, run and ledger unchanged); closure hashcheck (only the run-root and ledger-root absent flags are false, as expected after the campaign); 723 protected files; archive record |
| `verify/` | Controller verification; full read-only record dump; independent audit (0 problems); scientific analysis (`LP2A3_ANALYSIS.json`) |
| `figures/` | LP2A3-2 trajectories; LP2A3-3 G and F_G; LP2A3-4 angles, heading and offsets; LP2A3-5 ring-1 proximity and terminals. PNG 300 dpi and vector PDF |
| `logs/` | Launch gate, activation checks, campaign call, closure, GO generator and figure scripts, with their logs |

The first run of the independent audit reported 35 problems. All came from two bugs in the audit script: alphabetical folder order, and SHA letter case in the dump. The fix is in `lp2a3_audit.py`; the rerun shows 0 problems. The output of the first run was overwritten and is not preserved.
