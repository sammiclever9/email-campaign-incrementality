# email-campaign-incrementality
Causal analysis of a randomized email campaign using R and Power BI, with hypothesis testing and bootstrap confidence intervals.

## Power BI dashboard

![Email campaign dashboard showing primary conversion effects and secondary spending effects, with individual 95% confidence intervals](figures/email-campaign-dashboard.png)

### Primary outcome — purchase conversion

Compared with no email, estimated conversion increased by 0.681 percentage points for the men's campaign and 0.311 percentage points for the women's campaign.

### Secondary outcome — spend per assigned customer

Estimated incremental spending was $0.770 per customer for the men's campaign and $0.424 for the women's campaign, including customers who spent zero.

*Effects are campaign minus control over two weeks. Conversion error bars show individual 95% proportion-test intervals. Spending error bars show individual 95% percentile-bootstrap intervals from 5,000 resamples. Both campaigns passed Holm-adjusted tests within each outcome's two-comparison family.*

Spending measures revenue. Costs and margins are needed to estimate profit.

## Reproduce the analysis

The analysis requires R. RStudio is recommended.
No additional R packages are required.

1. Download and extract this repository.
2. Open analysis.R in RStudio.
3. Select Session → Set Working Directory → To Source File Location.
4. Download the dataset using the code below.
5. Click Source to run analysis.R.

### Download the dataset

Run this code once in the RStudio Console from the project folder.
Skip this step if data/raw/hillstrom.csv already exists.

```r
# Create the input folder.
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)

# Download the dataset mirror.
download.file(
  "https://hillstorm1.s3.us-east-2.amazonaws.com/hillstorm_no_indices.csv.gz",
  "data/raw/hillstrom.csv.gz",
  mode = "wb"
)

# Save the uncompressed input.
raw_data <- read.csv("data/raw/hillstrom.csv.gz")
write.csv(raw_data, "data/raw/hillstrom.csv", row.names = FALSE)
```

### Methods and output

- Primary outcome: purchase conversion, analyzed with two-sided
  proportion tests.
- Secondary outcome: spend per assigned customer, including zero
  spending, analyzed with Welch tests and percentile-bootstrap
  confidence intervals.
- Bootstrap settings: 5,000 resamples and seed 20261124.
- Holm adjustments are applied separately within each outcome's
  two campaign-versus-control comparisons.
- All confidence intervals are individual 95% intervals.

The script checks the data and regenerates
power_bi_exports/campaign_effects.csv with two primary and two
secondary results.

Successful execution ends with:

```text
Analysis checks passed. Campaign effects export verified.
```

Bootstrap results may vary slightly across R versions or random
number generator settings.

See [dataset provenance](metadata/data-source.md) for the source,
experiment design, and variable definitions.


### Validation

A fresh-download test reproduced all four dashboard results,
with primary conversion and secondary spending results checked
separately.

See the [fresh-download validation record](metadata/fresh-download-validation.md).

[Download the editable Power BI report](email-campaign-dashboard.pbix)

The [R session information](metadata/r-session-info.txt) records
the environment used for the local validation.

### GitHub Actions verification

The manually triggered workflow runs analysis.R using R 4.3.3
on Ubuntu 22.04.

It verifies two primary conversion comparisons and two secondary
spending comparisons, then checks every exported column against
the committed dashboard CSV using numeric tolerance 1e-12.

Two manual runs completed successfully.

[View the second successful run](https://github.com/sammiclever9/email-campaign-incrementality/actions/runs/45603662463).

Successful runs provide a verified-campaign-results artifact
containing the regenerated CSV, comparison checks, and R session
information. Artifacts are retained for seven days.

To run it, open Actions → Verify email campaign analysis →
Run workflow, select main, and confirm.

### Reconnect and refresh the Power BI report

1. Download and extract the repository ZIP.
2. Open email-campaign-dashboard.pbix in Power BI Desktop.
3. Select File → Options and settings → Data source settings.
4. Under Data sources in current file, select the CSV source.
5. Click Change Source → Browse.
6. Select power_bi_exports/campaign_effects.csv from your
   extracted repository folder.
7. Click OK, then Close. Apply pending changes if prompted.
8. Select Home → Refresh.
9. Verify both charts, then save the report.

If Change Source is unavailable, select Home → Transform data,
choose the campaign query, and use the gear beside its Source
step to update the CSV path. Select Close & Apply afterward.

### Verify the refreshed results

Primary outcome — purchase conversion:
- Mens E-Mail: +0.681 percentage points, individual 95% CI
  0.500 to 0.861.
- Womens E-Mail: +0.311 percentage points, individual 95% CI
  0.150 to 0.472.

Secondary outcome — spend per assigned customer:
- Mens E-Mail: +$0.770, individual 95% bootstrap CI
  $0.492 to $1.070.
- Womens E-Mail: +$0.424, individual 95% bootstrap CI
  $0.167 to $0.672.

All effects compare the campaign with the no-email control.
Spending includes every assigned customer, including those
who spent zero.

Power BI refresh reloads the exported estimates. To recalculate
the statistical results, run analysis.R before refreshing.

The CSV reconnection and refresh were tested locally.
Both charts matched the verified R export.

