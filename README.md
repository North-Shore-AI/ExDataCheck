<p align="center">
  <img src="assets/ExDataCheck.svg" alt="ExDataCheck" width="150"/>
</p>

# ExDataCheck

**Data Validation and Quality Library for ML Pipelines**

[![Elixir](https://img.shields.io/badge/elixir-1.14+-purple.svg)](https://elixir-lang.org)
[![OTP](https://img.shields.io/badge/otp-25+-red.svg)](https://www.erlang.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/North-Shore-AI/ExDataCheck/blob/main/LICENSE)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blueviolet.svg)](https://hexdocs.pm/ex_data_check)

---

A comprehensive data validation and quality assessment library for Elixir, specifically designed for machine learning workflows. ExDataCheck provides Great Expectations-style validation, data profiling, schema validation, and quality metrics to ensure your ML pipelines work with high-quality data.

## Features

- **Expectations-Based Validation**: Define declarative expectations about your data (inspired by Great Expectations)
- **Data Profiling**: Automatic statistical profiling and data characterization
- **Schema Validation**: Type checking, structure validation, and schema enforcement
- **Quality Metrics**: Comprehensive data quality scoring and reporting
- **ML-Specific Checks**: Feature distributions, data drift detection, label imbalance
- **Pipeline Integration**: Seamlessly integrate into ETL and ML pipelines
- **Streaming Support**: Validate data in real-time as it flows through your pipeline
- **Rich Reporting**: Generate detailed validation reports in multiple formats

## Design Principles

1. **Declarative Expectations**: Express data requirements as clear, testable expectations
2. **Fail Fast**: Catch data quality issues early in the pipeline
3. **Comprehensive Metrics**: Track data quality across multiple dimensions
4. **ML-Aware**: Built specifically for machine learning use cases
5. **Production Ready**: Designed for high-throughput production environments
6. **Observable**: Rich logging and reporting for data quality monitoring

## Installation

Add `ex_data_check` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_data_check, "~> 0.1.0"}
  ]
end
```

Or install from GitHub:

```elixir
def deps do
  [
    {:ex_data_check, github: "North-Shore-AI/ExDataCheck"}
  ]
end
```

## Quick Start

### Basic Expectations

```elixir
# Define expectations for a dataset
dataset = [
  %{age: 25, income: 50000, score: 0.85},
  %{age: 32, income: 75000, score: 0.92},
  %{age: 28, income: 62000, score: 0.78}
]

expectations = [
  expect_column_values_to_be_between(:age, 18, 100),
  expect_column_values_to_be_of_type(:income, :integer),
  expect_column_values_to_be_in_range(:score, 0.0, 1.0),
  expect_column_to_exist(:age),
  expect_no_missing_values(:income)
]

result = ExDataCheck.validate(dataset, expectations)
# => %ExDataCheck.ValidationResult{
#   success: true,
#   expectations_met: 5,
#   expectations_failed: 0,
#   details: [...]
# }
```

### Data Profiling

```elixir
# Profile your dataset to understand its characteristics
profile = ExDataCheck.profile(dataset)
# => %ExDataCheck.Profile{
#   row_count: 3,
#   column_count: 3,
#   columns: %{
#     age: %{type: :integer, min: 25, max: 32, mean: 28.33, ...},
#     income: %{type: :integer, min: 50000, max: 75000, ...},
#     score: %{type: :float, min: 0.78, max: 0.92, ...}
#   },
#   missing_values: %{},
#   quality_score: 0.98
# }
```

### Schema Validation

```elixir
# Define and enforce schemas
schema = ExDataCheck.Schema.new([
  {:age, :integer, required: true, min: 0, max: 150},
  {:income, :integer, required: true, min: 0},
  {:score, :float, required: true, min: 0.0, max: 1.0},
  {:name, :string, required: false}
])

{:ok, validated_data} = ExDataCheck.validate_schema(dataset, schema)
```

### Quality Metrics

```elixir
# Calculate comprehensive quality metrics
metrics = ExDataCheck.quality_metrics(dataset)
# => %ExDataCheck.QualityMetrics{
#   completeness: 1.0,        # No missing values
#   validity: 0.98,           # 98% of values pass constraints
#   consistency: 0.95,        # Cross-column consistency
#   accuracy: 0.92,           # Estimated accuracy (if ground truth available)
#   timeliness: 1.0,          # Data freshness
#   overall_score: 0.97
# }
```

## Expectations Reference

### Value Expectations

```elixir
# Column values must be between min and max
expect_column_values_to_be_between(:age, 0, 120)

# Column values must be in a set
expect_column_values_to_be_in_set(:country, ["US", "UK", "CA"])

# Column values must match a regex
expect_column_values_to_match_regex(:email, ~r/@/)

# Column values must not be null
expect_column_values_to_not_be_null(:user_id)

# Column values must be unique
expect_column_values_to_be_unique(:transaction_id)
```

### Statistical Expectations

```elixir
# Column mean should be approximately a value
expect_column_mean_to_be_between(:age, 25, 35)

# Column standard deviation
expect_column_stdev_to_be_between(:score, 0.1, 0.3)

# Column median
expect_column_median_to_be_between(:income, 40000, 60000)

# Percentile checks
expect_column_quantile_to_be(:age, 0.95, 65)
```

### ML-Specific Expectations

```elixir
# Feature distribution checks
expect_feature_distribution(:age, :normal, mean: 30, stdev: 10)

# Label balance
expect_label_balance(:class, min_ratio: 0.3)

# Feature correlation
expect_feature_correlation(:feature_a, :feature_b, max: 0.9)

# Data drift detection
expect_no_data_drift(:features, reference_distribution)
```

### Schema Expectations

```elixir
# Column must exist
expect_column_to_exist(:user_id)

# Column type check
expect_column_to_be_of_type(:age, :integer)

# Number of columns
expect_column_count_to_equal(10)

# Table row count
expect_table_row_count_to_be_between(1000, 10000)
```

## Data Profiling

ExDataCheck provides comprehensive data profiling capabilities:

```elixir
# Generate a full profile
profile = ExDataCheck.profile(dataset, detailed: true)

# Profile includes:
# - Column types and cardinality
# - Statistical summaries (min, max, mean, median, stdev)
# - Missing value analysis
# - Distribution analysis
# - Correlation matrix
# - Outlier detection
# - Data quality score

# Export profile to various formats
ExDataCheck.Profile.to_json(profile)
ExDataCheck.Profile.to_html(profile)
ExDataCheck.Profile.to_markdown(profile)
```

## Schema Validation

Define strict schemas for your data:

```elixir
schema = ExDataCheck.Schema.new([
  # Column name, type, options
  {:user_id, :integer, required: true, unique: true},
  {:email, :string, required: true, format: ~r/@/},
  {:age, :integer, required: true, min: 18, max: 100},
  {:score, :float, required: true, min: 0.0, max: 1.0},
  {:tags, {:list, :string}, required: false},
  {:metadata, :map, required: false}
])

# Validate entire dataset
case ExDataCheck.validate_schema(dataset, schema) do
  {:ok, validated_data} ->
    # All data passes schema validation
    process_data(validated_data)

  {:error, validation_errors} ->
    # Handle validation errors
    log_errors(validation_errors)
end
```

## Pipeline Integration

Integrate ExDataCheck into your ML pipelines:

```elixir
defmodule MyMLPipeline do
  use ExDataCheck.Pipeline

  def run(data) do
    data
    |> validate_with([
      expect_column_to_exist(:features),
      expect_column_to_exist(:labels),
      expect_no_missing_values(:features),
      expect_label_balance(:labels, min_ratio: 0.2)
    ])
    |> profile(store: :pipeline_metrics)
    |> transform()
    |> validate_output([
      expect_column_count_to_equal(10),
      expect_table_row_count_to_be_between(100, 10000)
    ])
  end

  defp transform(validated_data) do
    # Your transformation logic
    validated_data
  end
end
```

## Quality Monitoring

Track data quality over time:

```elixir
# Initialize quality monitor
monitor = ExDataCheck.Monitor.new()

# Add quality checks
monitor
|> ExDataCheck.Monitor.add_check(:completeness, threshold: 0.95)
|> ExDataCheck.Monitor.add_check(:validity, threshold: 0.90)
|> ExDataCheck.Monitor.add_check(:consistency, threshold: 0.85)

# Run checks on batches
result = ExDataCheck.Monitor.check(monitor, batch_data)

# Alert on quality degradation
if result.overall_score < 0.90 do
  alert_quality_issue(result)
end
```

## Data Drift Detection

Detect when your data distribution changes:

```elixir
# Establish baseline
baseline = ExDataCheck.Drift.create_baseline(training_data)

# Check for drift in production data
drift_result = ExDataCheck.Drift.detect(production_data, baseline)

# => %ExDataCheck.DriftResult{
#   drifted: true,
#   columns_drifted: [:age, :income],
#   drift_scores: %{age: 0.23, income: 0.45, score: 0.02},
#   method: :kolmogorov_smirnov
# }

if drift_result.drifted do
  notify_team("Data drift detected in columns: #{inspect(drift_result.columns_drifted)}")
  trigger_retraining()
end
```

## Reporting

Generate comprehensive validation reports:

```elixir
result = ExDataCheck.validate(dataset, expectations)

# Markdown report
markdown = ExDataCheck.Report.to_markdown(result)
File.write!("validation_report.md", markdown)

# HTML report
html = ExDataCheck.Report.to_html(result, template: :detailed)
File.write!("validation_report.html", html)

# JSON export
json = ExDataCheck.Report.to_json(result)
send_to_monitoring_system(json)
```

## Module Structure

```
lib/ex_data_check/
├── ex_data_check.ex              # Main API
├── validation_result.ex          # Result structs
├── expectation.ex                # Expectation definitions
├── profile.ex                    # Data profiling
├── schema.ex                     # Schema validation
├── quality_metrics.ex            # Quality scoring
├── pipeline.ex                   # Pipeline integration
├── monitor.ex                    # Quality monitoring
├── drift.ex                      # Drift detection
├── report.ex                     # Reporting/export
└── expectations/
    ├── value.ex                  # Value-based expectations
    ├── statistical.ex            # Statistical expectations
    ├── schema.ex                 # Schema expectations
    ├── ml.ex                     # ML-specific expectations
    └── custom.ex                 # Custom expectation framework
```

## Use Cases

### Data Pipeline Validation

```elixir
# Validate data as it enters your pipeline
defmodule DataIngestion do
  def process(raw_data) do
    expectations = [
      expect_column_to_exist(:timestamp),
      expect_column_to_exist(:user_id),
      expect_column_values_to_not_be_null(:user_id),
      expect_column_values_to_match_regex(:email, ~r/@/)
    ]

    case ExDataCheck.validate(raw_data, expectations) do
      %{success: true} = result ->
        {:ok, raw_data}

      %{success: false} = result ->
        Logger.error("Data validation failed: #{inspect(result.details)}")
        {:error, result}
    end
  end
end
```

### ML Feature Validation

```elixir
# Validate features before training
defmodule ModelTraining do
  def prepare_features(data) do
    expectations = [
      expect_no_missing_values(:features),
      expect_column_mean_to_be_between(:feature_1, 0.0, 1.0),
      expect_feature_correlation(:feature_1, :feature_2, max: 0.95),
      expect_label_balance(:target, min_ratio: 0.2),
      expect_table_row_count_to_be_between(1000, 1_000_000)
    ]

    ExDataCheck.validate!(data, expectations)
  end
end
```

### Production Monitoring

```elixir
# Monitor production data quality
defmodule ProductionMonitor do
  use GenServer

  def check_batch(batch) do
    profile = ExDataCheck.profile(batch)
    metrics = ExDataCheck.quality_metrics(batch)

    if metrics.overall_score < 0.85 do
      alert_ops_team(metrics)
    end

    store_metrics(profile, metrics)
  end
end
```

## Best Practices

### 1. Define Expectations Early

Define your data expectations during development:

```elixir
# Create expectation suites for different stages
training_expectations = [
  expect_no_missing_values(:features),
  expect_label_balance(:target, min_ratio: 0.3)
]

inference_expectations = [
  expect_column_to_exist(:features),
  expect_column_count_to_equal(10)
]
```

### 2. Use Profiling for Exploration

Profile your data to understand it before writing expectations:

```elixir
profile = ExDataCheck.profile(data, detailed: true)
IO.inspect(profile.columns, label: "Column Statistics")
```

### 3. Monitor Quality Trends

Track quality metrics over time:

```elixir
metrics = ExDataCheck.quality_metrics(batch)
store_in_timeseries_db(metrics, timestamp: DateTime.utc_now())
```

### 4. Handle Validation Failures Gracefully

```elixir
case ExDataCheck.validate(data, expectations) do
  %{success: true} ->
    process_data(data)

  %{success: false, details: details} ->
    # Log failures
    Logger.warn("Validation failures: #{inspect(details)}")

    # Decide on action: reject, quarantine, or continue with warnings
    quarantine_data(data, details)
end
```

## Testing

Run the test suite:

```bash
mix test
```

Run specific tests:

```bash
mix test test/ex_data_check_test.exs
mix test test/expectations_test.exs
mix test test/profile_test.exs
```

## Performance

ExDataCheck is designed for high-throughput production use:

- Stream-based processing for large datasets
- Lazy evaluation of expectations
- Configurable sampling for profiling
- Minimal memory overhead

```elixir
# Process large datasets efficiently
large_dataset
|> Stream.chunk_every(1000)
|> Stream.map(&ExDataCheck.validate(&1, expectations))
|> Enum.reduce(%{}, &aggregate_results/2)
```

## Roadmap

See [docs/roadmap.md](docs/roadmap.md) for the complete implementation roadmap.

### Phase 1: Core Validation (Current)
- Basic expectations framework
- Schema validation
- Simple profiling

### Phase 2: ML Features
- Data drift detection
- Feature correlation analysis
- Distribution comparison

### Phase 3: Advanced Monitoring
- Quality trend analysis
- Anomaly detection
- Real-time alerting

### Phase 4: Enterprise Features
- Multi-dataset validation
- Expectation versioning
- Advanced reporting

## Contributing

This is part of the North Shore AI Research Infrastructure. Contributions are welcome!

Please ensure all tests pass and code follows the project style guide.

## License

MIT License - see [LICENSE](https://github.com/North-Shore-AI/ExDataCheck/blob/main/LICENSE) file for details

## Related Projects

- [crucible_bench](https://github.com/North-Shore-AI/crucible_bench) - Statistical testing framework for AI research
- Great Expectations (Python) - Inspiration for expectations-based validation
