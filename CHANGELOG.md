# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-10-20

### Added

#### Core Validation Framework
- Expectation system with declarative data quality requirements
- ValidationResult for aggregated validation results
- ExpectationResult for individual expectation results  
- ValidationError exception for fail-fast scenarios

#### Schema Expectations (3 expectations)
- expect_column_to_exist/1
- expect_column_to_be_of_type/2
- expect_column_count_to_equal/1

#### Value Expectations (8 expectations)
- expect_column_values_to_be_between/3
- expect_column_values_to_be_in_set/2
- expect_column_values_to_match_regex/2
- expect_column_values_to_not_be_null/1
- expect_column_values_to_be_unique/1
- expect_column_values_to_be_increasing/1
- expect_column_values_to_be_decreasing/1
- expect_column_value_lengths_to_be_between/3

#### Data Profiling
- Profile system with comprehensive dataset statistics
- Statistics utilities (min, max, mean, median, stdev, variance, quantiles)
- Automatic type inference
- Quality score calculation
- JSON and Markdown export

#### Main API
- validate/2 - Validate dataset against expectations
- validate!/2 - Validate with exception on failure
- profile/1 - Generate dataset profile
- Convenience functions for all expectations

### Technical
- Test Coverage: 186 tests (4 doctests, 17 properties, 165 unit)
- Elixir: ~> 1.14
- OTP: >= 25
- Dependencies: Jason, StreamData (test only)

## [0.2.0] - 2025-10-20

**Major Release**: Statistical analysis, ML-specific validations, and drift detection

This release transforms ExDataCheck from a core validation library into a comprehensive
ML data quality platform with advanced statistical analysis, drift detection, and
correlation analysis capabilities.

### Added

#### Statistical Expectations (5 new expectations)

Validate aggregate statistical properties of your data:

- **`expect_column_mean_to_be_between/3`** - Validate column mean falls within expected range
  - Example: `expect_column_mean_to_be_between(:age, 25, 45)`
  - Useful for detecting distribution shifts in numeric features

- **`expect_column_median_to_be_between/3`** - Validate median (50th percentile)
  - Example: `expect_column_median_to_be_between(:income, 40000, 60000)`
  - More robust to outliers than mean

- **`expect_column_stdev_to_be_between/3`** - Validate standard deviation
  - Example: `expect_column_stdev_to_be_between(:score, 0.1, 0.3)`
  - Ensure data variability is within expected bounds

- **`expect_column_quantile_to_be/3`** - Validate specific quantiles
  - Example: `expect_column_quantile_to_be(:age, 0.95, 65)`
  - Check distribution tails and percentiles
  - Supports custom tolerance levels

- **`expect_column_values_to_be_normal/2`** - Test for normal distribution
  - Example: `expect_column_values_to_be_normal(:measurements, alpha: 0.05)`
  - Uses Kolmogorov-Smirnov goodness-of-fit test
  - Configurable significance level
  - Returns test statistics and p-values

#### ML-Specific Expectations (6 new expectations)

Purpose-built for machine learning workflows:

- **`expect_label_balance/2`** - Validate label distribution for classification
  - Example: `expect_label_balance(:target, min_ratio: 0.2)`
  - Prevents model bias from imbalanced datasets
  - Reports class distribution and min class ratio
  - Works with binary and multi-class classification

- **`expect_label_cardinality/2`** - Validate number of unique labels
  - Example: `expect_label_cardinality(:target, min: 2, max: 10)`
  - Ensure reasonable number of classes
  - Detect label encoding issues

- **`expect_feature_correlation/3`** - Detect highly correlated features
  - Example: `expect_feature_correlation(:f1, :f2, max: 0.95)`
  - Helps avoid multicollinearity in models
  - Supports both max and min correlation bounds
  - Uses Pearson correlation

- **`expect_no_missing_values/1`** - Critical for many ML algorithms
  - Example: `expect_no_missing_values(:features)`
  - Alias for `expect_column_values_to_not_be_null/1` with ML-friendly naming
  - Reports completeness percentage

- **`expect_table_row_count_to_be_between/2`** - Dataset size validation
  - Example: `expect_table_row_count_to_be_between(1000, 1_000_000)`
  - Ensure sufficient training data
  - Detect data pipeline issues

- **`expect_no_data_drift/3`** - Distribution drift detection
  - Example: `expect_no_data_drift(:features, baseline, threshold: 0.05)`
  - Monitor production data vs training distribution
  - Trigger model retraining when drift detected
  - Configurable drift thresholds

