# Development smoke runs (disclosed, not evidence of GO)

Run after the preregistration (`bd03584`) and the implementation commit (`59cc80c`), before the formal batch. No contrast case (Msoft or Mstiff) was solved here. The preregistered gates were not changed afterwards.

| Run | Content | Outcome |
|---|---|---|
| `MAT_smoke1` | State 2 phase map, verifier and 8 negatives; exact-field self-check; benchmark at Hmax 4.8 and 2.4 only (a reduced, non-preregistered level set) | Phase map valid, 8/8 negatives rejected. At these coarse levels the displacement error converged at order about 1, which led to `smoke2`. |
| `MAT_smoke2` | Diagnostic of that order: ratios 1 and 2, Hmax 4.8 to 0.6, with and without exact Dirichlet data on the hole | See below. |
| `MAT_smoke3` | Material SIF pipeline at ratio 1 (M0 crash test) and the q-phase negative | All 14 gates pass and the recorded State 2 K is reproduced; the negative is rejected. |

**What `smoke2` showed:**
- The maximum error sits on the midside nodes of the traction-free hole chords.
- The coarse levels barely add hole chords (12 to 16), which is why the order looked like 1.
- On the 1.2 to 0.6 mm pair the order is about 2.3.
- Imposing the exact displacement on the hole cuts the error by 10 to 35 times.
- Ratios 1 and 2 behave alike.

So the dominant error comes from the polygonal hole geometry, not from the phase assembly.

**Change made after `smoke1`:** the batch's SIF-level q-phase negative uses an all-matrix map plus the one q element. This keeps any near-contrast K out of the log before the M0 identity test.
