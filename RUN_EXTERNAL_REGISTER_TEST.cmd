@echo off
setlocal
set "PROJECT_DIR=/mnt/c/Users/waimi/Documents/Codex/2026-07-10/can/projects/nanov-1tile-tinytapeout-sky"

wsl.exe -d Ubuntu -- bash -lc "cd '%PROJECT_DIR%' && iverilog -g2012 -s external_register_tb -o /tmp/nanov_extreg.vvp src/nanoV/register_external.v test/external_register_tb.v && vvp /tmp/nanov_extreg.vvp && yosys -l docs/EXTREG_SYNTH.log -s scripts/synth_external_registers.ys"
set "TEST_EXIT=%ERRORLEVEL%"

if "%TEST_EXIT%"=="0" (
  echo NanoV external-register staging test passed.
) else (
  echo NanoV external-register staging test failed with exit code %TEST_EXIT%.
)
pause
exit /b %TEST_EXIT%
