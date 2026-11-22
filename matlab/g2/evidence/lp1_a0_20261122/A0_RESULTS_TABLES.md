# A0 campaign G2-LP1-A0-001: per-state comparison and campaign record

Sources: `audit/A0_COMPARISON.json` (preregistered tiers A–D, `scripts/g2/a0/a0_compare_records.m`), `audit/A0_INDEPENDENT_CROSSCHECK.json` (independent field-by-field check against the committed SR1 historical extract) and the campaign logs. All differences are new minus historical.

## 1. Eight controller calls

| # | Case | MaxStateIndex | Status | computed | reused | promoted | Mode | Closed | RAM before, GiB | s |
|---:|---|---:|---|---:|---:|---:|---|:---:|---:|---:|
| 1 | H | 2 | BOUNDED_PREFIX_COMPLETE | 3 | 0 | 0 | OPEN_NEW | no | 8.264 | 32.9 |
| 2 | stiff13 | 2 | BOUNDED_PREFIX_COMPLETE | 3 | 0 | 0 | CONTINUE | no | 8.079 | 24.2 |
| 3 | soft2 | 2 | BOUNDED_PREFIX_COMPLETE | 3 | 0 | 0 | CONTINUE | no | 8.055 | 24.1 |
| 4 | soft1 | 2 | BOUNDED_PREFIX_COMPLETE | 3 | 0 | 0 | CONTINUE | no | 7.965 | 23.1 |
| 5 | H | 4 | CASE_S4_COMPLETE_AWAIT_CAMPAIGN_REVIEW | 2 | 3 | 0 | CONTINUE | no | 7.987 | 28.3 |
| 6 | stiff13 | 4 | CASE_S4_COMPLETE_AWAIT_CAMPAIGN_REVIEW | 2 | 3 | 0 | CONTINUE | no | 7.975 | 27.7 |
| 7 | soft2 | 4 | CASE_S4_COMPLETE_AWAIT_CAMPAIGN_REVIEW | 2 | 3 | 0 | CONTINUE | no | 7.971 | 27.4 |
| 8 | soft1 | 4 | CASE_S4_COMPLETE_AWAIT_CAMPAIGN_REVIEW | 2 | 3 | 0 | CONTINUE | yes | 7.997 | 27.5 |

Total new solves: 20.

## 2. Per-state comparison (20 states)

| State | Tier | Integer arrays equal | max\|Δx\|, mm | ΔK/K_ref | \|ΔG\|/G | \|Δθ\|, ° | EDI | COD | J | u | compliance | clearances, mm | all saved fields (independent) | T3 hist/new | K_I new, N·mm⁻³ᐟ² at 1 N | K_II new | G new, N/mm at 1 N | θ new, ° |
|---|:---:|:---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:---:|---|---:|---:|---:|---:|
| H_S0 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28151/28151 | 0.00526316463825 | +0.000595364825636 | 8.584569786e-09 | -12.5957584902 |
| H_S1 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28437/28437 | 0.00577384089842 | +4.78623139998e-05 | 1.020145543e-08 | -0.9497556569 |
| H_S2 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28631/28631 | 0.00619750668217 | +9.96110467673e-05 | 1.175570977e-08 | -1.8406938504 |
| H_S3 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28815/28815 | 0.00663576338031 | +0.000100030936328 | 1.347668666e-08 | -1.7264975345 |
| H_S4 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 29063/29063 | 0.00709117586262 | +0.000100903254567 | 1.538959204e-08 | -1.6298006977 |
| stiff13_S0 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28151/28151 | 0.00515493008981 | +0.000615744269508 | 8.24709205e-09 | -13.2584434704 |
| stiff13_S1 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28421/28421 | 0.00564249445396 | +4.93575376123e-05 | 9.742674242e-09 | -1.0022070451 |
| stiff13_S2 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28647/28647 | 0.00602952715707 | +9.60437177363e-05 | 1.11270326e-08 | -1.8242376973 |
| stiff13_S3 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28799/28799 | 0.00642538613168 | +9.47483508151e-05 | 1.263559091e-08 | -1.6889036057 |
| stiff13_S4 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 29047/29047 | 0.00683217712954 | +9.25727675612e-05 | 1.42856705e-08 | -1.5519968180 |
| soft2_S0 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28151/28151 | 0.00514852189175 | +0.000594322519969 | 8.218957083e-09 | -12.8390363942 |
| soft2_S1 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28457/28457 | 0.00566066272547 | +4.89385690911e-05 | 9.805498728e-09 | -0.9905146266 |
| soft2_S2 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28595/28595 | 0.00608562358424 | +0.000100098604175 | 1.133522968e-08 | -1.8836561977 |
| soft2_S3 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28823/28823 | 0.00652668480534 | +0.000100662915265 | 1.303740767e-08 | -1.7663982319 |
| soft2_S4 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 29005/29005 | 0.00698642118457 | +0.000101588942343 | 1.49383976e-08 | -1.6654445829 |
| soft1_S0 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28151/28151 | 0.00534076449229 | +0.000549496292084 | 8.820286782e-09 | -11.5115523405 |
| soft1_S1 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28399/28399 | 0.00586762419742 | +4.65986380964e-05 | 1.053548763e-08 | -0.9099125647 |
| soft1_S2 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28601/28601 | 0.00632750138335 | +0.000102472584961 | 1.225408971e-08 | -1.8546523772 |
| soft1_S3 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 28813/28813 | 0.00680796006555 | +0.000105118968042 | 1.418535463e-08 | -1.7683788249 |
| soft1_S4 | **A** | yes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | bitwise | 29035/29035 | 0.00731204850204 | +0.00010972211889 | 1.636358948e-08 | -1.7186195122 |

