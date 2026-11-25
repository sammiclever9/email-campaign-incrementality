# Fresh-download validation

## Procedure

Downloaded and extracted a fresh repository ZIP, restarted R,
and followed the README instructions to obtain the dataset
and run analysis.R.

The published dashboard CSV was read before running the script.
The regenerated CSV was then compared with that saved copy.

## Checks passed

- Four result rows were regenerated.
- Two rows were labeled Primary and two were labeled Secondary.
- Column names and comparison labels matched.
- Every exported column matched the published results.
- Numeric comparisons passed with tolerance 1e-12.
- The script's data and export checks passed.

## Primary outcome — purchase conversion

Effects are campaign minus no-email control, in percentage points.

| Campaign | Effect | Lower 95% | Upper 95% |
|---|---:|---:|---:|
| Mens E-Mail | 0.681 | 0.500 | 0.861 |
| Womens E-Mail | 0.311 | 0.150 | 0.472 |

Intervals are individual 95% proportion-test intervals.

## Secondary outcome — spend per assigned customer

Effects are campaign minus no-email control, in dollars per
assigned customer, including customers who spent zero.

| Campaign | Effect | Lower 95% | Upper 95% |
|---|---:|---:|---:|
| Mens E-Mail | 0.770 | 0.492 | 1.070 |
| Womens E-Mail | 0.424 | 0.167 | 0.672 |

Intervals are individual 95% percentile-bootstrap intervals
using 5,000 resamples and seed 20261124.

Displayed estimates are rounded to three decimal places.
Comparisons used the full-precision exports.

## Result

All checks returned TRUE.

Final confirmation:

> Fresh-download test passed. All four dashboard results match.

This check confirms reproducibility in the tested local
environment. It does not establish compatibility with every
R version or operating system.
