# Changelog

All notable changes to FdiTools are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/),
and the project follows [Semantic Versioning](https://semver.org/).

> 🇯🇵 日本語版: [CHANGELOG_JP.md](CHANGELOG_JP.md)

## [3.0.1] - 2026-06-18

### Changed
- `bode_fdi` `'style','band'` now shades the complex confidence disk on **both**
  the magnitude **and** the phase axis (phase half-width `±asin(r/|G|)`, full
  `±180°` once the disk reaches the origin).
- `residtest` computes the residual autocorrelation with an FFT instead of
  `xcorr`, so the validation step no longer needs the Signal Processing Toolbox.
- `fdicohere` rewritten to compute the periodic (ensemble) coherence from the
  per-period DFTs (no Signal Processing Toolbox). It accepts
  `fdicohere(Pest)` (uses the time data saved by `time2frf_ml`) or
  `fdicohere(Pest, dat)` (uses the iodata `dat`).

### Backward compatibility (v2.1.1, SISO/SIMO)
- `UserData.sGhat` is kept as a **deprecated alias** of `UserData.sG`.
- `bode_fdi(data, noise, option)` (the old positional/struct call) is still
  accepted and mapped to the name-value options, emitting an
  `FdiTools:deprecated` warning. Suppress it with
  `warning('off','FdiTools:deprecated')`.

### Toolboxes
- Required: MATLAB, Control System Toolbox.
- Optional: System Identification Toolbox (`iodata` ↔ `iddata`),
  Signal Processing Toolbox (legacy windowed estimators and `Tutorial_1` only).

## [3.0.0] - 2026-06-15

Major upgrade, continuing the original FdiTools (v1–v2.1.1).

### Added
- `iodata` — an `iddata`-compatible time-domain container that works without the
  System Identification Toolbox.
- Local Polynomial Method (`time2frf_lpm`): periodic and broadband modes;
  identifies the FRF from short, transient-corrupted records.
- MIMO FRF (`time2frf_ml`): orthogonal multiple-experiment and zippered
  single-experiment multisines.
- Robust BLA (`time2bla`): separates measurement noise from nonlinear
  distortions.
- `bode_fdi` redesigned (name-value API) and `frfconf`: FRF Bode plots with
  uncertainty and closed-form confidence bounds (no Statistics Toolbox).

### Changed
- FRF standard deviation field renamed `UserData.sGhat` → `UserData.sG`
  (PS2012 eq. 2-38). See the migration notes below.
- `bode_fdi` switched from a positional/struct API to name-value options.
- MIMO FRF estimation now goes through `iodata`: `time2frf_ml(dat)`.

---

## Migration from v2.1.1 to v3.0

### Works unchanged (SISO/SIMO)
These v2.1.1 calls keep the same signature and behaviour:

| Call | Notes |
|---|---|
| `Pest = time2frf_ml(x, y, ms)` | still returns an `frd` |
| `[y, time] = pretreat(x, nrofs, fs, nroft, trend)` | matrix form retained |
| `ms = multisine(harm, Hampl, options)` | unchanged |
| `nlsfdi(Pest, FRF_W, n, mh, ml, …)` / `mlfdi(Pest, …)` | unchanged |
| `btlsfdi(Pest, n, mh, ml, relax, iter, max_err, cORd)` | unchanged |
| `Pest.freq`, `Pest.resp` | `frd` properties (`Frequency`/`ResponseData`) |

### What changed (and how to update)

**1. FRF standard deviation field**

```matlab
% v2.1.1
sg = Pest.UserData.sGhat;
% v3.0 (preferred)
sg = Pest.UserData.sG;
```
`sGhat` is kept as a deprecated alias, so old code still runs. It is a plain
struct field, so reading it does **not** print a warning; please migrate to `sG`.

**2. Bode plots (`bode_fdi`)**

```matlab
% v2.1.1
option.pmin = -180; option.pmax = 180; option.title = 'G';
bode_fdi({Pest}, [freq, noise], option);

% v3.0
bode_fdi(Pest, 'unc', 'sG', 'style', 'band', ...
         'pmin', -180, 'pmax', 180, 'title', 'G');
```
The legacy form is still accepted (with an `FdiTools:deprecated` warning).
New capabilities: `'unc'` selects the uncertainty source (`'sG'`, `'sCR'`,
`'FRFn'`, or an explicit `[freq mag]`), and `'style','band'` shades the
confidence disk on both magnitude and phase.

**3. MIMO**

MIMO FRF estimation now uses `iodata`:

```matlab
dat  = iodata(output, input, 1/fs, 'Period', nrofs, 'UserData', struct('ms', ms));
Pest = time2frf_ml(dat);     % orthogonal (multi-experiment) or zippered
```

### Deprecation policy
Deprecated SISO/SIMO aliases (`UserData.sGhat`, the `bode_fdi` positional/struct
call) are kept for compatibility and may be removed in a future major version.
Prefer `UserData.sG` and the name-value `bode_fdi` API in new code.
