# Repeat the pinned prestart check (default 8.2 GiB, no override) every 15 s for up to 30 min;
# on the first pass launch MATLAB at once for the GO-absent activation checks.
$S = '<scratch>'
$ps = '<repo>\scripts\g2\lp2a2\lp2a2_eq_prestart_check.ps1'
$deadline = (Get-Date).AddMinutes(30); $n = 0; $max = 0
while ((Get-Date) -lt $deadline) {
  $n++
  $line = powershell -NoProfile -ExecutionPolicy Bypass -File $ps -Out "$S\pre\LP2A2_EQ_A2_PRESTART_ACTCHECK.json"
  $code = $LASTEXITCODE
  $f = (Get-Content "$S\pre\LP2A2_EQ_A2_PRESTART_ACTCHECK.json" -Raw | ConvertFrom-Json).freePhysicalGiB
  if ($f -gt $max) { $max = $f }
  if ($code -eq 0) {
    Write-Output "PRESTART_PASS attempt=$n $line"
    & '<scratch>' -Tag lp2a2_eq_a2_activation_checks -Script "$S\lp2a2_eq_a2_activation_checks.m" -Cwd '<repo>' | Select-String -Pattern 'A2ACT|PRELAUNCH|EXIT|ERROR|REFUSE'
    exit 0
  }
  Start-Sleep -Seconds 15
}
Write-Output "PRESTART_TIMEOUT attempts=$n maxFree=$max"
exit 4
