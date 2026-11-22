# Preflight investigation before any geometry retry

The first algebra/preflight run at local commit
`8a19166528aad9be3d41f32bbfe3516719d436a6` passed 23/23 algebra tests, with
no mesh or FEM. Free RAM was 5.8133 GiB, but `GetProcessesByName('MATLAB')`
counted two executables. The earlier environment-only probe had reported
2.9940 GiB. No application was terminated to free resources.

Potential implementation defect: Windows starts the engine through
`<matlabroot>/bin/matlab.exe`, which has the same process name as
`<matlabroot>/bin/win64/MATLAB.exe`. Counting names alone cannot distinguish
the launcher from a second engine. The new preflight records PID and executable
path, excludes only the exact installed launcher path, and counts unknown paths
conservatively as engines. Exactly one engine remains mandatory; the RAM guard
stays 5 GiB. This correction is committed before the diagnostic rerun.

This is an investigation of preflight accounting, not a retry of a failed mesh.
The original failed preflight record is retained. A true second engine still
causes HOLD; no process is killed, no numerical threshold changes, and no physical
calculation is enabled by the correction.
