<p align="center">
  <img src="assets/ExDataCheck.svg" alt="ExDataCheck" width="150"/>
</p>

# ExDataCheck

**Production-Ready Data Validation and Quality Library for Elixir ML Pipelines**

[![Elixir](https://img.shields.io/badge/elixir-1.14+-purple.svg)](https://elixir-lang.org)
[![OTP](https://img.shields.io/badge/otp-25+-blue.svg)](https://www.erlang.org)
[![Hex.pm](https://img.shields.io/hexpm/v/ex_data_check.svg)](https://hex.pm/packages/ex_data_check)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-purple.svg)](https://hexdocs.pm/ex_data_check)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/North-Shore-AI/ExDataCheck/blob/main/LICENSE)
[![Tests](https://img.shields.io/badge/tests-314%20passing-success.svg)](https://github.com/North-Shore-AI/ExDataCheck)
[![Coverage](https://img.shields.io/badge/coverage-%3E90%25-success.svg)](https://github.com/North-Shore-AI/ExDataCheck)

---

A comprehensive data validation and quality assessment library for Elixir, specifically designed for machine learning workflows. ExDataCheck brings Great Expectations-style validation to the Elixir ecosystem with 34 built-in expectations, advanced profiling, drift detection, and comprehensive statistical analysis.

## ✨ Features

### Core Capabilities (v0.2.1)

- ✅ **34 Built-in Expectations**: Schema, value, statistical, ML, temporal, string, and composite validations
- ✅ **Data Profiling**: Comprehensive statistical analysis with outlier detection
- ✅ **Drift Detection**: Distribution change detection with KS test and PSI
- ✅ **Correlation Analysis**: Pearson and Spearman correlations for feature engineering
- ✅ **Quality Scoring**: Automatic data quality assessment
- ✅ **Multiple Export Formats**: JSON, Markdown reports
- ✅ **Property-Based Testing**: Mathematical correctness guaranteed
- ✅ **Production Ready**: Zero warnings, >90% test coverage

### New in v0.3.0

- ✅ **Pipeline Stage Integration**: Use ExDataCheck in data processing pipelines
- ✅ **Crucible Framework Support**: Optional integration with CrucibleIR (optional dependency)
- ✅ **Context-Based API**: Stage module for pipeline workflows

### Coming Soon

- 🔄 **Streaming Support**: Handle massive datasets (Phase 3)
- 🔄 **Quality Monitoring**: Real-time quality tracking with alerts (Phase 3)
- 🔄 **Pipeline Integration**: Broadway, Flow, GenStage (Phase 3)
- 🔄 **Custom Expectations**: Build domain-specific validations (Phase 4)

## 🚀 Quick Start

### Installation

Add `ex_data_check` to your `mix.exs`:

```elixir
def deps do
  [
    {:ex_data_check, "~> 0.3.0"}
  ]
end
```

**Optional**: For Crucible framework integration, add:

```elixir
def deps do
  [
    {:ex_data_check, "~> 0.3.0"},
    {:crucible_ir, "~> 0.1.1"}  # Optional for pipeline integration
  ]
end
```

### Basic Validation

```elixir
# Import convenience functions
import ExDataCheck

# Your dataset
dataset = [
  %{age: 25, name: "Alice", email: "alice@example.com", score: 0.85},
  %{age: 30, name: "Bob", email: "bob@example.com", score: 0.92},
  %{age: 35, name: "Charlie", email: "charlie@example.com", score: 0.78}
]

# Define expectations
expectations = [
  # Schema validation
  expect_column_to_exist(:age),
  expect_column_to_be_of_type(:age, :integer),
  expect_column_count_to_equal(4),

  # Value validation
  expect_column_values_to_be_between(:age, 18, 100),
  expect_column_values_to_match_regex(:email, ~r/@/),
  expect_column_values_to_not_be_null(:name),
  expect_column_values_to_be_unique(:email),

  # Statistical validation
  expect_column_mean_to_be_between(:age, 25, 35),
  expect_column_stdev_to_be_between(:score, 0.01, 0.2),

  # ML-specific validation
  expect_table_row_count_to_be_between(2, 1000)
]

# Validate
result = ExDataCheck.validate(dataset, expectations)

if result.success do
  IO.puts("✓ All #{result.expectations_met} expectations met!")
else
  IO.puts("✗ #{result.expectations_failed} expectations failed")

  result
  |> ExDataCheck.ValidationResult.failed_expectations()
  |> Enum.each(fn failed ->
    IO.puts("  - #{failed.expectation}")
  end)
end
```

### Data Profiling

```elixir
# Basic profiling
profile = ExDataCheck.profile(dataset)

IO.inspect(profile.row_count)        # => 3
IO.inspect(profile.column_count)     # => 4
IO.inspect(profile.quality_score)    # => 1.0

# Access column statistics
age_stats = profile.columns[:age]
IO.inspect(age_stats.min)            # => 25
IO.inspect(age_stats.max)            # => 35
IO.inspect(age_stats.mean)           # => 30.0
IO.inspect(age_stats.type)           # => :integer

# Detailed profiling with outliers and correlations
detailed_profile = ExDataCheck.profile(dataset, detailed: true)
IO.inspect(detailed_profile.correlation_matrix)
IO.inspect(detailed_profile.columns[:age].outliers)
```

### Drift Detection

```elixir
# Create baseline from training data
training_data = [
  %{feature1: 25, feature2: 100},
  %{feature1: 30, feature2: 120},
  %{feature1: 35, feature2: 140}
]

baseline = ExDataCheck.create_baseline(training_data)

# Check production data for drift
production_data = [
  %{feature1: 26, feature2: 105},
  %{feature1: 31, feature2: 125}
]

drift_result = ExDataCheck.detect_drift(production_data, baseline)

if drift_result.drifted do
  IO.puts("⚠ Drift detected in columns: #{inspect(drift_result.columns_drifted)}")
  IO.inspect(drift_result.drift_scores)
else
  IO.puts("✓ No significant drift detected")
end
```

### Export Reports

```elixir
# Export profile to JSON
json = ExDataCheck.Profile.to_json(profile)
File.write!("profile.json", json)

# Export profile to Markdown
markdown = ExDataCheck.Profile.to_markdown(profile)
File.write!("profile.md", markdown)
```

### Pipeline Stage Integration (v0.3.0)

Use ExDataCheck as a stage in data processing pipelines:

```elixir
# Define your pipeline with validation stage
defmodule MyDataPipeline do
  def run(raw_data) do
    # Create context with data
    %{dataset: raw_data}
    |> validation_stage()
    |> transformation_stage()
    |> loading_stage()
  end

  defp validation_stage(context) do
    ExDataCheck.Stage.run(context, %{
      expectations: [
        ExDataCheck.expect_column_to_exist(:id),
        ExDataCheck.expect_no_missing_values(:features),
        ExDataCheck.expect_table_row_count_to_be_between(100, 1_000_000)
      ],
      profile: true,      # Include profiling
      fail_fast: true     # Raise on validation failure
    })
  end

  defp transformation_stage(context) do
    # Access validation results
    if context.data_validation.passed do
      # Transform data...
      context
    else
      raise "Data validation failed"
    end
  end

  defp loading_stage(context) do
    # Load processed data...
    context
  end
end

# Run the pipeline
result = MyDataPipeline.run(my_data)
```

**Optional Crucible Integration**: When using with the Crucible framework:

```elixir
# Add to mix.exs:
{:crucible_ir, "~> 0.1.1"}

# Use in Crucible pipeline:
stage = ExDataCheck.CrucibleIntegration.stage()

# Pipeline definition
pipeline = [
  DataLoadStage,
  ExDataCheck.CrucibleIntegration.stage(),
  ProcessingStage,
  ModelTrainingStage
]
```

## 📚 Complete Expectations Reference

### Schema Expectations (3)

```elixir
# Column must exist
expect_column_to_exist(:user_id)

# Column must be specific type
expect_column_to_be_of_type(:age, :integer)
# Supported types: :integer, :float, :string, :boolean, :atom, :list, :map

# Dataset must have specific column count
expect_column_count_to_equal(10)
```

### Value Expectations (8)

```elixir
# Values must be within range (inclusive)
expect_column_values_to_be_between(:age, 0, 120)

# Values must be in allowed set
expect_column_values_to_be_in_set(:status, ["active", "pending", "completed"])

# Values must match regex pattern
expect_column_values_to_match_regex(:email, ~r/^[^@]+@[^@]+\.[^@]+$/)

# No null values allowed
expect_column_values_to_not_be_null(:user_id)

# All values must be unique
expect_column_values_to_be_unique(:transaction_id)

# Values must be in strictly increasing order
expect_column_values_to_be_increasing(:timestamp)

# Values must be in strictly decreasing order
expect_column_values_to_be_decreasing(:temperature)

# Value lengths must be within range (strings, lists)
expect_column_value_lengths_to_be_between(:name, 2, 50)
```

### Statistical Expectations (5)

```elixir
# Mean must be within range
expect_column_mean_to_be_between(:age, 25, 45)

# Median must be within range
expect_column_median_to_be_between(:income, 40000, 60000)

# Standard deviation must be within range
expect_column_stdev_to_be_between(:score, 0.1, 0.3)

# Specific quantile must match expected value
expect_column_quantile_to_be(:age, 0.95, 65)
expect_column_quantile_to_be(:age, 0.75, 50, tolerance: 2.0)

# Values should follow normal distribution
expect_column_values_to_be_normal(:measurements)
expect_column_values_to_be_normal(:measurements, alpha: 0.01)
```

### ML-Specific Expectations (6)

```elixir
# Labels should be reasonably balanced (classification)
expect_label_balance(:target, min_ratio: 0.2)

# Number of unique labels should be in range
expect_label_cardinality(:target, min: 2, max: 10)

# Features should not be too highly correlated
expect_feature_correlation(:feature1, :feature2, max: 0.95)

# No missing values (critical for many ML algorithms)
expect_no_missing_values(:features)

# Dataset should have sufficient rows
expect_table_row_count_to_be_between(1000, 1_000_000)

# No distribution drift from baseline
baseline = ExDataCheck.create_baseline(training_data)
expect_no_data_drift(:features, baseline, threshold: 0.05)
```

## 📊 Data Profiling Guide

### Basic Profiling

```elixir
dataset = [
  %{age: 25, name: "Alice", score: 0.85},
  %{age: 30, name: "Bob", score: 0.92},
  %{age: 35, name: "Charlie", score: 0.78}
]

profile = ExDataCheck.profile(dataset)

# Access profile information
profile.row_count           # => 3
profile.column_count        # => 3
profile.quality_score       # => 1.0 (perfect - no missing values)

# Column-level statistics
profile.columns[:age]
# => %{
#   type: :integer,
#   min: 25,
#   max: 35,
#   mean: 30.0,
#   median: 30,
#   stdev: 4.08...,
#   missing: 0,
#   cardinality: 3
# }

# Missing value analysis
profile.missing_values
# => %{age: 0, name: 0, score: 0}
```

### Detailed Profiling with Outliers and Correlations

```elixir
# Enable detailed mode
detailed_profile = ExDataCheck.profile(dataset, detailed: true)

# Outlier detection (IQR method by default)
detailed_profile.columns[:age].outliers
# => %{
#   method: :iqr,
#   outliers: [100, 200],
#   outlier_count: 2,
#   q1: 25.0,
#   q3: 35.0,
#   iqr: 10.0,
#   lower_fence: -5.0,
#   upper_fence: 65.0
# }

# Use Z-score method instead
zscore_profile = ExDataCheck.profile(dataset,
  detailed: true,
  outlier_method: :zscore
)

# Correlation matrix (for numeric columns)
detailed_profile.correlation_matrix
# => %{
#   age: %{age: 1.0, score: 0.87},
#   score: %{age: 0.87, score: 1.0}
# }
```

### Export Profiles

```elixir
# JSON export
json = ExDataCheck.Profile.to_json(profile)
File.write!("data_profile.json", json)

# Markdown export
markdown = ExDataCheck.Profile.to_markdown(profile)
File.write!("data_profile.md", markdown)
```

## 🔍 Drift Detection Guide

### Creating Baselines

```elixir
# Create baseline from training data
training_data = [
  %{age: 25, income: 50000, score: 0.85},
  %{age: 30, income: 75000, score: 0.92},
  %{age: 35, income: 62000, score: 0.78}
]

baseline = ExDataCheck.create_baseline(training_data)

# Baseline captures distribution for each column
baseline[:age]
# => %{
#   type: :numeric,
#   values: [25, 30, 35],
#   mean: 30.0,
#   stdev: 4.08...
# }

# Save baseline for later use
File.write!("baseline.json", Jason.encode!(baseline))
```

### Detecting Drift

```elixir
# Load baseline
baseline = File.read!("baseline.json") |> Jason.decode!(keys: :atoms)

# Check production data for drift
production_data = [
  %{age: 45, income: 95000, score: 0.65},
  %{age: 50, income: 120000, score: 0.58}
]

drift_result = ExDataCheck.detect_drift(production_data, baseline)

drift_result.drifted                    # => true
drift_result.columns_drifted            # => [:age, :income]
drift_result.drift_scores
# => %{age: 0.23, income: 0.45, score: 0.02}
drift_result.method                     # => :auto

# Use custom threshold
strict_result = ExDataCheck.detect_drift(
  production_data,
  baseline,
  threshold: 0.01
)

# Use specific method
ks_result = ExDataCheck.detect_drift(
  production_data,
  baseline,
  method: :ks
)
```

### Drift in Expectations

```elixir
# Include drift checking in expectations
baseline = ExDataCheck.create_baseline(training_data)

expectations = [
  expect_no_data_drift(:age, baseline),
  expect_no_data_drift(:income, baseline, threshold: 0.1)
]

result = ExDataCheck.validate(production_data, expectations)
```

## 🎯 Real-World Use Cases

### Use Case 1: ML Training Data Validation

```elixir
defmodule MLPipeline.TrainingValidation do
  import ExDataCheck

  @training_expectations [
    # Schema validation
    expect_column_to_exist(:features),
    expect_column_to_exist(:labels),

    # Completeness
    expect_no_missing_values(:features),
    expect_no_missing_values(:labels),

    # Statistical properties
    expect_column_mean_to_be_between(:features, -1.0, 1.0),
    expect_column_stdev_to_be_between(:features, 0.1, 2.0),

    # ML-specific checks
    expect_label_balance(:labels, min_ratio: 0.2),
    expect_table_row_count_to_be_between(1000, 1_000_000),
    expect_label_cardinality(:labels, min: 2, max: 100)
  ]

  def validate_and_profile(training_data) do
    # Validate
    validation = ExDataCheck.validate(training_data, @training_expectations)

    unless validation.success do
      raise "Training data validation failed: #{inspect(validation.failed_expectations())}"
    end

    # Profile
    profile = ExDataCheck.profile(training_data, detailed: true)

    # Create drift baseline
    baseline = ExDataCheck.create_baseline(training_data)

    {:ok, validation, profile, baseline}
  end
end
```

### Use Case 2: Production Data Monitoring

```elixir
defmodule ProductionMonitor do
  use GenServer
  import ExDataCheck

  def init(baseline) do
    {:ok, %{baseline: baseline, batch_count: 0}}
  end

  def handle_call({:check_batch, batch}, _from, state) do
    # Quick validation
    quick_checks = [
      expect_column_to_exist(:features),
      expect_no_missing_values(:features)
    ]

    validation = ExDataCheck.validate(batch, quick_checks)

    # Drift detection
    drift = ExDataCheck.detect_drift(batch, state.baseline)

    # Profile batch
    profile = ExDataCheck.profile(batch)

    # Alert if issues detected
    if !validation.success or drift.drifted or profile.quality_score < 0.85 do
      alert_ops_team(%{
        validation: validation,
        drift: drift,
        quality: profile.quality_score,
        batch: state.batch_count
      })
    end

    # Store metrics
    store_metrics(profile, drift, state.batch_count)

    {:reply, {:ok, %{validation: validation, drift: drift}},
     %{state | batch_count: state.batch_count + 1}}
  end

  defp alert_ops_team(metrics), do: IO.puts("⚠ Alert: #{inspect(metrics)}")
  defp store_metrics(_profile, _drift, _count), do: :ok
end
```

### Use Case 3: Feature Engineering Validation

```elixir
defmodule FeatureEngineering do
  import ExDataCheck

  def validate_features(features_df) do
    expectations = [
      # No high correlation (avoid multicollinearity)
      expect_feature_correlation(:feature1, :feature2, max: 0.90),
      expect_feature_correlation(:feature1, :feature3, max: 0.90),
      expect_feature_correlation(:feature2, :feature3, max: 0.90),

      # Features should be normalized
      expect_column_mean_to_be_between(:feature1, -0.1, 0.1),
      expect_column_stdev_to_be_between(:feature1, 0.9, 1.1),

      # No missing values
      expect_no_missing_values(:feature1),
      expect_no_missing_values(:feature2),
      expect_no_missing_values(:feature3)
    ]

    result = ExDataCheck.validate(features_df, expectations)

    # Get correlation matrix for analysis
    profile = ExDataCheck.profile(features_df, detailed: true)

    {result, profile.correlation_matrix}
  end
end
```

### Use Case 4: Data Quality Dashboard

```elixir
defmodule DataQualityDashboard do
  import ExDataCheck

  def generate_quality_report(dataset) do
    # Comprehensive validation
    expectations = build_comprehensive_expectations()
    validation = ExDataCheck.validate(dataset, expectations)

    # Detailed profiling
    profile = ExDataCheck.profile(dataset, detailed: true)

    # Generate reports
    %{
      validation_report: format_validation(validation),
      profile_report: ExDataCheck.Profile.to_markdown(profile),
      quality_score: profile.quality_score,
      summary: %{
        total_rows: profile.row_count,
        total_columns: profile.column_count,
        expectations_met: validation.expectations_met,
        expectations_failed: validation.expectations_failed,
        missing_values: calculate_total_missing(profile.missing_values)
      }
    }
  end

  defp build_comprehensive_expectations do
    [
      # Schema
      expect_column_to_exist(:id),
      expect_column_to_exist(:timestamp),

      # Values
      expect_column_values_to_be_unique(:id),
      expect_column_values_to_not_be_null(:id),

      # Statistics
      expect_column_mean_to_be_between(:value, 0, 100)
    ]
  end

  defp format_validation(validation) do
    # Format for display
    %{
      success: validation.success,
      total: validation.total_expectations,
      passed: validation.expectations_met,
      failed: validation.expectations_failed
    }
  end

  defp calculate_total_missing(missing_map) do
    Map.values(missing_map) |> Enum.sum()
  end
end
```

### Use Case 5: Temporal Event Streams

```elixir
import ExDataCheck

expectations = [
  expect_column_values_to_be_valid_timestamps(:event_time),
  expect_column_timestamps_to_be_chronological(:event_time, strict: true),
  expect_column_timestamps_to_be_within_range(:event_time, min_time, max_time),
  expect_column_timestamp_intervals_to_be_regular(:event_time, expected_interval: {1, :minute})
]

result = ExDataCheck.validate(events, expectations)
```

### Use Case 6: Contact Data with Composite Logic

```elixir
import ExDataCheck

expectations = [
  # Either email or phone must be valid
  expect_any([
    expect_column_values_to_be_valid_emails(:contact),
    expect_column_values_to_match_format(:contact, :us_phone)
  ]),
  # Require HTTPS URLs and proper UUIDs
  expect_column_values_to_be_valid_urls(:profile_url, schemes: [:https]),
  expect_column_values_to_be_valid_uuids(:user_id, version: 4)
]

result = ExDataCheck.validate(users, expectations)
```

## 📖 Comprehensive API Reference

### Main API Functions

#### Validation

```elixir
# Validate dataset against expectations
@spec validate(dataset, expectations) :: ValidationResult.t()
result = ExDataCheck.validate(dataset, expectations)

# Validate and raise on failure
@spec validate!(dataset, expectations) :: ValidationResult.t() | no_return()
result = ExDataCheck.validate!(dataset, expectations)
```

#### Profiling

```elixir
# Basic profiling
@spec profile(dataset) :: Profile.t()
profile = ExDataCheck.profile(dataset)

# Detailed profiling with outliers and correlations
@spec profile(dataset, opts) :: Profile.t()
profile = ExDataCheck.profile(dataset,
  detailed: true,
  outlier_method: :iqr  # or :zscore
)
```

#### Drift Detection

```elixir
# Create baseline from reference data
@spec create_baseline(dataset) :: baseline()
baseline = ExDataCheck.create_baseline(training_data)

# Detect drift
@spec detect_drift(dataset, baseline, opts) :: DriftResult.t()
drift = ExDataCheck.detect_drift(production_data, baseline, threshold: 0.05)

#### Expectation Helpers (new categories)

```elixir
# Temporal
expect_column_values_to_be_valid_timestamps(:created_at)
expect_column_timestamps_to_be_chronological(:event_time, strict: true)
expect_column_timestamps_to_be_within_range(:timestamp, min_dt, max_dt)
expect_column_timestamp_intervals_to_be_regular(:timestamp, expected_interval: {1, :hour})

# String
expect_column_values_to_be_valid_emails(:email)
expect_column_values_to_be_valid_urls(:website, schemes: [:https])
expect_column_values_to_be_valid_uuids(:id, version: 4)
expect_column_values_to_match_format(:ip, :ip_address)
expect_column_string_length_distribution(:name, mean_length: {3, 15}, max_length: 50)

# Composite
expect_all([expect_column_to_exist(:id), expect_column_values_to_be_unique(:id)])
expect_any([
  expect_column_values_to_be_valid_emails(:contact),
  expect_column_values_to_match_format(:contact, :us_phone)
])
expect_at_least(2, [
  expect_column_values_to_not_be_null(:name),
  expect_column_values_to_be_valid_urls(:profile_url, schemes: [:https]),
  expect_column_values_to_be_valid_emails(:email)
])
```
```

### Result Structures

#### ValidationResult

```elixir
%ExDataCheck.ValidationResult{
  success: boolean(),
  total_expectations: integer(),
  expectations_met: integer(),
  expectations_failed: integer(),
  results: [ExpectationResult.t()],
  dataset_info: map(),
  timestamp: DateTime.t()
}

# Helper functions
ValidationResult.success?(result)              # => boolean()
ValidationResult.failed?(result)               # => boolean()
ValidationResult.failed_expectations(result)   # => [ExpectationResult.t()]
ValidationResult.passed_expectations(result)   # => [ExpectationResult.t()]
```

#### Profile

```elixir
%ExDataCheck.Profile{
  row_count: integer(),
  column_count: integer(),
  columns: %{column_name => column_profile},
  missing_values: %{column_name => count},
  quality_score: float(),
  correlation_matrix: map(),  # if detailed: true
  timestamp: DateTime.t()
}

# Export functions
Profile.to_json(profile)      # => json_string
Profile.to_markdown(profile)  # => markdown_string
Profile.quality_score(profile) # => float()
```

#### DriftResult

```elixir
%ExDataCheck.DriftResult{
  drifted: boolean(),
  columns_drifted: [column_name],
  drift_scores: %{column_name => float()},
  method: atom(),
  threshold: float()
}
```

## 🏗️ Architecture & Module Structure

### Current Module Organization (v0.2.1)

```
lib/ex_data_check/
├── ex_data_check.ex                 # Main API with convenience functions
├── expectation.ex                   # Core expectation struct
├── expectation_result.ex            # Individual expectation results
├── validation_result.ex             # Aggregated validation results
├── validation_error.ex              # Exception for validate!/2
├── profile.ex                       # Data profiling results
├── statistics.ex                    # Statistical utilities
├── correlation.ex                   # Correlation analysis
├── drift.ex                         # Drift detection
├── drift_result.ex                  # Drift detection results
├── outliers.ex                      # Outlier detection
├── validator/
│   └── column_extractor.ex          # Column extraction utilities
└── expectations/
    ├── schema.ex                    # Schema expectations (3)
    ├── value.ex                     # Value expectations (8)
    ├── statistical.ex               # Statistical expectations (5)
    ├── ml.ex                        # ML expectations (6)
    ├── temporal.ex                  # Temporal expectations (4)       # NEW
    ├── string.ex                    # String/format expectations (5)  # NEW
    └── composite.ex                 # Logical composition (3)         # NEW
```

### Test Organization

```
test/
├── ex_data_check_test.exs              # Doctests
├── ex_data_check_integration_test.exs  # Integration tests
├── expectation_test.exs                # Core struct tests
├── expectation_result_test.exs         # Result struct tests
├── validation_result_test.exs          # Validation results
├── profile_test.exs                    # Profiling tests
├── profiling_integration_test.exs      # Profiling integration
├── statistics_test.exs                 # Statistics utilities
├── correlation_test.exs                # Correlation analysis
├── drift_test.exs                      # Drift detection
├── outliers_test.exs                   # Outlier detection
├── validator/
│   └── column_extractor_test.exs       # Column extraction
├── expectations/
│   ├── schema_test.exs                 # Schema expectations
│   ├── value_test.exs                  # Value expectations
│   ├── statistical_test.exs            # Statistical expectations
│   ├── ml_test.exs                     # ML expectations
│   ├── temporal_test.exs               # Temporal expectations
│   ├── string_test.exs                 # String/format expectations
│   └── composite_test.exs              # Composite expectations
└── support/
    └── generators.ex                   # Property-based test generators
```

## 🧪 Testing

### Run Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test test/expectations/value_test.exs

# Run with coverage
mix test --cover

# Watch mode (with mix_test_watch)
mix test.watch
```

### Test Statistics (v0.2.1)

```
✅ 314 Tests Passing
   - 4 Doctests
   - 25 Property-based tests
   - 244 Unit/Integration tests

✅ >90% Code Coverage
✅ Zero Warnings
✅ All Tests Async-Safe
```

### Quality Gates

All code passes:
- ✅ `mix compile --warnings-as-errors`
- ✅ `mix test` (all pass)
- ✅ `mix format --check-formatted`
- ✅ Property-based tests for mathematical correctness

## 🎯 Design Principles

### 1. Declarative Expectations

Express data requirements as clear, testable expectations rather than imperative validation logic.

```elixir
# Declarative ✓
expectations = [
  expect_column_values_to_be_between(:age, 0, 120),
  expect_no_missing_values(:email)
]

# vs Imperative ✗
def validate_age(dataset) do
  Enum.all?(dataset, fn row ->
    age = row[:age]
    age != nil and age >= 0 and age <= 120
  end)
end
```

### 2. Fail Fast (Optional)

Catch data quality issues early, but collect all errors by default for comprehensive reporting.

```elixir
# Collect all failures (default)
result = ExDataCheck.validate(data, expectations)
result.expectations_failed  # Shows all failures

# Fail fast (raise on first failure)
ExDataCheck.validate!(data, expectations)
```

### 3. Comprehensive Metrics

Track data quality across multiple dimensions with detailed diagnostics.

### 4. ML-Aware

Built specifically for ML use cases with drift detection, label balance, correlation analysis.

### 5. Production Ready

- Zero warnings in compilation
- Comprehensive error handling
- Extensive test coverage
- Proper resource management

### 6. Observable

All operations emit telemetry events for monitoring and debugging (Phase 3).

## 📈 Performance

### Current Performance (v0.2.1)

**Batch Validation**:
- ~10,000 rows/second on typical hardware
- Memory usage proportional to dataset size
- Parallel expectation execution (future)

**Profiling**:
- < 1 second for 10,000 rows
- < 5 seconds for 100,000 rows
- Detailed profiling adds ~20% overhead

**Drift Detection**:
- KS test: O(n log n) complexity
- PSI: O(n) complexity
- Baseline creation: One-time cost

### Performance Tips

```elixir
# For large datasets, sample for profiling
profile = ExDataCheck.profile(
  large_dataset,
  sample_size: 10_000
)

# For repeated validations, cache expectations
@expectations [
  expect_column_to_exist(:id),
  # ...
]

def validate(data), do: ExDataCheck.validate(data, @expectations)
```

## 🗺️ Roadmap

### ✅ Phase 1: Core Validation (v0.1.0) - **COMPLETE**

- Core validation framework
- 11 expectations (schema + value)
- Basic profiling and statistics
- JSON/Markdown export
- **Released**: October 20, 2025

### ✅ Phase 2: ML Features (v0.2.0) - **COMPLETE**

- 11 additional expectations (statistical + ML)
- Drift detection (KS test, PSI)
- Advanced profiling (outliers, correlations)
- Correlation analysis (Pearson, Spearman)
- **Released**: October 20, 2025

### 🔄 Phase 3: Production Features (v0.3.0) - **PLANNED**

**Weeks 9-12** | Target: Q1 2026

- **Streaming Support**: Handle datasets of any size
- **Quality Monitoring**: Real-time quality tracking with alerts
- **Pipeline Integration**: Broadway, Flow, GenStage
- **Rich Reporting**: HTML dashboards, visualization data

### 🔄 Phase 4: Enterprise & Advanced (v0.4.0) - **PLANNED**

**Weeks 13-16** | Target: Q2 2026

- **Custom Expectations**: Framework for domain-specific validations
- **Suite Management**: Versioned, reusable expectation libraries
- **Multi-Dataset Validation**: Cross-dataset consistency checking
- **Performance Optimization**: Caching, parallel execution, benchmarks

See [docs/20251020/future_vision_phase3_4.md](docs/20251020/future_vision_phase3_4.md) for detailed Phase 3 & 4 plans.

## 🤝 Contributing

ExDataCheck is part of the **North Shore AI Research Infrastructure**. Contributions are welcome!

### Development Setup

```bash
git clone https://github.com/North-Shore-AI/ExDataCheck.git
cd ExDataCheck
mix deps.get
mix test
```

### Contribution Guidelines

1. **Follow TDD**: Write tests first (Red-Green-Refactor)
2. **Maintain Coverage**: Keep >90% test coverage
3. **Zero Warnings**: Code must compile cleanly
4. **Document Everything**: All public functions need @doc and @spec
5. **Property Test**: Use StreamData for mathematical functions
6. **Format Code**: Run `mix format` before committing

### Areas for Contribution

- New expectations (statistical, domain-specific)
- Performance optimizations
- Documentation improvements
- Example use cases
- Integration packages (Broadway, Ecto, Explorer)

## 📝 Documentation

- **[API Reference](https://hexdocs.pm/ex_data_check)** - Complete function documentation
- **[Architecture Guide](docs/architecture.md)** - System design and components
- **[Expectations Guide](docs/expectations.md)** - Creating and using expectations
- **[Roadmap](docs/roadmap.md)** - Implementation roadmap and timeline
- **[Future Vision](docs/20251020/future_vision_phase3_4.md)** - Phase 3 & 4 plans
- **[Changelog](CHANGELOG.md)** - Version history and changes

## 🏆 Project Stats (v0.3.0)

```
📊 Tests: 340+ passing (includes pipeline stage integration tests)
🎯 Expectations: 34 (3 schema + 8 value + 5 statistical + 6 ML + 4 temporal + 5 string + 3 composite)
📁 Modules: 24 (includes Stage and CrucibleIntegration)
📝 Lines of Code: ~8,000
📈 Test Coverage: >90%
⚡ Performance: ~10k rows/second
🐛 Warnings: 0
✅ Production Ready: Yes
🔌 Pipeline Integration: Yes (v0.3.0)
```

## 🔬 Technical Details

### Dependencies

```elixir
# Runtime
{:jason, "~> 1.4"}  # JSON encoding/decoding

# Optional
{:crucible_ir, "~> 0.1.1", optional: true}  # Crucible framework integration

# Development/Test
{:ex_doc, "~> 0.31", only: :dev, runtime: false}
{:stream_data, "~> 1.1", only: :test}
```

### Requirements

- **Elixir**: ~> 1.14
- **OTP**: >= 25
- **Erlang**: >= 25

### Supported Data Formats

- Lists of maps (atom or string keys)
- Keyword lists
- Streams (future)
- Explorer DataFrames (future integration)
- Nx tensors (future integration)

## 💡 Examples

### Complete ML Pipeline Example

```elixir
defmodule CompleteMLPipeline do
  import ExDataCheck

  def run do
    # 1. Load and validate raw data
    raw_data = load_raw_data()

    validate_raw_data(raw_data)

    # 2. Profile data
    profile = ExDataCheck.profile(raw_data, detailed: true)
    save_profile(profile, "raw_data_profile.json")

    # 3. Engineer features
    features = engineer_features(raw_data)

    # 4. Validate features
    validate_features(features)

    # 5. Create baseline for monitoring
    baseline = ExDataCheck.create_baseline(features)
    save_baseline(baseline, "feature_baseline.json")

    # 6. Train model
    model = train_model(features)

    {:ok, model, baseline}
  end

  defp validate_raw_data(data) do
    expectations = [
      expect_column_to_exist(:user_id),
      expect_column_to_exist(:timestamp),
      expect_column_values_to_not_be_null(:user_id),
      expect_column_values_to_be_unique(:user_id)
    ]

    ExDataCheck.validate!(data, expectations)
  end

  defp validate_features(features) do
    expectations = [
      expect_no_missing_values(:features),
      expect_column_mean_to_be_between(:feature1, -0.5, 0.5),
      expect_column_stdev_to_be_between(:feature1, 0.8, 1.2),
      expect_feature_correlation(:feature1, :feature2, max: 0.95),
      expect_label_balance(:target, min_ratio: 0.15),
      expect_table_row_count_to_be_between(1000, 1_000_000)
    ]

    ExDataCheck.validate!(features, expectations)
  end

  defp load_raw_data, do: []
  defp engineer_features(_data), do: []
  defp train_model(_features), do: nil
  defp save_profile(_profile, _path), do: :ok
  defp save_baseline(_baseline, _path), do: :ok
end
```

## 🎓 Learning Resources

### Tutorials

1. **Getting Started** - Quick introduction to ExDataCheck
2. **Building Expectations** - Creating effective data quality checks
3. **Profiling Deep Dive** - Understanding your data with profiles
4. **Drift Detection** - Monitoring model performance over time
5. **Production Deployment** - Best practices for production use

### Working Examples

The `examples/` directory contains fully functional, runnable examples demonstrating ExDataCheck capabilities:

#### Run Examples

```bash
mix run examples/basic_validation.exs
mix run examples/data_profiling.exs
mix run examples/drift_detection.exs
mix run examples/ml_pipeline.exs
```

#### Available Examples

1. **basic_validation.exs** - Core validation with schema and value expectations
   - Type checking, value ranges, regex patterns
   - Handling validation failures and success cases
   - Using `validate!` for fail-fast behavior

2. **data_profiling.exs** - Comprehensive data profiling and analysis
   - Basic and detailed profiling modes
   - Outlier detection (IQR and Z-score methods)
   - Correlation matrix generation
   - Export to JSON and Markdown

3. **drift_detection.exs** - Distribution drift monitoring for ML models
   - Creating baselines from training data
   - Detecting drift in production data
   - Custom threshold configuration
   - Integration with validation expectations

4. **ml_pipeline.exs** - Complete end-to-end ML data quality pipeline
   - Raw data validation
   - Feature engineering validation
   - Training data quality checks
   - Production monitoring and drift detection

See [examples/README.md](examples/README.md) for detailed descriptions and patterns.

## 🐛 Troubleshooting

### Common Issues

**Issue**: Validation is slow for large datasets
**Solution**: Use sampling for profiling, or wait for Phase 3 streaming support

**Issue**: Too many false positives in drift detection
**Solution**: Adjust threshold: `detect_drift(data, baseline, threshold: 0.1)`

**Issue**: Expectations failing unexpectedly
**Solution**: Profile your data first to understand actual distributions

### Getting Help

- **Issues**: [GitHub Issues](https://github.com/North-Shore-AI/ExDataCheck/issues)
- **Discussions**: [GitHub Discussions](https://github.com/North-Shore-AI/ExDataCheck/discussions)
- **Email**: support@northshore.ai

## 📄 License

MIT License - see LICENSE file for details.

Copyright (c) 2025 North Shore AI

## 🙏 Acknowledgments

- **Great Expectations** (Python) - Inspiration for expectations-based validation
- **Elixir Community** - For the amazing ecosystem
- **North Shore AI** - For supporting open source research infrastructure

## 🔗 Related Projects

- **[crucible_bench](https://github.com/North-Shore-AI/crucible_bench)** - Statistical testing framework for AI research
- **Great Expectations** - Python data validation library (inspiration)
- **Nx** - Numerical computing for Elixir
- **Explorer** - DataFrames for Elixir
- **Broadway** - Data ingestion and processing pipelines

## 📊 Project Status

**Current Version**: v0.3.0
**Status**: Production Ready ✅
**Maturity**: Early Adopter Phase
**Maintenance**: Actively Developed
**Next Release**: v0.4.0 (Q1 2026)

---

<p align="center">
  <strong>Built with ❤️ by North Shore AI</strong>
  <br>
  <em>Making ML pipelines reliable, one expectation at a time</em>
</p>

<p align="center">
  <a href="https://github.com/North-Shore-AI/ExDataCheck">GitHub</a> •
  <a href="https://hexdocs.pm/ex_data_check">Documentation</a> •
  <a href="CHANGELOG.md">Changelog</a> •
  <a href="docs/20251020/future_vision_phase3_4.md">Future Vision</a>
</p>
### New in v0.2.1

- ⏱️ **Temporal expectations**: validate timestamps, ordering, ranges, and regular intervals
- 🔤 **String expectations**: validate emails, URLs (with scheme/TLD controls), UUIDs (with version), common formats, and length distributions
- 🔗 **Composite expectations**: AND/OR/threshold logic with `expect_all/1`, `expect_any/1`, `expect_at_least/2`
