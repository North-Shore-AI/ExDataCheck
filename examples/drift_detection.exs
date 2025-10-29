#!/usr/bin/env elixir

# ExDataCheck - Drift Detection Example
#
# This example demonstrates data drift detection for monitoring ML model performance.
# Run with: mix run examples/drift_detection.exs

IO.puts("\n=== ExDataCheck Drift Detection Example ===\n")

# Helper to safely format numeric values
format_num = fn val ->
  cond do
    is_float(val) -> Float.round(val, 4)
    is_integer(val) -> val
    true -> val
  end
end

# ============================================================================
# Create Training Baseline
# ============================================================================

IO.puts("=== Creating Baseline from Training Data ===\n")

# Simulated training data (normalized features, balanced labels)
training_data =
  for _i <- 1..1000 do
    %{
      # Mean ~50, StdDev ~10
      feature1: :rand.normal() * 10 + 50,
      # Mean ~100, StdDev ~5
      feature2: :rand.normal() * 5 + 100,
      # Uniform 10-30
      feature3: :rand.uniform() * 20 + 10,
      # Balanced categories
      category: Enum.random(["A", "B", "C"]),
      # Binary classification
      target: Enum.random([0, 1])
    }
  end

IO.puts("Training dataset: #{length(training_data)} samples")

# Profile the training data
training_profile = ExDataCheck.profile(training_data)
IO.puts("Training data quality score: #{Float.round(training_profile.quality_score, 2)}")

# Display training statistics
IO.puts("\nTraining Data Statistics:")

[:feature1, :feature2, :feature3]
|> Enum.each(fn col ->
  stats = training_profile.columns[col]
  IO.puts("  #{col}:")
  IO.puts("    Mean: #{format_num.(stats.mean)}")
  IO.puts("    StdDev: #{format_num.(stats.stdev)}")
  IO.puts("    Min: #{format_num.(stats.min)}")
  IO.puts("    Max: #{format_num.(stats.max)}")
end)

# Create baseline for drift detection
baseline = ExDataCheck.create_baseline(training_data)
IO.puts("\nBaseline created for #{map_size(baseline)} columns")

# ============================================================================
# Scenario 1: No Drift (Production data similar to training)
# ============================================================================

IO.puts("\n\n=== Scenario 1: No Drift (Good Production Data) ===\n")

production_data_good =
  for _i <- 1..500 do
    %{
      # Same distribution
      feature1: :rand.normal() * 10 + 50,
      # Same distribution
      feature2: :rand.normal() * 5 + 100,
      # Same distribution
      feature3: :rand.uniform() * 20 + 10,
      category: Enum.random(["A", "B", "C"]),
      target: Enum.random([0, 1])
    }
  end

IO.puts("Production dataset: #{length(production_data_good)} samples")

drift_result = ExDataCheck.detect_drift(production_data_good, baseline)

IO.puts("\nDrift Detection Results:")
IO.puts("  Drifted: #{drift_result.drifted}")
IO.puts("  Method: #{drift_result.method}")
IO.puts("  Threshold: #{drift_result.threshold}")
IO.puts("  Columns Drifted: #{inspect(drift_result.columns_drifted)}")

IO.puts("\n  Drift Scores:")

drift_result.drift_scores
|> Enum.sort()
|> Enum.each(fn {col, score} ->
  status = if score > drift_result.threshold, do: "⚠ DRIFT", else: "✓ OK"
  IO.puts("    #{col}: #{format_num.(score)} #{status}")
end)

if drift_result.drifted do
  IO.puts("\n  ⚠ Warning: Drift detected! Consider retraining the model.")
else
  IO.puts("\n  ✓ No significant drift detected. Model is safe to use.")
end

# ============================================================================
# Scenario 2: Moderate Drift (Slight distribution shift)
# ============================================================================

IO.puts("\n\n=== Scenario 2: Moderate Drift (Slight Distribution Shift) ===\n")

production_data_moderate =
  for _i <- 1..500 do
    %{
      # Mean shifted from 50 to 55
      feature1: :rand.normal() * 10 + 55,
      # StdDev increased from 5 to 6
      feature2: :rand.normal() * 6 + 100,
      # Same distribution
      feature3: :rand.uniform() * 20 + 10,
      category: Enum.random(["A", "B", "C"]),
      target: Enum.random([0, 1])
    }
  end

IO.puts("Production dataset: #{length(production_data_moderate)} samples")

drift_result2 = ExDataCheck.detect_drift(production_data_moderate, baseline)

IO.puts("\nDrift Detection Results:")
IO.puts("  Drifted: #{drift_result2.drifted}")
IO.puts("  Method: #{drift_result2.method}")
IO.puts("  Threshold: #{drift_result2.threshold}")
IO.puts("  Columns Drifted: #{inspect(drift_result2.columns_drifted)}")

IO.puts("\n  Drift Scores:")

drift_result2.drift_scores
|> Enum.sort()
|> Enum.each(fn {col, score} ->
  status = if score > drift_result2.threshold, do: "⚠ DRIFT", else: "✓ OK"
  IO.puts("    #{col}: #{format_num.(score)} #{status}")
end)

if drift_result2.drifted do
  IO.puts("\n  ⚠ Warning: Drift detected in: #{inspect(drift_result2.columns_drifted)}")
  IO.puts("  Consider investigating and potentially retraining.")
else
  IO.puts("\n  ✓ No significant drift detected.")
end

# ============================================================================
# Scenario 3: Significant Drift (Major distribution change)
# ============================================================================

IO.puts("\n\n=== Scenario 3: Significant Drift (Major Distribution Change) ===\n")

