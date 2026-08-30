@echo off
setlocal
set "PROJECT_DIR=/mnt/c/Users/waimi/Documents/Codex/2026-07-10/can/projects/nanov-1tile-tinytapeout-sky"
set "LOG_FILE=%PROJECT_DIR%/docs/FIRMWARE_TEST_LATEST.log"

wsl.exe -d Ubuntu -- bash -lc "source /mnt/d/riscv/nanov-tinytapeout-sky/.venv/bin/activate; cd '%PROJECT_DIR%'; exec > >(tee '%LOG_FILE%') 2>&1; echo RUN_STARTED=$(date -Iseconds); make -C firmware clean; make -C firmware simulate"
set "TEST_EXIT=%ERRORLEVEL%"
echo.
if "%TEST_EXIT%"=="0" (
  echo Compiler-generated NanoV firmware test passed.
) else (
  echo Compiler-generated NanoV firmware test failed with exit code %TEST_EXIT%.
)
pause
exit /b %TEST_EXIT%
