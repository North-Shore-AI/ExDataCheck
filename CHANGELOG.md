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

[0.1.0]: https://github.com/North-Shore-AI/ExDataCheck/releases/tag/v0.1.0
