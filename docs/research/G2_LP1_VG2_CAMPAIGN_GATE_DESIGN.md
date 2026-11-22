# G2-LP1-VG2 — campaign-bound scientific GO: design, state model and threat model

[Issue #62](https://github.com/mfs9697/NewMetacomp/issues/62). Source commit `adbc8a6`, source set `9b634df22d2c44ba9f6465fa9c88f54274afa3a17aa5d43df1e2b2ac58b5c2b5`.

Only the authorization machinery changed. The physics, mesh and SIF functions, 4-mm steps, S0–S4 caps, policy v2, LP0 evidence, source lock and the 20 archived states are unchanged.

## 1. What a GO now authorizes

A GO authorizes **one named campaign**. Its scope is bounded by:

- **Unchanged pins:** source set, policy, LP0 evidence, full token and contract evidence.
- **New GO fields:**
  - `approvedRunName` must match `run_[a-zA-Z0-9_]+` and must not be the historical `run_20261122_lp1_v1`;
  - `campaignId` must match `[A-Za-z0-9_-]{3,64}`;
  - `campaignScope` must be exactly `A0_LP1_S0_S4_REPRODUCTION`.
- **Call binding:** every `Run=true` call must use `RunName == approvedRunName` (`G2LP1:HOLD_CAMPAIGN_SCOPE`).
- **Receipt binding:** the first admitted call writes an immutable **receipt** that binds the campaign ID, run name, the **SHA-256 of the exact GO bytes the gate validated**, and the token. Every later call must match all four (`G2LP1:HOLD_CAMPAIGN_INTEGRITY`).

The GO path stays hard-coded at `matlab/g2/G2_LP1_SCIENTIFIC_GO_v1.json`. The reviewed-resumption record is likewise hard-coded at `matlab/g2/G2_LP1_CAMPAIGN_RESUME_v1.json`. The controller rejects `GoFile`, `ResumeFile` and `CampaignId` arguments (tested).

## 2. Order of checks in `g2_lp1_run` (`Run=true`)

1. Argument parsing and the S0–S4 cap (unchanged).
2. Context and preflight (unchanged): clean LF tree, R2023a/PDE, one engine, ≥ 5 GiB.
3. `goRec = g2_lp1_scientific_gate(C)`: hard-coded GO, all VG1 checks, plus the three campaign fields. Returns `goFileSHA256`.
4. Token equality (unchanged).
5. **Campaign decision** (`g2_lp1_campaign_validate`, pure), from read-only facts: the ledger snapshot, the run-folder facts and the optional resume record. It runs **before any run-root folder, ledger entry, mesh, state or solve**; this ordering is statically tested.
6. In `VERIFY_ONLY` mode, every requested state must already have a `STATE.mat`; otherwise `HOLD_CAMPAIGN_CLOSED`, before any write.
7. Existing staging checks (unchanged): H S0–S2 first; all four S2 before any S3.
8. Only then: the receipt (OPEN_NEW only), resume consumption (if reviewed), then the run folder and `RUN.mat`.
9. Per new state: integrity check → 5-GiB guard → **campaign hook** → `mkdir`. The hook refuses in `VERIFY_ONLY` and writes the immutable `ADMIT_<case>_S<k>` entry.
10. After a call that reaches S4: if all four S4 states exist, write `CLOSED` (with their SHA-256).

## 3. Campaign states and transitions

```
                 first authorized call, no receipt, no run folder
   NOT_OPENED ───────────────────────────────────────────────► OPEN
       │  (run folder or ledger entries without receipt → HOLD_CAMPAIGN_INTEGRITY)
       │
 OPEN ──staged calls (H prefix, candidate prefixes, S3/S4)──► OPEN
 OPEN ──pre-admission HOLD_MEMORY──► OPEN_HOLD_REVIEW ──reviewed RESUME record (≤ 1)──► OPEN
 OPEN ──all four S4 STATE present──► CLOSED (VERIFY_ONLY: zero-solve reuse calls only)
 any ──receipt/ledger tamper, other GO, deleted run folder──► HOLD_CAMPAIGN_INTEGRITY (stop; review)
 any ──RunName ≠ approvedRunName──► HOLD_CAMPAIGN_SCOPE (refused before any write)
```

| Current state (ledger + run folder) | Call | Decision | Writes |
|---|---|---|---|
| no receipt, no run folder, no entries | authorized, approved run | `OPEN_NEW` | RECEIPT, then run folder, RUN.mat, ADMIT per new state |
| no receipt, run folder exists | any | `HOLD_CAMPAIGN_INTEGRITY` (adopting a foreign run) | none |
| no receipt, ledger entries exist | any | `HOLD_CAMPAIGN_INTEGRITY` | none |
| receipt bound to (campaign, run, GO SHA, token) | same campaign, approved run | `CONTINUE` | ADMIT per new state only |
| receipt, run folder absent, no ADMIT | same | `CONTINUE` (interrupted opening, no physics) | run folder, RUN.mat |
| receipt, run folder absent, ADMIT entries | any | `HOLD_CAMPAIGN_INTEGRITY` (deleted run) | none |
| receipt, `ADMIT_<case>_S<k>` exists but its state folder is missing | the state | `HOLD_CAMPAIGN_INTEGRITY` (deleted or interrupted admission → review) | none |
| receipt bound to another GO SHA / campaign / run / token | any | `HOLD_CAMPAIGN_INTEGRITY` | none |
| RUN.mat token ≠ campaign token | any | `HOLD_CAMPAIGN_INTEGRITY` | none |
| one unreviewed pre-admission HOLD, no resume record | any | `HOLD_CAMPAIGN_REVIEW_REQUIRED` | none |
| one unreviewed HOLD + valid resume record (decision, campaign, hold SHA, reviewer, URL), no prior resumption | same | `CONTINUE` | RESUME entry, then normal |
| a second pre-admission HOLD after one resumption | any | `HOLD_CAMPAIGN_REVIEW_REQUIRED` (allowance exhausted) | none |
| CLOSED | any call whose states all exist | `VERIFY_ONLY` (reuse path re-audits, zero solves) | none |
| CLOSED | any call needing a new state | `HOLD_CAMPAIGN_CLOSED` | none |
| any | RunName ≠ approved (including the historical run or a second campaign) | `HOLD_CAMPAIGN_SCOPE` | none |

**Pre-admission memory refusal.** The 5-GiB check fails before the state folder exists. It writes:
- the VG1 chain record `PREADMISSION_HOLD_MEMORY_S<k>_*` beside the chain;
- a ledger `HOLD_PREADMISSION_MEMORY_*` entry.

No physical stop is fabricated and the chain is not blocked. **Resumption is never automatic.** It requires a committed, reviewed `G2_LP1_CAMPAIGN_RESUME_v1.json` naming the hold record's SHA-256, and at most one resumption per campaign is allowed.

## 4. Verification after closure

| Kind | What it is | Authorization |
|---|---|---|
| Controller zero-solve reuse (`VERIFY_ONLY`) | Re-invokes `g2_lp1_run` with `MaxStateIndex=4`. The reuse path re-reads records and re-audits meshes, phases, links and clearance; `computed=0`. | Needs the GO still present; cannot create a state |
| Independent read-only audit | `scripts/g2/a0/a0_compare_records.m` (tiers A–D) and the SR1-style recomputation | Needs no GO; plain `load` only |

## 5. Threat model and residual risk (stated candidly)

| Threat | Mitigation | Residual |
|---|---|---|
| GO reused for another run name or campaign | `approvedRunName` binding at every call | none in a given checkout |
| Restarting a finished campaign under the same run name | `CLOSED` → `VERIFY_ONLY` | needs local ledger present |
| Deleting the run folder and recomputing | ADMIT entries plus receipt → `HOLD_CAMPAIGN_INTEGRITY` | needs local ledger present |
| Deleting the ledger, keeping the run | run folder without receipt → HOLD | — |
| Editing the GO after opening | receipt binds the GO SHA → HOLD | — |
| Editing or forging ledger entries | SHA manifests verified on every snapshot; kind, name and campaign checks | a forger who regenerates consistent MAT + manifest pairs is not detected (no secret key) |
| **Deleting both ledger and run folder, or running from an independent clone** | **not detectable locally** | **residual**: no cryptographic or GitHub-global single-use. Mitigate procedurally: keep the GO only in the reviewed commit, remove or revoke it right after verified closure, and archive the ledger with the campaign evidence. |
| Unreviewed automatic resumption after a memory dip | review-bound resume record, ≤ 1 | — |

**Durable global single use would need external state**, such as a signed GitHub status or a server-side nonce, and is not implemented. The bounded alternative is implemented: a local immutable ledger plus GO removal after closure. This does not change the security assumptions of VG1; it adds local campaign binding.
