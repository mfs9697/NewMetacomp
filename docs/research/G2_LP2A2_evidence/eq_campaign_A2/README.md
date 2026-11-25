# LP2-A2 SIF-equivalence campaign G2-LP2A2-EQ-001, activation A2

- **Authorization:** https://github.com/mfs9697/NewMetacomp/pull/71#issuecomment-7171931196
- **Readiness review:** https://github.com/mfs9697/NewMetacomp/pull/71#pullrequestreview-6063423416
- **Approved head:** `a4561f8`
- **GO commit:** `820efd4` (GO file only)
- **Revocation commit:** `886c230` (tree identical to `a4561f8`)
- **Memorandum (Ukrainian):** [`../../G2_LP2A2_EQ_A2_DEMONSTRATION_MEMO_UA.md`](../../G2_LP2A2_EQ_A2_DEMONSTRATION_MEMO_UA.md)

**Outcome.** The wrapper reported `EQUIVALENT`:
- 1 entry-point call, 1 wrapper call;
- 4 driver attempts, 4 completed solves, 4/4 passing comparisons;
- contrast passed.

The independent audit confirmed it (`EQUIVALENT_CONFIRMED`). The read-only replay `g2_lp2a2_eq_verify` returned `VERIFY_HOLD`. The cause is a defect in that tool: an empty `cell` compared with an empty `double` from `jsondecode`. Its own recomputation agrees exactly with the stored records; see `verify/LP2A2_EQ_A2_REPLAY_DIAGNOSTIC.json`.

The activation-A1 evidence in `../eq_campaign/` and its HOLD archive are unchanged. Campaign records (`outputs/g2_lp2a2_eq_v1/`, 24 files) are not in git. They are in the archive `NewMetacomp_G2_LP2A2_EQ_A2_Records_20261125.zip` (`96ed7a36…`, 62 members), kept on the internal SSD and on the removable USB drive.

Absolute local paths are sanitized; see `SANITIZATION.json` in each folder. The activation-check and campaign logs were written as UTF-16LE by the launcher. They were converted to UTF-8 before sanitization; the originals are in the archive.

| Folder | Content |
|---|---|
| `pre/` | Python hashcheck 13/13 and the 699 protected files before activation; pre-start check before the GO-absent MATLAB checks (8.201 GiB); MATLAB activation checks (R2023a, PDE 3.10, 1 process, 7.630 GiB after context, correct-token refusal `HOLD_UNAUTHORIZED`, no writes) |
| `campaign/` | Pre-start check before the campaign (8.389 GiB); entry-point dry check (parent and changed file, context, token, GO validation, memory gate); wrapper result `LP2A2_EQ_A2_CAMPAIGN.json`; copy of the committed GO (`820efd4`) |
| `post/` | Post-revocation refusals: 4/4 driver, wrapper 0 solves, 24 record files unchanged. Hashcheck and protected check after revocation; archive record (both copies verified) |
| `verify/` | Record dump for the audit; replay diagnostic; independent audit (final, and run 1, which failed on manifest hex case and is kept as history) |
| `opening/` | Crack-face jump profiles, new family vs archived (interpolated), per solve |
| `figures/` | LP2A2-EQ-1 (tolerance use), LP2A2-EQ-2 (opening difference); PNG 300 dpi and vector PDF |
| `scripts_logs/` | All scripts and logs of this activation: activation checks, single campaign call, closure (post-revocation + replay + dump), replay diagnostic, opening export and figures, GO generator, pre-start wait loops |
