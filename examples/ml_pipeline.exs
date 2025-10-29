#!/usr/bin/env elixir

# ExDataCheck - Complete ML Pipeline Example
#
# This example demonstrates a complete ML workflow with data validation,
# profiling, feature engineering validation, and drift monitoring.
# Run with: mix run examples/ml_pipeline.exs

import ExDataCheck

IO.puts("\n=== ExDataCheck Complete ML Pipeline Example ===\n")
IO.puts("This example demonstrates validation at each stage of an ML pipeline:\n")
IO.puts("  1. Raw data validation")
IO.puts("  2. Data profiling and quality assessment")
IO.puts("  3. Feature engineering validation")
IO.puts("  4. Training data validation")
IO.puts("  5. Baseline creation for drift monitoring")
IO.puts("  6. Production data monitoring\n")

# Helper to safely format numeric values
format_num = fn val ->
  cond do
    is_float(val) -> Float.round(val, 2)
    is_integer(val) -> val
    true -> val
  end
end

# ============================================================================
# Stage 1: Raw Data Validation
# ============================================================================

IO.puts("=== Stage 1: Raw Data Validation ===\n")

# Simulated raw data from data source (e.g., database, API)
raw_data =
  for i <- 1..1000 do
    %{
      id: i,
      user_id: "user_#{rem(i, 100)}",
      age: 18 + rem(i, 50),
      income: 30000 + rem(i * 1000, 70000),
      credit_score: 300 + rem(i * 7, 550),
      loan_amount: 5000 + rem(i * 500, 45000),
      employment_years: rem(i, 40),
      timestamp: DateTime.add(DateTime.utc_now(), -i * 3600, :second)
    }
  end

IO.puts("Raw dataset loaded: #{length(raw_data)} records\n")

# Define raw data expectations
raw_expectations = [
  # Schema validation
  expect_column_to_exist(:id),
  expect_column_to_exist(:user_id),
  expect_column_to_exist(:age),
  expect_column_to_exist(:income),
  expect_column_to_exist(:credit_score),
  expect_column_to_exist(:loan_amount),

  # Type validation
  expect_column_to_be_of_type(:id, :integer),
  expect_column_to_be_of_type(:user_id, :string),
  expect_column_to_be_of_type(:age, :integer),
  expect_column_to_be_of_type(:income, :integer),

  # Data quality
  expect_column_values_to_not_be_null(:id),
  expect_column_values_to_not_be_null(:user_id),
  expect_column_values_to_be_unique(:id),

  # Business rules
  expect_column_values_to_be_between(:age, 18, 100),
  expect_column_values_to_be_between(:credit_score, 300, 850),
  expect_column_values_to_be_between(:income, 0, 500_000),

  # Dataset size
  expect_table_row_count_to_be_between(100, 100_000)
]

IO.puts("Validating raw data with #{length(raw_expectations)} expectations...")
raw_result = validate(raw_data, raw_expectations)

if raw_result.success do
  IO.puts(
    "✓ Raw data validation passed (#{raw_result.expectations_met}/#{raw_result.total_expectations})"
  )
else
  IO.puts("✗ Raw data validation failed (#{raw_result.expectations_failed} failures)")

  raw_result
  |> ExDataCheck.ValidationResult.failed_expectations()
  |> Enum.take(3)
  |> Enum.each(fn failed ->
    IO.puts("  - #{failed.expectation}")
  end)
end

# ============================================================================
# Stage 2: Data Profiling and Quality Assessment
# ============================================================================

IO.puts("\n\n=== Stage 2: Data Profiling and Quality Assessment ===\n")

profile = ExDataCheck.profile(raw_data, detailed: true)

IO.puts("Dataset Profile:")
IO.puts("  Rows: #{profile.row_count}")
IO.puts("  Columns: #{profile.column_count}")
IO.puts("  Quality Score: #{Float.round(profile.quality_score, 4)}")
IO.puts("  Missing Values: #{Enum.sum(Map.values(profile.missing_values))}")

IO.puts("\nNumeric Feature Statistics:")

[:age, :income, :credit_score, :loan_amount, :employment_years]
|> Enum.each(fn col ->
  stats = profile.columns[col]

  if stats do
    IO.puts(
      "  #{col}: mean=#{format_num.(stats.mean)}, " <>
        "stdev=#{format_num.(stats.stdev)}, " <>
        "range=[#{format_num.(stats.min)}, #{format_num.(stats.max)}]"
    )
  end
end)

# Check for outliers
IO.puts("\nOutlier Detection:")

