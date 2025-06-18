# IphoneSolitaire
I want my iphone to Play Solo.

## Detecting iPhone Mirroring

The repository now contains `main.py`, a small Python script that checks for
iPhone screen mirroring on macOS. It looks for a connected iPhone via
`system_profiler` and checks whether **QuickTime Player** is running. If both
conditions are true, it reports that mirroring appears to be active.

```bash
python3 main.py
```
