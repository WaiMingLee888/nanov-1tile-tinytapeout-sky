@echo off
setlocal
set "TEST_DIR=/mnt/c/Users/waimi/Documents/Codex/2026-07-10/can/projects/nanov-1tile-tinytapeout-sky/test"
set "LOG_FILE=/mnt/c/Users/waimi/Documents/Codex/2026-07-10/can/projects/nanov-1tile-tinytapeout-sky/docs/RTL_TEST_LATEST.log"

wsl.exe -d Ubuntu -- bash -lc "source /mnt/d/riscv/nanov-tinytapeout-sky/.venv/bin/activate; cd '%TEST_DIR%'; exec > >(tee '%LOG_FILE%') 2>&1; echo RUN_STARTED=$(date -Iseconds); python ../scripts/verify_one_tile_contract.py || exit 10; python make_test_mem.py test.mem || exit 11; make clean || exit 12; make || exit 13; if grep -q failure results.xml; then exit 14; fi"
set "TEST_EXIT=%ERRORLEVEL%"
echo.
if "%TEST_EXIT%"=="0" (
  echo NanoV one-tile RTL test passed.
) else (
  echo NanoV one-tile RTL test failed with exit code %TEST_EXIT%.
)
pause
exit /b %TEST_EXIT%