[:income, :loan_amount]
|> Enum.each(fn col ->
  outlier_info = profile.columns[col].outliers

  if outlier_info && outlier_info.outlier_count > 0 do
    IO.puts("  #{col}: #{outlier_info.outlier_count} outliers detected")
  else
    IO.puts("  #{col}: No outliers")
  end
end)

# ============================================================================
# Stage 3: Feature Engineering
# ============================================================================

IO.puts("\n\n=== Stage 3: Feature Engineering ===\n")

IO.puts("Creating derived features...")

# Engineer features
engineered_data =
  raw_data
  |> Enum.map(fn row ->
    # Calculate derived features
    debt_to_income = row.loan_amount / max(row.income, 1)
    age_group = div(row.age, 10)
    income_bracket = div(row.income, 20000)

    # Normalize features to [0, 1] range
    norm_age = (row.age - 18) / (100 - 18)
    norm_credit = (row.credit_score - 300) / (850 - 300)
    norm_income = min(row.income / 200_000, 1.0)

    Map.merge(row, %{
      debt_to_income: debt_to_income,
      age_group: age_group,
      income_bracket: income_bracket,
      norm_age: norm_age,
      norm_credit: norm_credit,
      norm_income: norm_income,
      # Simulate target variable (loan approval)
      target: if(rem(row.id, 3) == 0, do: 1, else: 0)
    })
  end)

IO.puts("Features engineered: #{length(engineered_data)} records")
IO.puts("New features: debt_to_income, age_group, income_bracket, norm_*, target")

# Validate engineered features
feature_expectations = [
  # Normalized features should be in [0, 1]
  expect_column_values_to_be_between(:norm_age, 0.0, 1.0),
  expect_column_values_to_be_between(:norm_credit, 0.0, 1.0),
  expect_column_values_to_be_between(:norm_income, 0.0, 1.0),

  # No missing values in critical features
  expect_no_missing_values(:norm_age),
  expect_no_missing_values(:norm_credit),
  expect_no_missing_values(:norm_income),
  expect_no_missing_values(:target),

  # Check feature correlations (avoid multicollinearity)
  expect_feature_correlation(:norm_age, :norm_credit, max: 0.95),
  expect_feature_correlation(:norm_age, :norm_income, max: 0.95),
  expect_feature_correlation(:norm_credit, :norm_income, max: 0.95)
]

IO.puts("\nValidating engineered features...")
feature_result = validate(engineered_data, feature_expectations)

if feature_result.success do
  IO.puts("✓ Feature engineering validation passed")
else
  IO.puts("✗ Feature engineering validation failed")
end

# ============================================================================
# Stage 4: Training Data Validation
# ============================================================================

IO.puts("\n\n=== Stage 4: Training Data Validation ===\n")

# Split data (simulated)
train_size = div(length(engineered_data) * 8, 10)
training_data = Enum.take(engineered_data, train_size)
test_data = Enum.drop(engineered_data, train_size)

IO.puts("Training set: #{length(training_data)} samples")
IO.puts("Test set: #{length(test_data)} samples")

# Comprehensive training data validation
training_expectations = [
  # Sufficient data
  expect_table_row_count_to_be_between(500, 1_000_000),

  # Label balance
  expect_label_balance(:target, min_ratio: 0.2),
  expect_label_cardinality(:target, min: 2, max: 2),

  # Feature quality
  expect_column_mean_to_be_between(:norm_age, 0.0, 1.0),
  expect_column_mean_to_be_between(:norm_credit, 0.0, 1.0),
  expect_column_mean_to_be_between(:norm_income, 0.0, 1.0),

  # Feature variance (ensure features aren't constant)
  expect_column_stdev_to_be_between(:norm_age, 0.05, 1.0),
  expect_column_stdev_to_be_between(:norm_credit, 0.05, 1.0),
  expect_column_stdev_to_be_between(:norm_income, 0.05, 1.0),

  # No missing values
  expect_no_missing_values(:norm_age),
  expect_no_missing_values(:norm_credit),
  expect_no_missing_values(:norm_income),
  expect_no_missing_values(:target)
]

IO.puts("Validating training data with #{length(training_expectations)} expectations...")
training_result = validate(training_data, training_expectations)

if training_result.success do
  IO.puts(
    "✓ Training data validation passed (#{training_result.expectations_met}/#{training_result.total_expectations})"
  )
else
  IO.puts("✗ Training data validation failed")

  training_result
  |> ExDataCheck.ValidationResult.failed_expectations()
  |> Enum.each(fn failed ->
    IO.puts("  - #{failed.expectation}")
  end)
end

# Profile training data
train_profile = ExDataCheck.profile(training_data)
IO.puts("\nTraining Data Profile:")
IO.puts("  Quality Score: #{Float.round(train_profile.quality_score, 4)}")
IO.puts("  Label Distribution:")

