# ExDataCheck Enhancement Design: v0.2.1

**Document Date**: November 25, 2025
**Author**: Claude Code
**Status**: Implementation Ready
**Target**: ExDataCheck v0.2.1

## Executive Summary

This document outlines enhancements to ExDataCheck v0.2.0 that add critical missing functionality identified through codebase analysis. These enhancements focus on three key areas:

1. **Time-Series Expectations** - Validate temporal data patterns
2. **Enhanced String Validation** - Comprehensive string format checking
3. **Composite Expectations** - Combine and compose expectations logically

These additions fill important gaps in the current expectation library while maintaining backward compatibility and adhering to existing architectural patterns.

---

## Current State Analysis

### Strengths (v0.2.0)

- **Comprehensive Coverage**: 22 expectations across schema, value, statistical, and ML categories
- **Production Ready**: >90% test coverage, zero warnings
- **Well-Architected**: Clean separation of concerns, extensible design
- **ML-Focused**: Drift detection, correlation analysis, label balance

### Identified Gaps

After thorough analysis of the codebase, documentation, and roadmap, the following gaps were identified:

#### 1. **Temporal Data Validation**
- **Gap**: No expectations for time-series data validation
- **Impact**: Cannot validate timestamps, temporal ordering, or time-based patterns
- **Use Cases**: Log validation, event streams, time-series ML data

#### 2. **String Format Validation**
- **Gap**: Limited string validation (only regex and length)
- **Impact**: Cannot validate common string formats (email, URL, phone, UUID)
- **Use Cases**: Contact data, web data, identifier validation

#### 3. **Composite Expectations**
- **Gap**: No way to combine expectations with logical operators
- **Impact**: Cannot express "A AND B" or "A OR B" validation logic
- **Use Cases**: Complex business rules, conditional validation

#### 4. **Missing Value Strategy Options**
- **Gap**: No fine-grained control over how expectations handle nulls
- **Impact**: All-or-nothing approach to null handling
- **Use Cases**: Datasets with expected missing values in specific contexts

---

## Enhancement 1: Time-Series Expectations

### Rationale

Time-series data is ubiquitous in ML workflows (logs, sensors, financial data, user events). ExDataCheck currently has no dedicated support for validating temporal patterns.

### Proposed Expectations

#### 1.1 `expect_column_values_to_be_valid_timestamps/2`

Validates that column contains parseable timestamps.

```elixir
# Ensure all timestamps are valid
expect_column_values_to_be_valid_timestamps(:created_at)

# With format specification
expect_column_values_to_be_valid_timestamps(:event_time,
  format: "{YYYY}-{0M}-{0D}T{h24}:{m}:{s}Z"
)
```

**Parameters**:
- `column` - Column name
- `opts` - Options
  - `:format` - Expected timestamp format (optional, attempts multiple formats if not specified)
  - `:allow_nil` - Whether to allow nil values (default: false)

**Validation Logic**:
- Attempts to parse each value as timestamp
- Returns failing values and parse errors
- Supports multiple common formats if no format specified

#### 1.2 `expect_column_timestamps_to_be_chronological/2`

Validates that timestamps are in chronological order (strictly increasing or non-decreasing).

```elixir
# Strictly increasing (no duplicates)
expect_column_timestamps_to_be_chronological(:timestamp, strict: true)

# Non-decreasing (duplicates allowed)
expect_column_timestamps_to_be_chronological(:event_time)
```

**Parameters**:
- `column` - Column name
- `opts` - Options
  - `:strict` - Require strictly increasing (default: false, allows equal)
  - `:allow_nil` - Skip nil values (default: true)

**Validation Logic**:
- Checks that each timestamp >= (or >) previous timestamp
- Reports violations with indices and timestamp values
- Handles nil values according to option

#### 1.3 `expect_column_timestamps_to_be_within_range/3`

Validates that timestamps fall within a specified date range.

```elixir
# Ensure timestamps within last year
start_date = DateTime.utc_now() |> DateTime.add(-365, :day)
end_date = DateTime.utc_now()
expect_column_timestamps_to_be_within_range(:event_time, start_date, end_date)
```

**Parameters**:
- `column` - Column name
- `min_timestamp` - Minimum timestamp (inclusive, DateTime or NaiveDateTime)
- `max_timestamp` - Maximum timestamp (inclusive, DateTime or NaiveDateTime)

**Validation Logic**:
- Parses timestamps and compares to range
- Returns out-of-range values with details
- Handles timezone conversions if needed

#### 1.4 `expect_column_timestamp_intervals_to_be_regular/2`

