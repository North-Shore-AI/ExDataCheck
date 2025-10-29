# ExDataCheck Examples

This directory contains working examples demonstrating the capabilities of ExDataCheck for data validation, profiling, and drift detection in ML pipelines.

## Running Examples

All examples can be run directly using `mix run`:

```bash
# From the project root directory
mix run examples/basic_validation.exs
mix run examples/data_profiling.exs
mix run examples/drift_detection.exs
mix run examples/ml_pipeline.exs
```

## Example Descriptions

### 1. basic_validation.exs

**What it demonstrates:**
- Basic data validation with schema and value expectations
- Type checking and business rule validation
- Handling validation failures gracefully
- Using `validate!` for fail-fast behavior

**Key features shown:**
- `expect_column_to_exist/1`
- `expect_column_to_be_of_type/2`
- `expect_column_values_to_be_between/3`
- `expect_column_values_to_match_regex/2`
- `expect_column_values_to_be_unique/1`
- `expect_column_mean_to_be_between/3`

**Use case:**
Validating incoming data from APIs, databases, or CSV files before processing.

### 2. data_profiling.exs

**What it demonstrates:**
- Basic and detailed data profiling
- Statistical analysis of numeric and categorical columns
- Outlier detection using IQR and Z-score methods
- Correlation matrix generation
- Exporting profiles to JSON and Markdown
- Performance with larger datasets (1000+ rows)

**Key features shown:**
- `ExDataCheck.profile/1` - Basic profiling
- `ExDataCheck.profile/2` - Detailed profiling with options
- `Profile.to_json/1` - Export to JSON
- `Profile.to_markdown/1` - Export to Markdown
- Outlier detection with `:iqr` and `:zscore` methods
- Correlation matrix for numeric features

**Use case:**
Exploratory data analysis, data quality dashboards, and understanding dataset characteristics.

### 3. drift_detection.exs

**What it demonstrates:**
- Creating baselines from training data
- Detecting distribution drift in production data
- Multiple drift scenarios (no drift, moderate, significant)
- Custom threshold configuration
- Using drift detection in validation expectations
- Production monitoring pipeline simulation

**Key features shown:**
- `ExDataCheck.create_baseline/1`
- `ExDataCheck.detect_drift/2`
- `expect_no_data_drift/3`
- Custom thresholds for drift sensitivity
- Kolmogorov-Smirnov (KS) test for numeric features
- Population Stability Index (PSI) for categorical features

**Use case:**
Monitoring ML model inputs for distribution changes that might degrade model performance.

### 4. ml_pipeline.exs

**What it demonstrates:**
- Complete end-to-end ML data quality pipeline
- Validation at each pipeline stage
- Feature engineering validation
- Training data quality checks
- Baseline creation and production monitoring
- Comprehensive data quality reporting

**Pipeline stages:**
1. **Raw Data Validation** - Schema, types, and business rules
2. **Data Profiling** - Quality assessment and outlier detection
3. **Feature Engineering** - Derived feature validation
4. **Training Validation** - Label balance, feature quality, sufficient data
5. **Baseline Creation** - Capture training distribution
6. **Production Monitoring** - Ongoing validation and drift detection

**Key features shown:**
- `expect_label_balance/2` - Classification label distribution
- `expect_feature_correlation/3` - Avoid multicollinearity
- `expect_no_missing_values/1` - Data completeness
- `expect_table_row_count_to_be_between/2` - Dataset size validation
- Integration of all ExDataCheck capabilities

**Use case:**
Production ML pipelines requiring comprehensive data quality monitoring.

## Common Patterns

### Pattern 1: Basic Validation

```elixir
import ExDataCheck

expectations = [
  expect_column_to_exist(:user_id),
  expect_column_values_to_not_be_null(:user_id),
  expect_column_values_to_be_unique(:user_id)
]

result = ExDataCheck.validate(dataset, expectations)

if result.success do
  # Process data
else
  # Handle failures
end
```

### Pattern 2: Profile and Validate

```elixir
# First profile to understand data
profile = ExDataCheck.profile(dataset, detailed: true)

# Then create expectations based on profile
expectations = [
  expect_column_mean_to_be_between(:age,
    profile.columns[:age].mean * 0.9,
    profile.columns[:age].mean * 1.1
  )
]

result = ExDataCheck.validate(new_data, expectations)
```

### Pattern 3: Drift Monitoring

```elixir
# During training
baseline = ExDataCheck.create_baseline(training_data)
File.write!("baseline.json", Jason.encode!(baseline))

# In production
baseline = File.read!("baseline.json") |> Jason.decode!(keys: :atoms)

drift = ExDataCheck.detect_drift(production_batch, baseline)

if drift.drifted do
  # Alert ops team
  # Consider model retraining
end
```

### Pattern 4: Pipeline Integration

```elixir
defmodule DataPipeline do
  import ExDataCheck

  @raw_expectations [...]
  @feature_expectations [...]

  def process(raw_data) do
    with {:ok, _} <- validate_raw(raw_data),
         {:ok, features} <- engineer_features(raw_data),
         {:ok, _} <- validate_features(features) do
      {:ok, features}
    end
  end

  defp validate_raw(data) do
    case ExDataCheck.validate(data, @raw_expectations) do
      %{success: true} -> {:ok, data}
      result -> {:error, result}
    end
  end
end
```

## Example Data

All examples use simulated data for demonstration purposes:

- **basic_validation.exs**: User records with names, emails, ages, scores
- **data_profiling.exs**: Sales data with products, prices, revenues, regions
- **drift_detection.exs**: ML features with normal and uniform distributions
- **ml_pipeline.exs**: Loan application data with demographics and financial features

The examples generate random data on each run, so results will vary slightly but demonstrate consistent behavior.

## Learning Path

We recommend exploring the examples in this order:

1. **Start with basic_validation.exs** - Learn core validation concepts
2. **Move to data_profiling.exs** - Understand data analysis capabilities
3. **Try drift_detection.exs** - Learn production monitoring
4. **Study ml_pipeline.exs** - See complete integration

## Extending Examples

Feel free to modify these examples to test with your own data:

```elixir
# Replace the simulated data with your dataset
my_data = [
  %{id: 1, name: "Alice", value: 100},
  %{id: 2, name: "Bob", value: 200}
]

# Reuse the expectations from examples
expectations = [
  expect_column_to_exist(:id),
  expect_column_values_to_be_unique(:id)
]

result = ExDataCheck.validate(my_data, expectations)
```

## Getting Help

- **Documentation**: See main README.md and docs/ directory
- **API Reference**: Run `mix docs` and open `doc/index.html`
- **Issues**: https://github.com/North-Shore-AI/ExDataCheck/issues

## Performance Notes

The examples demonstrate performance characteristics:

- **basic_validation.exs**: ~1ms for 5 rows, 25 expectations
- **data_profiling.exs**: ~3ms for 1000 rows with detailed profiling
- **drift_detection.exs**: ~10-20ms for 500 rows drift detection
- **ml_pipeline.exs**: ~50-100ms for complete pipeline with 1000 rows

Actual performance depends on your hardware and dataset characteristics.

## Next Steps

After exploring these examples:

1. Read the [Architecture Guide](../docs/architecture.md)
2. Review the [Expectations Guide](../docs/expectations.md)
3. Check the [API Documentation](https://hexdocs.pm/ex_data_check)
4. Integrate ExDataCheck into your project
5. Create custom expectations for your domain

---

Built with ❤️ by North Shore AI
