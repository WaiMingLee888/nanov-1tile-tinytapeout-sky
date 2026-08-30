@echo off
setlocal
set "PROJECT_DIR=/mnt/c/Users/waimi/Documents/Codex/2026-07-10/can/projects/nanov-1tile-tinytapeout-sky"

wsl.exe -d Ubuntu -- bash -lc "cd '%PROJECT_DIR%' && bash scripts/test_external_register_path.sh"
set "TEST_EXIT=%ERRORLEVEL%"

if "%TEST_EXIT%"=="0" (
  echo NanoV external-register staging test passed.
) else (
  echo NanoV external-register staging test failed with exit code %TEST_EXIT%.
)
pause
exit /b %TEST_EXIT%