Validates that timestamps have regular intervals (e.g., every hour, every day).

```elixir
# Expect hourly data points
expect_column_timestamp_intervals_to_be_regular(:reading_time,
  expected_interval: {1, :hour},
  tolerance: 0.1  # 10% tolerance
)
```

**Parameters**:
- `column` - Column name
- `opts` - Options
  - `:expected_interval` - Tuple of {value, unit} where unit is :second, :minute, :hour, :day
  - `:tolerance` - Acceptable deviation as ratio (0.1 = 10%)

**Validation Logic**:
- Calculates intervals between consecutive timestamps
- Checks if intervals match expected (within tolerance)
- Reports irregular intervals

### Implementation Details

**New Module**: `lib/ex_data_check/expectations/temporal.ex`

```elixir
defmodule ExDataCheck.Expectations.Temporal do
  @moduledoc """
  Time-series and temporal data expectations.

  Validates timestamp formats, chronological ordering, date ranges,
  and temporal patterns common in time-series ML workflows.
  """

  alias ExDataCheck.{Expectation, ExpectationResult}
  alias ExDataCheck.Validator.ColumnExtractor

  # Implementation of expectations...
end
```

**Testing Strategy**:
- Unit tests for each expectation
- Property-based tests for temporal logic
- Edge cases: timezone conversions, leap years, DST
- Test with various timestamp formats

**Dependencies**:
- Use Elixir's built-in DateTime/NaiveDateTime
- No additional dependencies required

---

## Enhancement 2: Enhanced String Validation

### Rationale

Current string validation is limited to regex patterns and length checks. Many ML workflows involve structured string data (emails, URLs, UUIDs) that benefit from dedicated validators.

### Proposed Expectations

#### 2.1 `expect_column_values_to_be_valid_emails/1`

Validates email address format.

```elixir
expect_column_values_to_be_valid_emails(:email)
```

**Validation Logic**:
- Uses comprehensive email regex
- Checks basic structure: local@domain.tld
- Returns invalid email examples

#### 2.2 `expect_column_values_to_be_valid_urls/2`

Validates URL format.

```elixir
# Any valid URL
expect_column_values_to_be_valid_urls(:website)

# Only HTTPS URLs
expect_column_values_to_be_valid_urls(:api_endpoint, schemes: [:https])
```

**Parameters**:
- `column` - Column name
- `opts` - Options
  - `:schemes` - Allowed schemes (default: [:http, :https])
  - `:require_tld` - Require top-level domain (default: true)

**Validation Logic**:
- Parses and validates URL structure
- Checks scheme, domain, path components
- Returns malformed URLs

#### 2.3 `expect_column_values_to_be_valid_uuids/2`

Validates UUID format.

```elixir
# Any UUID version
expect_column_values_to_be_valid_uuids(:id)

# Specific version
expect_column_values_to_be_valid_uuids(:session_id, version: 4)
```

**Parameters**:
- `column` - Column name
- `opts` - Options
  - `:version` - UUID version (1-5, default: any)
  - `:case` - :lower, :upper, or :any (default: :any)

**Validation Logic**:
- Validates UUID format (8-4-4-4-12 hex digits)
- Checks version bits if specified
- Returns invalid UUIDs

#### 2.4 `expect_column_values_to_match_format/2`

Validates strings against predefined format patterns.

```elixir
# US phone number
expect_column_values_to_match_format(:phone, :us_phone)

# Credit card (masked)
expect_column_values_to_match_format(:cc_last4, :credit_card_last4)

# ISO date
expect_column_values_to_match_format(:date_str, :iso_date)
```

**Supported Formats**:
- `:us_phone` - (123) 456-7890, 123-456-7890, etc.
- `:credit_card_last4` - Last 4 digits: XXXX-XXXX-XXXX-1234
- `:iso_date` - YYYY-MM-DD
- `:iso_datetime` - YYYY-MM-DDTHH:MM:SSZ
- `:ip_address` - IPv4 or IPv6
- `:hex_color` - #RRGGBB or #RGB

**Parameters**:
- `column` - Column name
- `format` - Format atom or custom regex

**Validation Logic**:
- Maps format to appropriate validator
- Returns non-matching values
- Provides format-specific error messages

#### 2.5 `expect_column_string_length_distribution/3`

Validates that string lengths follow expected distribution.

```elixir
# Names typically 5-20 characters
expect_column_string_length_distribution(:name,
  mean_length: {5, 20},
  max_length: 50
)
```