**Verdict: `A0_REPRODUCED_EXACT`** (worst tier A); S4 classifications unchanged: True; max|ΔF_G| = 0; max|Δd| = 0 mm.

## 3. S4 classifications (SR1 rules) — historical = new

| Case | F_G, % | U_primary | U_cons | primary | conservative | d, mm | U_d,cons, mm | offset (cautious) |
|---|---:|---:|---:|:---:|:---:|---:|---:|:---:|
| stiff13 | -7.173170 | 1.00e-05 | 0.032494 | resolved | resolved | -0.190902 | 0.043435 | resolved |
| soft2 | -2.931815 | 1.00e-05 | 0.033975 | resolved | **unresolved** | -0.085163 | 0.043281 | **unresolved** |
| soft1 | +6.328936 | 1.00e-05 | 0.037210 | resolved | resolved | +0.305671 | 0.041864 | resolved |

## 4. Provenance (new records)

| State | source set = 9b634df2…, policy, parent chain, file-hash links | STATE.mat SHA-256 |
|---|:---:|---|
| H_S0 | OK | `d1a42856be6b6f2c26dff21a103216fcb3bbf1cf1320fa18ce18d2479dc5cf68` |
| H_S1 | OK | `883f1a390c609d2ad1d8a0a60227bc55cb8e6625060359c0dbad2537475e2c1e` |
| H_S2 | OK | `2146d1602c1872660aedbea8daa29425f111cfc79c34590e298ae011af31a2fd` |
| H_S3 | OK | `37b5a38068169c3ea58f39673626696caf3392a8d856a31a5d6fa4f77cfd2fa3` |
| H_S4 | OK | `3e13276c751aa71ea7a39ce0b40de291fa00b241bfd4caa5407992f3d95262db` |
| stiff13_S0 | OK | `5c36971918639d331cb05d97160d27978fa610a36995c0782984b8f1059f1aba` |
| stiff13_S1 | OK | `6ac14e5c2ed1421651b49aa676df4beba7df51ee4d69f18ca086cd9894eee220` |
| stiff13_S2 | OK | `d31f5c23421f8b4362d5483e66632a21e146c7e9ba442b442bec2e541dd4c8a8` |
| stiff13_S3 | OK | `fa4a307885b4cd8f2d57f4ca5e5e6431328ba10f4bf6702fe1d0b967d191a9a0` |
| stiff13_S4 | OK | `2e88c6f43212048ce48ad9969a426a250b6ea031169829b9e32dd076a30965cb` |
| soft2_S0 | OK | `6e9e00096c0148883402d1fcc6a2ec96d9e54bd812191d2d7f15e0dcd5d06443` |
| soft2_S1 | OK | `8014d47abd2b1e26a60cfaa1d30ab434f777060af602deca088db20b249d77c9` |
| soft2_S2 | OK | `cc5b01eb78e8c106c807234619efa4bf9151d4a7c73c1fbf56e0d4aa224483d2` |
| soft2_S3 | OK | `db521ee00557a3a85432fd150221c32afc9b02e148ed79fa69716a45c1f78f09` |
| soft2_S4 | OK | `fd4a25727617f000507e6490349367aceaea990bc808974c83963aa15c1287f9` |
| soft1_S0 | OK | `2bb181f4cabf18ec357e6c2f273492269347ebf8bc5eb0d7a78a4e0df6a72eac` |
| soft1_S1 | OK | `71867d831d10017c4f7c22922443829b59a83a744d34d6fc11d7e5d39088cf9f` |
| soft1_S2 | OK | `024f030fe56d209b8c9761c74c16748f2f4f124e3d5126efaa323460749a6a9c` |
| soft1_S3 | OK | `b75106ab0cfbc8ac304b6ff608386c53c642d1fa7a90b748aa3383595d99c1e9` |
| soft1_S4 | OK | `cecb046ceac2f5d617deae0d5d0f6b2462b86982600af3493b6383cd307a95d7` |