production_data_bad =
  for _i <- 1..500 do
    %{
      # Mean shifted significantly (50 -> 70)
      feature1: :rand.normal() * 15 + 70,
      # Mean and variance changed
      feature2: :rand.normal() * 10 + 120,
      # Range shifted completely
      feature3: :rand.uniform() * 30 + 20,
      # New category appeared
      category: Enum.random(["A", "B", "D"]),
      target: Enum.random([0, 1])
    }
  end

IO.puts("Production dataset: #{length(production_data_bad)} samples")

drift_result3 = ExDataCheck.detect_drift(production_data_bad, baseline)

IO.puts("\nDrift Detection Results:")
IO.puts("  Drifted: #{drift_result3.drifted}")
IO.puts("  Method: #{drift_result3.method}")
IO.puts("  Threshold: #{drift_result3.threshold}")
IO.puts("  Columns Drifted: #{inspect(drift_result3.columns_drifted)}")

IO.puts("\n  Drift Scores:")

drift_result3.drift_scores
|> Enum.sort()
|> Enum.each(fn {col, score} ->
  status = if score > drift_result3.threshold, do: "⚠ DRIFT", else: "✓ OK"
  IO.puts("    #{col}: #{format_num.(score)} #{status}")
end)

if drift_result3.drifted do
  IO.puts("\n  🚨 CRITICAL: Significant drift detected!")
  IO.puts("  Affected columns: #{inspect(drift_result3.columns_drifted)}")
  IO.puts("  Action required: Model retraining recommended.")
else
  IO.puts("\n  ✓ No significant drift detected.")
end

# ============================================================================
# Custom Threshold Testing
# ============================================================================

IO.puts("\n\n=== Custom Threshold Testing ===\n")

# Test with stricter threshold
strict_result =
  ExDataCheck.detect_drift(
    production_data_moderate,
    baseline,
    # Very strict (default is 0.05)
    threshold: 0.01
  )

IO.puts("Strict threshold (0.01):")
IO.puts("  Drifted: #{strict_result.drifted}")
IO.puts("  Columns Drifted: #{inspect(strict_result.columns_drifted)}")

# Test with more lenient threshold
lenient_result =
  ExDataCheck.detect_drift(
    production_data_bad,
    baseline,
    # Very lenient
    threshold: 0.2
  )

IO.puts("\nLenient threshold (0.2):")
IO.puts("  Drifted: #{lenient_result.drifted}")
IO.puts("  Columns Drifted: #{inspect(lenient_result.columns_drifted)}")

# ============================================================================
# Using Drift Detection in Expectations
# ============================================================================

IO.puts("\n\n=== Using Drift Detection in Expectations ===\n")

import ExDataCheck

# Create expectations with drift detection
expectations = [
  expect_no_data_drift(:feature1, baseline, threshold: 0.05),
  expect_no_data_drift(:feature2, baseline, threshold: 0.05),
  expect_no_data_drift(:feature3, baseline, threshold: 0.05)
]

# Validate good production data
IO.puts("Validating good production data:")
result_good = ExDataCheck.validate(production_data_good, expectations)
IO.puts("  Success: #{result_good.success}")
IO.puts("  Expectations Met: #{result_good.expectations_met}/#{result_good.total_expectations}")

# Validate bad production data
IO.puts("\nValidating drifted production data:")
result_bad = ExDataCheck.validate(production_data_bad, expectations)
IO.puts("  Success: #{result_bad.success}")
IO.puts("  Expectations Met: #{result_bad.expectations_met}/#{result_bad.total_expectations}")

if not result_bad.success do
  IO.puts("\n  Failed drift checks:")

  result_bad
  |> ExDataCheck.ValidationResult.failed_expectations()
  |> Enum.each(fn failed ->
    IO.puts("    - #{failed.expectation}")
  end)
end

# ============================================================================
# Monitoring Pipeline Simulation
# ============================================================================

IO.puts("\n\n=== Production Monitoring Pipeline Simulation ===\n")

IO.puts("Simulating 10 batches of production data...\n")

batches = [
  {1, production_data_good, "Normal"},
  {2, production_data_good, "Normal"},
  {3, production_data_moderate, "Slight shift"},
  {4, production_data_good, "Normal"},
  {5, production_data_moderate, "Slight shift"},
  {6, production_data_good, "Normal"},
  {7, production_data_bad, "Major shift"},
  {8, production_data_bad, "Major shift"},
  {9, production_data_good, "Normal"},
  {10, production_data_good, "Normal"}
]

IO.puts("Batch | Drifted | Columns Affected | Description")
IO.puts("------|---------|------------------|------------")

batches
|> Enum.each(fn {batch_num, data, desc} ->
  drift = ExDataCheck.detect_drift(data, baseline, threshold: 0.05)
  drifted_str = if drift.drifted, do: "YES", else: "NO "

  columns_str =
    if drift.drifted do
      drift.columns_drifted |> Enum.take(2) |> Enum.join(", ")
    else
      "-"
    end

  IO.puts(
    String.pad_trailing("  #{batch_num}", 6) <>
      " | " <>
      String.pad_trailing(drifted_str, 8) <>
      " | " <>
      String.pad_trailing(columns_str, 17) <>
      "| #{desc}"
  )
end)

IO.puts("\n=== Example Complete ===\n")
IO.puts("Key Takeaways:")
IO.puts("  1. Create baselines from training data")
IO.puts("  2. Monitor production data for drift")
IO.puts("  3. Adjust thresholds based on use case")
IO.puts("  4. Retrain models when significant drift is detected")
IO.puts("  5. Use drift detection in validation pipelines")
IO.puts("")