**Parameters**:
- `column` - Column name
- `opts` - Options
  - `:mean_length` - Expected mean range as {min, max}
  - `:max_length` - Absolute maximum length
  - `:min_length` - Absolute minimum length

**Validation Logic**:
- Calculates length statistics
- Checks mean falls in expected range
- Flags outliers beyond absolute bounds

### Implementation Details

**New Module**: `lib/ex_data_check/expectations/string.ex`

```elixir
defmodule ExDataCheck.Expectations.String do
  @moduledoc """
  Enhanced string validation expectations.

  Provides format-specific validation for common string patterns
  like emails, URLs, UUIDs, and phone numbers.
  """

  alias ExDataCheck.{Expectation, ExpectationResult}
  alias ExDataCheck.Validator.ColumnExtractor

  # Format validators
  @email_regex ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/
  @uuid_regex ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

  # Implementation...
end
```

**Testing Strategy**:
- Test valid and invalid examples for each format
- Property-based tests for regex patterns
- Edge cases: internationalization, special characters
- Performance tests for regex matching

---

## Enhancement 3: Composite Expectations

### Rationale

Complex business rules often require combining multiple expectations with logical operators. Currently, users must manually implement this logic in application code.

### Proposed API

#### 3.1 `expect_all/1` - Logical AND

All expectations must pass.

```elixir
expect_all([
  expect_column_to_exist(:age),
  expect_column_values_to_be_between(:age, 0, 120),
  expect_column_mean_to_be_between(:age, 25, 45)
])
```

**Behavior**:
- Executes all expectations
- Succeeds only if ALL pass
- Returns all results (both passing and failing)

#### 3.2 `expect_any/1` - Logical OR

At least one expectation must pass.

```elixir
# Accept either email or phone for contact
expect_any([
  expect_column_values_to_be_valid_emails(:contact),
  expect_column_values_to_match_format(:contact, :us_phone)
])
```

**Behavior**:
- Executes all expectations
- Succeeds if ANY pass
- Returns all results with OR logic annotation

#### 3.3 `expect_at_least/2` - Threshold Logic

At least N expectations must pass.

```elixir
# At least 2 of 3 quality checks
expect_at_least(2, [
  expect_no_missing_values(:features),
  expect_column_mean_to_be_between(:score, 0.7, 1.0),
  expect_label_balance(:target, min_ratio: 0.3)
])
```

**Parameters**:
- `min_passing` - Minimum number that must pass
- `expectations` - List of expectations

#### 3.4 `expect_conditional/3` - Conditional Expectations

Apply expectation only if condition is met.

```elixir
# Only validate age if age_verified flag is true
expect_conditional(
  fn dataset -> Enum.all?(dataset, fn row -> row[:age_verified] end) end,
  expect_column_values_to_be_between(:age, 18, 100),
  else: expect_column_to_exist(:age_estimated)
)
```

**Parameters**:
- `condition` - Function that returns boolean
- `then_expectation` - Expectation to apply if true
- `opts` - Options
  - `:else` - Expectation to apply if false (optional)

### Implementation Details

**New Module**: `lib/ex_data_check/expectations/composite.ex`

```elixir
defmodule ExDataCheck.Expectations.Composite do
  @moduledoc """
  Composite expectations for logical combination of validations.

  Allows expressing complex business rules through logical composition:
  - AND logic (all must pass)
  - OR logic (any must pass)
  - Threshold logic (at least N must pass)
  - Conditional logic (if/then/else)
  """

  alias ExDataCheck.{Expectation, ExpectationResult}

  def expect_all(expectations) do
    validator = fn dataset ->
      results = Enum.map(expectations, & &1.validator.(dataset))
      success = Enum.all?(results, & &1.success)

      ExpectationResult.new(
        success,
        "expect all #{length(expectations)} expectations to pass",
        %{
          total: length(expectations),
          passed: Enum.count(results, & &1.success),
          failed: Enum.count(results, &(!&1.success)),
          results: results
        },
        %{logic: :and, count: length(expectations)}
      )
    end

    Expectation.new(:composite_all, :all, validator, %{expectations: expectations})
  end

  # Additional implementations...
end
```

**Testing Strategy**:
- Test all logical operators
- Test nested compositions
- Test short-circuit behavior (if implemented)
- Test performance with many expectations

---

## Enhancement 4: Flexible Null Handling

### Rationale

Current expectations have inconsistent null handling. Some ignore nulls, others don't. This enhancement provides explicit control.

### Proposed Enhancement

Add `:null_strategy` option to all expectations:

```elixir
# Fail if ANY nulls present
expect_column_values_to_be_between(:age, 0, 120, null_strategy: :fail)

# Ignore nulls (current behavior)
expect_column_values_to_be_between(:age, 0, 120, null_strategy: :ignore)

# Count nulls in validation stats but don't fail
expect_column_values_to_be_between(:age, 0, 120, null_strategy: :report)

# Require exactly N% nulls (for missing data strategies)
expect_column_values_to_be_between(:age, 0, 120,
  null_strategy: {:expect_ratio, 0.05}  # Expect ~5% missing
)
```

**Null Strategies**:
- `:ignore` - Skip null values (default for most expectations)
- `:fail` - Fail if any nulls present
- `:report` - Include null count in results but don't fail
- `{:expect_ratio, ratio}` - Expect specific ratio of nulls

### Implementation

Add to base Expectation validation logic:

```elixir
defp handle_null_strategy(values, opts) do
  strategy = Keyword.get(opts, :null_strategy, :ignore)
  non_nil = Enum.reject(values, &is_nil/1)
  nil_count = length(values) - length(non_nil)

  case strategy do
    :ignore -> {:ok, non_nil, %{null_count: nil_count}}
    :fail when nil_count > 0 -> {:error, "Nulls not allowed"}
    :fail -> {:ok, non_nil, %{null_count: 0}}
    :report -> {:ok, non_nil, %{null_count: nil_count, null_ratio: nil_count / length(values)}}
    {:expect_ratio, expected} ->
      actual = nil_count / length(values)
      if abs(actual - expected) < 0.01 do
        {:ok, non_nil, %{null_ratio: actual}}
      else
        {:error, "Expected #{expected} nulls, got #{actual}"}
      end
  end
end
```

---

## Architecture & Integration

### Module Structure

```
lib/ex_data_check/expectations/
├── schema.ex          (existing - 3 expectations)
├── value.ex           (existing - 8 expectations)
├── statistical.ex     (existing - 5 expectations)
├── ml.ex              (existing - 6 expectations)
├── temporal.ex        (NEW - 4 expectations)
├── string.ex          (NEW - 5 expectations)
└── composite.ex       (NEW - 4 expectations)
```

### Total Expectations Count

- **v0.2.0**: 22 expectations
- **v0.2.1**: 34 expectations (+12 new)
  - Schema: 3
  - Value: 8
  - Statistical: 5
  - ML: 6
  - **Temporal: 4 (NEW)**
  - **String: 5 (NEW)**
  - **Composite: 4 (NEW)**

### Main API Updates

Update `lib/ex_data_check.ex` with new delegations:

```elixir
# Temporal expectations
defdelegate expect_column_values_to_be_valid_timestamps(column), to: Temporal
defdelegate expect_column_values_to_be_valid_timestamps(column, opts), to: Temporal
defdelegate expect_column_timestamps_to_be_chronological(column), to: Temporal
defdelegate expect_column_timestamps_to_be_chronological(column, opts), to: Temporal
defdelegate expect_column_timestamps_to_be_within_range(column, min, max), to: Temporal
defdelegate expect_column_timestamp_intervals_to_be_regular(column, opts), to: Temporal

# String expectations
defdelegate expect_column_values_to_be_valid_emails(column), to: String
defdelegate expect_column_values_to_be_valid_urls(column), to: String
defdelegate expect_column_values_to_be_valid_urls(column, opts), to: String
defdelegate expect_column_values_to_be_valid_uuids(column), to: String
defdelegate expect_column_values_to_be_valid_uuids(column, opts), to: String
defdelegate expect_column_values_to_match_format(column, format), to: String
defdelegate expect_column_string_length_distribution(column, opts), to: String

# Composite expectations
defdelegate expect_all(expectations), to: Composite
defdelegate expect_any(expectations), to: Composite
defdelegate expect_at_least(min_passing, expectations), to: Composite
defdelegate expect_conditional(condition, then_exp, opts), to: Composite
```

---

## Testing Strategy

### Test Coverage Goals

- Maintain >90% coverage
- All new expectations have:
  - Unit tests for success cases
  - Unit tests for failure cases
  - Edge case tests
  - Property-based tests (where applicable)
  - Integration tests

### Test Organization

```
test/expectations/
├── temporal_test.exs      (NEW - 100+ tests)
├── string_test.exs        (NEW - 80+ tests)
├── composite_test.exs     (NEW - 60+ tests)
└── null_handling_test.exs (NEW - 40+ tests)
```

### Expected Test Count

- **v0.2.0**: 273 tests
- **v0.2.1**: ~550+ tests (+280 new)

---

## Performance Considerations

### Time-Series Expectations