# Calculate label distribution
label_counts =
  training_data
  |> Enum.group_by(& &1.target)
  |> Enum.map(fn {label, rows} -> {label, length(rows)} end)
  |> Enum.into(%{})

label_counts
|> Enum.each(fn {label, count} ->
  pct = Float.round(count / length(training_data) * 100, 1)
  IO.puts("    Class #{label}: #{count} samples (#{pct}%)")
end)

# ============================================================================
# Stage 5: Create Baseline for Drift Monitoring
# ============================================================================

IO.puts("\n\n=== Stage 5: Create Baseline for Production Monitoring ===\n")

# Create baseline from training data (only include feature columns)
baseline = ExDataCheck.create_baseline(training_data)

IO.puts("Baseline created from #{length(training_data)} training samples")
IO.puts("Monitoring #{map_size(baseline)} columns for drift")

# Save baseline (simulated)
IO.puts("Baseline saved to production monitoring system")

# ============================================================================
# Stage 6: Production Data Monitoring
# ============================================================================

IO.puts("\n\n=== Stage 6: Production Data Monitoring ===\n")

# Simulate production data batches
production_batches = [
  # Good batches (similar to training)
  Enum.take(test_data, 100),
  Enum.take(test_data, 100),

  # Batch with slight drift
  Enum.take(test_data, 100)
  |> Enum.map(fn row ->
    # Slight age shift
    Map.put(row, :norm_age, row.norm_age * 1.1)
  end),

  # Good batch
  Enum.take(test_data, 100)
]

IO.puts("Monitoring #{length(production_batches)} production batches...\n")

production_batches
|> Enum.with_index(1)
|> Enum.each(fn {batch, batch_num} ->
  # Validate production data
  prod_result =
    validate(batch, [
      expect_no_missing_values(:norm_age),
      expect_no_missing_values(:norm_credit),
      expect_column_values_to_be_between(:norm_age, 0.0, 1.0),
      expect_column_values_to_be_between(:norm_credit, 0.0, 1.0)
    ])

  # Check for drift
  drift_result = ExDataCheck.detect_drift(batch, baseline, threshold: 0.05)

  # Profile batch
  batch_profile = ExDataCheck.profile(batch)

  # Report batch status
  validation_status = if prod_result.success, do: "✓", else: "✗"
  drift_status = if drift_result.drifted, do: "⚠", else: "✓"
  quality_status = if batch_profile.quality_score >= 0.95, do: "✓", else: "⚠"

  IO.puts("Batch #{batch_num}:")

  IO.puts(
    "  Validation: #{validation_status} (#{prod_result.expectations_met}/#{prod_result.total_expectations} passed)"
  )

  IO.puts(
    "  Drift Check: #{drift_status} (#{if drift_result.drifted, do: "DRIFT in #{inspect(drift_result.columns_drifted)}", else: "No drift"})"
  )

  IO.puts("  Quality: #{quality_status} (score: #{Float.round(batch_profile.quality_score, 3)})")

  if not prod_result.success or drift_result.drifted or batch_profile.quality_score < 0.95 do
    IO.puts("  ⚠ Action required: Investigate batch #{batch_num}")
  end

  IO.puts("")
end)

# ============================================================================
# Summary
# ============================================================================

IO.puts("\n=== Pipeline Summary ===\n")

IO.puts("✓ Raw Data Validation: #{if raw_result.success, do: "PASSED", else: "FAILED"}")
IO.puts("✓ Data Profiling: Complete (quality score: #{Float.round(profile.quality_score, 2)})")
IO.puts("✓ Feature Engineering: #{if feature_result.success, do: "PASSED", else: "FAILED"}")
IO.puts("✓ Training Validation: #{if training_result.success, do: "PASSED", else: "FAILED"}")
IO.puts("✓ Baseline Created: #{map_size(baseline)} columns monitored")
IO.puts("✓ Production Monitoring: #{length(production_batches)} batches processed")

IO.puts("\nData Quality Pipeline:")
IO.puts("  Raw Data → Validation → Profiling → Feature Engineering →")
IO.puts("  Training Validation → Model Training → Baseline Creation →")
IO.puts("  Production Monitoring → Drift Detection → Alerting")

IO.puts("\n=== Example Complete ===\n")
IO.puts("This example demonstrates a production-ready ML pipeline with:")
IO.puts("  • Comprehensive data validation at each stage")
IO.puts("  • Detailed profiling and quality assessment")
IO.puts("  • Feature engineering validation")
IO.puts("  • Training data quality checks")
IO.puts("  • Drift detection and monitoring")
IO.puts("  • Production data validation")
IO.puts("")
