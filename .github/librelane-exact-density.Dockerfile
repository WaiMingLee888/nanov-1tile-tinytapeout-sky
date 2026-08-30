FROM ghcr.io/librelane/librelane:3.0.5

COPY scripts/patch_librelane_gpl.py /tmp/patch_librelane_gpl.py
RUN python /tmp/patch_librelane_gpl.py
