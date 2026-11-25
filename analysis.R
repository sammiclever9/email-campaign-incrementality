# Email campaign incrementality analysis.
# Run from the project folder.

input_file <- file.path("data", "raw", "hillstrom.csv")
output_dir <- "power_bi_exports"

if (!file.exists(input_file)) {
  stop("Place hillstrom.csv in data/raw before running.")
}

# Read the customer-level experiment data.
email <- read.csv(
  input_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

required_columns <- c(
  "recency", "history_segment", "history", "mens", "womens",
  "zip_code", "newbie", "channel", "segment",
  "visit", "conversion", "spend"
)

stopifnot(
  nrow(email) == 64000L,
  ncol(email) == 12L,
  setequal(names(email), required_columns)
)

# Check missing and blank entries.
missing_counts <- vapply(email, function(x) {
  sum(is.na(x) | trimws(as.character(x)) == "")
}, integer(1))

stopifnot(all(missing_counts == 0L))

# Check numeric outcome coding.
email$visit <- suppressWarnings(as.numeric(email$visit))
email$conversion <- suppressWarnings(as.numeric(email$conversion))
email$spend <- suppressWarnings(as.numeric(email$spend))

stopifnot(
  all(email$visit %in% c(0, 1)),
  all(email$conversion %in% c(0, 1)),
  all(is.finite(email$spend)),
  all(email$spend >= 0),
  all((email$conversion == 1) == (email$spend > 0)),
  all(email$conversion <= email$visit)
)

# Verify the treatment assignments.
group_names <- c("No E-Mail", "Mens E-Mail", "Womens E-Mail")
expected_counts <- c(21306L, 21307L, 21387L)

stopifnot(all(email$segment %in% group_names))

group_counts <- table(factor(email$segment, levels = group_names))
stopifnot(all(as.integer(group_counts) == expected_counts))

# Summarize all customers in each assigned group.
treatment_summary <- do.call(rbind, lapply(group_names, function(g) {
  d <- email[email$segment == g, ]
  
  data.frame(
    segment = g,
    customers = nrow(d),
    visits = sum(d$visit),
    conversions = sum(d$conversion),
    total_spend = sum(d$spend),
    visit_pct = 100 * mean(d$visit),
    conversion_pct = 100 * mean(d$conversion),
    spend_per_customer = mean(d$spend)
  )
}))

rownames(treatment_summary) <- NULL

stopifnot(
  sum(treatment_summary$customers) == 64000,
  sum(treatment_summary$visits) == 9394,
  sum(treatment_summary$conversions) == 578
)

# Keep the shared control and campaign names.
control <- treatment_summary[
  treatment_summary$segment == "No E-Mail", ]
campaigns <- c("Mens E-Mail", "Womens E-Mail")

# Primary outcome: compare purchase conversion rates.
conversion_results <- do.call(rbind, lapply(campaigns, function(g) {
  treatment <- treatment_summary[treatment_summary$segment == g, ]
  
  test <- prop.test(
    x = c(treatment$conversions, control$conversions),
    n = c(treatment$customers, control$customers),
    alternative = "two.sided",
    correct = FALSE
  )
  
  data.frame(
    outcome_role = "Primary",
    outcome = "Purchase conversion",
    campaign = g,
    effect_unit = "Percentage points",
    effect = 100 * (
      treatment$conversions / treatment$customers -
        control$conversions / control$customers
    ),
    lower_95 = 100 * unname(test$conf.int[1]),
    upper_95 = 100 * unname(test$conf.int[2]),
    p_original = test$p.value,
    ci_method = "Individual 95% proportion-test interval"
  )
}))

# Adjust the two primary comparison p-values.
conversion_results$p_holm <- p.adjust(
  conversion_results$p_original,
  method = "holm"
)

# Secondary outcome: include every assigned customer's spending.
spend_groups <- setNames(lapply(group_names, function(g) {
  email$spend[email$segment == g]
}), group_names)

control_spend <- spend_groups[["No E-Mail"]]

# Run two-sided Welch tests for mean spending.
spending_p <- vapply(campaigns, function(g) {
  t.test(
    spend_groups[[g]],
    control_spend,
    alternative = "two.sided",
    var.equal = FALSE
  )$p.value
}, numeric(1))

# Bootstrap customers independently within each assignment group.
set.seed(20261124)
bootstrap_reps <- 5000L

bootstrap_spending <- replicate(bootstrap_reps, {
  control_mean <- mean(sample(
    control_spend,
    size = length(control_spend),
    replace = TRUE
  ))
  
  vapply(campaigns, function(g) {
    spending <- spend_groups[[g]]
    
    mean(sample(
      spending,
      size = length(spending),
      replace = TRUE
    )) - control_mean
  }, numeric(1))
})

# Calculate individual percentile-bootstrap intervals.
spending_intervals <- t(apply(
  bootstrap_spending,
  1,
  quantile,
  probs = c(0.025, 0.975),
  names = FALSE
))

spending_results <- data.frame(
  outcome_role = "Secondary",
  outcome = "Spend per assigned customer",
  campaign = campaigns,
  effect_unit = "Dollars per customer",
  effect = vapply(campaigns, function(g) {
    mean(spend_groups[[g]]) - mean(control_spend)
  }, numeric(1)),
  lower_95 = spending_intervals[, 1],
  upper_95 = spending_intervals[, 2],
  p_original = unname(spending_p),
  ci_method = "Individual 95% percentile-bootstrap interval"
)

# Adjust the two secondary comparison p-values separately.
spending_results$p_holm <- p.adjust(
  spending_results$p_original,
  method = "holm"
)

# Combine the dashboard results without rounding.
dashboard_results <- rbind(conversion_results, spending_results)
rownames(dashboard_results) <- NULL

dashboard_results$comparison <- "Campaign minus No E-Mail"
dashboard_results$adjustment_family <- paste(
  "Two campaign-versus-control",
  dashboard_results$outcome,
  "tests"
)
dashboard_results$reject_equal_outcomes <-
  dashboard_results$p_holm <= 0.05

# Retain the dashboard's existing export columns.
export_columns <- c(
  "outcome_role", "outcome", "campaign", "effect_unit",
  "effect", "lower_95", "upper_95", "p_holm", "ci_method",
  "comparison", "adjustment_family", "reject_equal_outcomes"
)

dashboard_results <- dashboard_results[export_columns]

# Check the four effect estimates and interval bounds.
stopifnot(
  nrow(dashboard_results) == 4L,
  all(is.finite(dashboard_results$effect)),
  all(dashboard_results$lower_95 < dashboard_results$effect),
  all(dashboard_results$upper_95 > dashboard_results$effect),
  all(dashboard_results$p_holm >= 0),
  all(dashboard_results$p_holm <= 1),
  isTRUE(all.equal(
    round(dashboard_results$effect, 3),
    c(0.681, 0.311, 0.770, 0.424),
    check.attributes = FALSE
  ))
)

# Export the results for Power BI.
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
output_file <- file.path(output_dir, "campaign_effects.csv")

write.csv(dashboard_results, output_file, row.names = FALSE)

# Verify the saved CSV against the analysis results.
export_check <- read.csv(output_file, stringsAsFactors = FALSE)

stopifnot(isTRUE(all.equal(
  dashboard_results,
  export_check,
  tolerance = 1e-12,
  check.attributes = FALSE
)))

# Display the results without changing their stored precision.
display_results <- dashboard_results[
  c("outcome_role", "campaign", "effect", "lower_95", "upper_95")
]
display_results[3:5] <- lapply(display_results[3:5], round, 3)

print(treatment_summary, row.names = FALSE)
print(display_results, row.names = FALSE)
message("Analysis checks passed. Campaign effects export verified.")