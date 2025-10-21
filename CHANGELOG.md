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

### Added

#### Statistical Expectations (5 expectations)
- expect_column_mean_to_be_between/3 - Validate column mean within range
- expect_column_median_to_be_between/3 - Validate column median
- expect_column_stdev_to_be_between/3 - Validate standard deviation
- expect_column_quantile_to_be/3 - Validate specific quantiles
- expect_column_values_to_be_normal/2 - Normality testing with KS test

#### ML-Specific Expectations (6 expectations)
- expect_label_balance/2 - Label distribution balance for classification
- expect_label_cardinality/2 - Validate number of unique labels
- expect_feature_correlation/3 - Detect highly correlated features
- expect_no_missing_values/1 - Critical for ML algorithms
- expect_table_row_count_to_be_between/2 - Dataset size validation
- expect_no_data_drift/3 - Distribution drift detection

#### Drift Detection System
- Drift.create_baseline/1 - Capture reference distributions
- Drift.detect/2 - Compare current data to baseline
- Drift.ks_test/2 - Two-sample Kolmogorov-Smirnov test
- Drift.psi/2 - Population Stability Index calculation
- DriftResult struct with per-column drift scores
- Automatic method selection (KS for numeric, PSI for categorical)

#### Advanced Profiling
- Outliers.detect_iqr/1 - IQR method outlier detection
- Outliers.detect_zscore/2 - Z-score method outlier detection
- Enhanced profiling with detailed mode (outliers + correlations)
- Correlation matrix in profile results

#### Correlation Analysis
- Correlation.pearson/2 - Pearson correlation coefficient
- Correlation.spearman/2 - Spearman rank correlation
- Correlation.correlation_matrix/2 - Pairwise correlation matrix

### Enhanced

- Profile system supports detailed mode with outliers and correlations
- Statistical rigor: KS test, normal CDF, error function implementations
- Comprehensive drift tracking for ML model monitoring

### Technical

- Total Expectations: 22 (3 schema + 8 value + 5 statistical + 6 ML)
- Test Coverage: 273 tests (4 doctests, 25 properties, 244 unit)
- New Modules: Statistical, ML, Drift, DriftResult, Correlation, Outliers
- Zero Warnings, >90% Coverage

## [Unreleased]

[0.2.0]: https://github.com/North-Shore-AI/ExDataCheck/releases/tag/v0.2.0
[0.1.0]: https://github.com/North-Shore-AI/ExDataCheck/releases/tag/v0.1.0