## 5. Campaign ledger `outputs/g2_lp1_campaign_ledger/G2-LP1-A0-001/`

| Entry | SHA-256 |
|---|---|
| `ADMIT_H_S0.mat` | `60b7012d12ccb241e1aeca9b1cad5adffddf1c6fb1b2e7dcc09ed0393e939f81` |
| `ADMIT_H_S1.mat` | `96e1db1d4bcc35db4199c2fdbb48ee2587e09274937e7b7938f96312073a30de` |
| `ADMIT_H_S2.mat` | `33d596ac8fc0eff7b4a2a98edd95064c45ffdbb9ed4f35020432116a3ccdd85a` |
| `ADMIT_H_S3.mat` | `f04f583f5e9df958413ce35c01fb51b50b5ec2bb95f458c30429c07528c9613c` |
| `ADMIT_H_S4.mat` | `0749992ebc540fe75914938cbd7e5ff66b5d09b3be0957ff47a4e9dd904c9bf5` |
| `ADMIT_soft1_S0.mat` | `8009b63c13d4122088046cf57f877e74170fad31aea72b3f65553d2d82f2340d` |
| `ADMIT_soft1_S1.mat` | `75bb35b1af36d684c8bf2707deb7491a59c2762e008778085aa0397d4c654fba` |
| `ADMIT_soft1_S2.mat` | `5f6ba5ad2b55e30d165600b5f82204789dcd3e5f370350bd99729f9e3903d4e4` |
| `ADMIT_soft1_S3.mat` | `a6d298658752f01dcab817aa833a16dc845aaeb2a338533fac26a647015e5afa` |
| `ADMIT_soft1_S4.mat` | `e74153025493c4a720f54079072fbd4568998d4fd59a09a3703fe5ebb85834ef` |
| `ADMIT_soft2_S0.mat` | `f9e554c13e06ebb0583ef39b1e44768ae27dcc78e6c9e00dff3660372043d45e` |
| `ADMIT_soft2_S1.mat` | `3938d71fca501e898a341c405af4d507329d3e4ad3dbc8f105bcd67a684995ce` |
| `ADMIT_soft2_S2.mat` | `5e5201c9598987d911f3b5e80a73c12e2f945e89b7cf66219b66f271dfff0949` |
| `ADMIT_soft2_S3.mat` | `f69c6152bb8b0f05ba45ed4e7b7479f314f3a9582823bc87c9496612ccce75b4` |
| `ADMIT_soft2_S4.mat` | `b72a3e1e797ab870624a2442556dbfde9c50b189d65936d9083f0af0c38d7a81` |
| `ADMIT_stiff13_S0.mat` | `45aced7af510c30c05fd385e775a566c8cb799445ad8fc8fa04ad317ffc51943` |
| `ADMIT_stiff13_S1.mat` | `0d3b6937065480c00213cc5788f2ed94009deb3bde73afeac16fbd0ee920013d` |
| `ADMIT_stiff13_S2.mat` | `39c6ccf7928f5126b3f7585df2ebfc24bafa43aef3419d699a3183e092284b9e` |
| `ADMIT_stiff13_S3.mat` | `7eb896116b09f477ca8c904d6e2943a09df84ebcf326f04b7b9ba1b3a85cfa36` |
| `ADMIT_stiff13_S4.mat` | `3ccbe8b438b8f4094b9292ec1aa3a5da3a91a88e424c5c5953b084b86557581a` |
| `CLOSED.mat` | `37d8d416475ca203521b7f47753dec80a0dece27bc2a3dce89ed584341372f0f` |
| `RECEIPT.mat` | `9fd3050b3f07b82ab84f4d59e96d497011ccfffeeb7dcb84a0001c4793472665` |

Independent check: expected set (RECEIPT + 20 ADMIT + CLOSED) True, manifests True, manifest hashes True.

## 6. Post-closure VERIFY_ONLY

| Case | Status | computed | reused | promoted | Mode |
|---|---|---:|---:|---:|---|
| H | CASE_S4_COMPLETE_AWAIT_CAMPAIGN_REVIEW | 0 | 5 | 0 | VERIFY_ONLY |
| stiff13 | CASE_S4_COMPLETE_AWAIT_CAMPAIGN_REVIEW | 0 | 5 | 0 | VERIFY_ONLY |
| soft2 | CASE_S4_COMPLETE_AWAIT_CAMPAIGN_REVIEW | 0 | 5 | 0 | VERIFY_ONLY |
| soft1 | CASE_S4_COMPLETE_AWAIT_CAMPAIGN_REVIEW | 0 | 5 | 0 | VERIFY_ONLY |

Bytes of all 226 run and ledger files unchanged: True; pass: True.