- **Timestamp parsing**: O(n) with caching
- **Chronological check**: O(n) single pass
- **Interval regularity**: O(n) single pass

### String Expectations

- **Email validation**: O(n) with compiled regex
- **URL parsing**: O(n) using URI module
- **UUID validation**: O(n) with compiled regex

### Composite Expectations

- **expect_all**: O(n * m) where m = number of expectations
- **expect_any**: Can short-circuit after first success
- **expect_conditional**: Adds condition evaluation overhead

### Optimization Strategies

1. **Regex Compilation**: Pre-compile all regex patterns
2. **Parallel Execution**: Consider parallel expectation execution for composites
3. **Early Termination**: Short-circuit logic where appropriate
4. **Caching**: Cache parsed timestamps and URLs

---

## Backward Compatibility

### Breaking Changes

**NONE** - This release is 100% backward compatible with v0.2.0.

### Deprecations

**NONE** - No existing functionality is deprecated.

### Migration Guide

No migration needed. All new functionality is additive:

```elixir
# v0.2.0 code continues to work unchanged
result = ExDataCheck.validate(dataset, [
  expect_column_to_exist(:age),
  expect_column_values_to_be_between(:age, 0, 120)
])

# v0.2.1 adds new expectations
result = ExDataCheck.validate(dataset, [
  expect_column_to_exist(:age),
  expect_column_values_to_be_between(:age, 0, 120),
  expect_column_values_to_be_valid_timestamps(:created_at),  # NEW
  expect_column_values_to_be_valid_emails(:email)            # NEW
])
```

---

## Documentation Updates

### README.md Updates

- Update expectations count: 22 → 34
- Add temporal expectations section
- Add string expectations section
- Add composite expectations section
- Update test count: 273 → 550+

### New Documentation

- `docs/expectations_temporal.md` - Temporal expectations guide
- `docs/expectations_string.md` - String validation guide
- `docs/expectations_composite.md` - Composite logic guide

### Examples

- `examples/temporal_validation.exs` - Time-series validation examples
- `examples/string_validation.exs` - String format validation examples
- `examples/composite_logic.exs` - Complex business rules examples

---

## Implementation Phases

### Phase 1: Temporal Expectations (2 days)

1. Create `temporal.ex` module
2. Implement 4 temporal expectations
3. Write comprehensive tests (100+ tests)
4. Update main API with delegations
5. Document in README and separate guide

### Phase 2: String Expectations (1.5 days)

1. Create `string.ex` module
2. Implement 5 string expectations
3. Write comprehensive tests (80+ tests)
4. Update main API with delegations
5. Document in README and separate guide

### Phase 3: Composite Expectations (1.5 days)

1. Create `composite.ex` module
2. Implement 4 composite expectations
3. Write comprehensive tests (60+ tests)
4. Update main API with delegations
5. Document in README and separate guide

### Phase 4: Polish & Release (1 day)

1. Run full test suite
2. Ensure zero warnings
3. Update CHANGELOG.md
4. Update version to 0.2.1
5. Generate documentation
6. Create release notes

**Total Time Estimate**: 6 days

---

## Success Metrics

### Code Quality

- [ ] >90% test coverage maintained
- [ ] Zero compilation warnings
- [ ] All tests passing
- [ ] No performance regressions

### Functionality

- [ ] 12 new expectations implemented and tested
- [ ] All expectations have comprehensive documentation
- [ ] Examples demonstrate real-world use cases

### User Experience

- [ ] Clear error messages for all validations
- [ ] Consistent API with existing expectations
- [ ] Backward compatible with v0.2.0

---

## Future Considerations

### Phase 3 Integration

These enhancements prepare for Phase 3 features:

- **Temporal expectations** enable time-series streaming validation
- **Composite expectations** support complex quality monitoring rules
- **String validation** complements data quality dashboards

### Potential Extensions (Future Releases)

- **Geospatial Expectations**: Lat/long validation, distance checks
- **JSON Schema Expectations**: Validate nested JSON structures
- **Network Expectations**: IP ranges, subnet validation
- **Custom Format Registry**: User-defined format validators
- **Async Validation**: Long-running validation with callbacks

---

## Conclusion

These enhancements significantly expand ExDataCheck's capabilities while maintaining its core principles of simplicity, reliability, and ML-focus. The additions fill critical gaps in temporal and string validation while adding powerful composition capabilities for complex business rules.

The implementation follows established patterns, maintains backward compatibility, and sets the stage for Phase 3 production features.

**Implementation Ready**: This design is ready for immediate implementation following the TDD approach outlined in the project guidelines.