#### Drift Detection System

Complete infrastructure for detecting distribution changes:

- **`Drift.create_baseline/1`** - Capture reference distributions from training data
  - Stores numeric distributions (values, mean, stdev)
  - Stores categorical distributions (frequency counts)
  - Automatic type detection

- **`Drift.detect/2`** - Compare current data to baseline
  - Returns `DriftResult` with per-column drift scores
  - Lists columns that have drifted
  - Configurable thresholds (default: 0.05)
  - Automatic method selection

- **`Drift.ks_test/2`** - Two-sample Kolmogorov-Smirnov test
  - Tests if two samples come from same distribution
  - Returns KS statistic and p-value
  - O(n log n) complexity
  - Used for continuous numeric features

- **`Drift.psi/2`** - Population Stability Index calculation
  - Industry-standard metric for distribution shift
  - Formula: Σ (current% - baseline%) * ln(current% / baseline%)
  - PSI < 0.1: No shift, 0.1-0.2: Moderate, >= 0.2: Significant
  - Used for categorical features

- **`DriftResult` struct** - Comprehensive drift reporting
  - Boolean `drifted` flag
  - List of `columns_drifted`
  - Per-column `drift_scores` map
  - Detection `method` used
  - Configured `threshold`

#### Advanced Profiling

Enhanced profiling with outlier detection and correlations:

- **`Outliers.detect_iqr/1`** - Interquartile Range method
  - Uses Tukey's fences (Q1 - 1.5*IQR, Q3 + 1.5*IQR)
  - Returns outliers, counts, quartiles, and fence boundaries
  - Robust to extreme values

- **`Outliers.detect_zscore/2`** - Z-score method
  - Detects values with |z-score| > threshold (default: 3)
  - Returns outliers, z-scores, mean, and stdev
  - Configurable threshold
  - Assumes approximately normal distribution

- **Enhanced `profile/2`** - Detailed profiling mode
  - Option `:detailed` enables outliers and correlation matrix
  - Option `:outlier_method` chooses between `:iqr` or `:zscore`
  - Correlation matrix for all numeric columns
  - Outlier information in column profiles

- **Correlation matrix in profiles** - Feature relationship analysis
  - Pairwise Pearson correlations
  - Automatically calculated for numeric columns
  - Helps identify redundant features
  - Supports feature engineering decisions

#### Correlation Analysis

Complete correlation analysis toolkit:

- **`Correlation.pearson/2`** - Pearson correlation coefficient
  - Measures linear relationships between variables
  - Range: -1 (perfect negative) to 1 (perfect positive)
  - Returns nil for zero variance or mismatched lengths
  - Used in feature correlation expectations

- **`Correlation.spearman/2`** - Spearman rank correlation
  - Measures monotonic relationships using ranks
  - More robust to outliers than Pearson
  - Handles non-linear but monotonic relationships
  - Proper handling of tied ranks

- **`Correlation.correlation_matrix/2`** - Pairwise correlation matrix
  - Calculates all pairwise correlations for specified columns
  - Returns nested map: `matrix[col1][col2]`
  - Diagonal is 1.0 (self-correlation)
  - Symmetric matrix

#### Mathematical Implementations

Rigorous statistical methods implemented from scratch:

- **Kolmogorov-Smirnov normality test**
  - Goodness-of-fit test for normal distribution
  - Compares empirical CDF to theoretical normal CDF
  - Returns test statistic and p-value
  - Critical value tables for different sample sizes

- **Normal CDF approximation**
  - Uses error function (erf) for standard normal CDF
  - Abramowitz and Stegun formula implementation
  - Accurate approximation for hypothesis testing

- **Error function (erf)**
  - Mathematical special function for normal distribution
  - Polynomial approximation method
  - Used in normality testing

- **Rank calculation for Spearman**
  - Proper handling of tied ranks
  - Average rank assignment for ties
  - Maintains rank correlation properties

### Enhanced

#### Profile System Improvements

- **Detailed profiling mode** - Optional comprehensive analysis
  ```elixir
  profile = ExDataCheck.profile(dataset, detailed: true, outlier_method: :iqr)
  ```

- **Outlier detection integrated** - Automatic outlier detection for numeric columns
  - IQR method for robust detection
  - Z-score method for parametric detection
  - Results included in column profiles

- **Correlation matrix** - Automatic pairwise correlation calculation
  - Only for numeric columns
  - Helps identify multicollinearity
  - Supports feature selection

#### API Enhancements

- **Convenience delegations** - All expectations available from main `ExDataCheck` module
  ```elixir
  import ExDataCheck
  expect_column_mean_to_be_between(:age, 25, 45)  # Direct access
  ```

- **Drift utilities** - Convenient API for drift detection
  ```elixir
  baseline = ExDataCheck.create_baseline(training_data)
  drift = ExDataCheck.detect_drift(production_data, baseline)
  ```

### Fixed

- Floating point precision in correlation calculations
- LICENSE file reference in documentation
- Property-based test edge cases for mathematical functions

### Technical

- **Total Expectations**: 22 (added 11 in this release)
  - Schema: 3
  - Value: 8
  - Statistical: 5 (**new**)
  - ML: 6 (**new**)

- **Test Coverage**: 273 tests (added 87 tests)
  - 4 doctests
  - 25 property-based tests (added 8)
  - 244 unit/integration tests (added 79)

- **New Modules**: 6 major modules
  - `ExDataCheck.Expectations.Statistical` - Statistical expectations
  - `ExDataCheck.Expectations.ML` - ML-specific expectations
  - `ExDataCheck.Correlation` - Correlation analysis
  - `ExDataCheck.Drift` - Drift detection
  - `ExDataCheck.DriftResult` - Drift results
  - `ExDataCheck.Outliers` - Outlier detection

- **Code Quality**
  - Zero compiler warnings
  - >90% test coverage
  - All code formatted with `mix format`
  - Complete type specifications (@spec)
  - Comprehensive documentation (@doc)

- **Performance**
  - Batch validation: ~10k rows/second
  - Profiling: < 5s for 100k rows
  - KS test: O(n log n)
  - PSI: O(n)

### Breaking Changes

None. This release is fully backward compatible with v0.1.0.

### Migration Guide

If upgrading from v0.1.0:

1. Update dependency in `mix.exs`:
   ```elixir
   {:ex_data_check, "~> 0.2.0"}
   ```

2. Run `mix deps.update ex_data_check`

3. All existing code continues to work

4. New features available immediately:
   ```elixir
   # New statistical expectations
   expect_column_mean_to_be_between(:age, 25, 45)

   # New ML expectations
   expect_label_balance(:target, min_ratio: 0.2)

   # New drift detection
   baseline = ExDataCheck.create_baseline(training_data)
   drift = ExDataCheck.detect_drift(production_data, baseline)

   # Enhanced profiling
   profile = ExDataCheck.profile(dataset, detailed: true)
   ```

### Use Cases Enabled by v0.2.0

#### 1. Model Performance Monitoring

```elixir
# Create baseline from training data
baseline = ExDataCheck.create_baseline(training_data)

# Monitor production data for drift
drift = ExDataCheck.detect_drift(production_data, baseline)

if drift.drifted do
  trigger_model_retraining()
end
```

#### 2. Feature Engineering Validation

```elixir
expectations = [
  expect_feature_correlation(:f1, :f2, max: 0.9),  # Avoid multicollinearity
  expect_column_mean_to_be_between(:f1, -0.1, 0.1),  # Normalized features
  expect_column_stdev_to_be_between(:f1, 0.9, 1.1)
]
```

#### 3. Training Data Quality Assurance

```elixir
expectations = [
  expect_label_balance(:target, min_ratio: 0.15),  # Reasonable class balance
  expect_no_missing_values(:features),  # No NaN values
  expect_table_row_count_to_be_between(1000, 1_000_000)  # Sufficient data
]
```

### Dependencies

No new runtime dependencies. Jason was already required in v0.1.0.

### Documentation

- Enhanced README with v0.2.0 features (1136 lines)
- Complete CHANGELOG with v0.2.0 details
- Future vision document for Phase 3 & 4 (`docs/20251020/future_vision_phase3_4.md`)
- All new functions documented with examples

### Acknowledgments

Thanks to the Elixir community for inspiration and feedback during development.

Special recognition for mathematical rigor in statistical implementations.

## [Unreleased]

[0.2.0]: https://github.com/North-Shore-AI/ExDataCheck/releases/tag/v0.2.0
[0.1.0]: https://github.com/North-Shore-AI/ExDataCheck/releases/tag/v0.1.0
