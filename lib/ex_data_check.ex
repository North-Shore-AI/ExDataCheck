defmodule ExDataCheck do
  @moduledoc """
  ExDataCheck - Data Validation and Quality Library for ML Pipelines

  ExDataCheck provides comprehensive data validation for Elixir machine learning
  workflows, bringing Great Expectations-style validation to the Elixir ecosystem.

  ## Features

  - **Expectations-Based Validation**: Define declarative expectations about data quality
  - **Data Profiling**: Automatic statistical profiling and characterization
  - **Schema Validation**: Type checking and structure validation
  - **Quality Metrics**: Comprehensive data quality scoring
  - **ML-Specific Checks**: Feature distributions, drift detection, label balance
  - **Pipeline Integration**: Seamless integration into ETL and ML pipelines

  ## Quick Start

      # Import convenience functions
      import ExDataCheck

      # Define your dataset
      dataset = [
        %{age: 25, name: "Alice", email: "alice@example.com", score: 0.85},
        %{age: 30, name: "Bob", email: "bob@example.com", score: 0.92},
        %{age: 35, name: "Charlie", email: "charlie@example.com", score: 0.78}
      ]

      # Define expectations using convenience functions
      expectations = [
        # Schema expectations
        expect_column_to_exist(:age),
        expect_column_to_exist(:email),
        expect_column_to_be_of_type(:age, :integer),
        expect_column_to_be_of_type(:name, :string),
        expect_column_count_to_equal(4),

        # Value expectations
        expect_column_values_to_be_between(:age, 18, 100),
        expect_column_values_to_be_between(:score, 0.0, 1.0),
        expect_column_values_to_match_regex(:email, ~r/@/),
        expect_column_values_to_not_be_null(:name),
        expect_column_values_to_be_unique(:email),
        expect_column_value_lengths_to_be_between(:name, 2, 50)
      ]

      # Validate
      result = ExDataCheck.validate(dataset, expectations)

      # Check results
      case result do
        %{success: true} = r ->
          IO.puts("✓ All expectations met!")

        %{success: false} = r ->
          IO.puts("✗ Some expectations failed")
          failed = ExDataCheck.ValidationResult.failed_expectations(r)
          Enum.each(failed, fn f -> IO.puts("  - " <> f.expectation) end)
      end

  ## Main API

  - `validate/2` - Validate dataset against expectations, returns ValidationResult
  - `validate!/2` - Validate and raise on failure
  - `profile/1` - Generate comprehensive dataset profile
  - `create_baseline/1` - Create distribution baseline for drift detection
  - `detect_drift/2` - Detect distribution drift from baseline

  ## Expectation Modules

  - `ExDataCheck.Expectations.Schema` - Schema expectations (column existence, types, counts)
  - `ExDataCheck.Expectations.Value` - Value expectations (ranges, sets, patterns)
  - `ExDataCheck.Expectations.Statistical` - Statistical expectations (mean, median, stdev, normality)
  - `ExDataCheck.Expectations.ML` - ML-specific expectations (label balance, correlations, missing values)

  """

  alias ExDataCheck.{ValidationResult, ValidationError, Expectation, Profile, Drift}
  alias ExDataCheck.Validator.ColumnExtractor
  alias ExDataCheck.Expectations.{Schema, Value, Statistical, ML}

  # Convenience delegations to expectation modules
  # This allows users to call ExDataCheck.expect_column_to_exist(:age)
  # instead of ExDataCheck.Expectations.Schema.expect_column_to_exist(:age)

  # Schema expectations
  defdelegate expect_column_to_exist(column), to: Schema
  defdelegate expect_column_to_be_of_type(column, type), to: Schema
  defdelegate expect_column_count_to_equal(count), to: Schema

  # Value expectations
  defdelegate expect_column_values_to_be_between(column, min, max), to: Value
  defdelegate expect_column_values_to_be_in_set(column, allowed_values), to: Value
  defdelegate expect_column_values_to_match_regex(column, pattern), to: Value
  defdelegate expect_column_values_to_not_be_null(column), to: Value
  defdelegate expect_column_values_to_be_unique(column), to: Value
  defdelegate expect_column_values_to_be_increasing(column), to: Value
  defdelegate expect_column_values_to_be_decreasing(column), to: Value

  defdelegate expect_column_value_lengths_to_be_between(column, min_length, max_length),
    to: Value

  # Statistical expectations
  defdelegate expect_column_mean_to_be_between(column, min, max), to: Statistical
  defdelegate expect_column_median_to_be_between(column, min, max), to: Statistical
  defdelegate expect_column_stdev_to_be_between(column, min, max), to: Statistical
  defdelegate expect_column_quantile_to_be(column, quantile, expected_value), to: Statistical

  defdelegate expect_column_quantile_to_be(column, quantile, expected_value, opts),
    to: Statistical

  defdelegate expect_column_values_to_be_normal(column), to: Statistical
  defdelegate expect_column_values_to_be_normal(column, opts), to: Statistical

  # ML-specific expectations
  defdelegate expect_label_balance(column, opts \\ []), to: ML
  defdelegate expect_label_cardinality(column, opts \\ []), to: ML
  defdelegate expect_feature_correlation(column1, column2, opts \\ []), to: ML
  defdelegate expect_no_missing_values(column), to: ML
  defdelegate expect_table_row_count_to_be_between(min, max), to: ML
  defdelegate expect_no_data_drift(column, baseline, opts \\ []), to: ML

  # Drift detection utilities
  defdelegate create_baseline(dataset), to: Drift
  defdelegate detect_drift(dataset, baseline), to: Drift, as: :detect
  defdelegate detect_drift(dataset, baseline, opts), to: Drift, as: :detect

  @doc """
  Profiles a dataset to analyze its structure and quality.

  Returns a `Profile` struct containing:
  - Row and column counts
  - Column-level statistics
  - Missing value analysis
  - Quality score
  - Outlier detection (optional)
  - Correlation matrix (optional)

  ## Parameters

    * `dataset` - List of maps or keyword lists
    * `opts` - Options
      * `:detailed` - Include outliers and correlations (default: false)
      * `:outlier_method` - Outlier detection method (`:iqr` or `:zscore`, default: `:iqr`)

  ## Examples

      iex> dataset = [%{age: 25, name: "Alice"}, %{age: 30, name: "Bob"}]
      iex> profile = ExDataCheck.profile(dataset)
      iex> profile.row_count
      2
      iex> profile.column_count
      2

      # Detailed profiling with outliers and correlations
      profile = ExDataCheck.profile(dataset, detailed: true)

  """
  @spec profile(list(map() | keyword()), keyword()) :: Profile.t()
  def profile(dataset, opts \\ []) do
    column_profiles = build_column_profiles(dataset, opts)

    # Add advanced features if detailed mode
    enhanced_profile =
      if Keyword.get(opts, :detailed, false) do
        add_advanced_profiling(dataset, column_profiles, opts)
      else
        %{}
      end

    Profile.new(length(dataset), column_profiles)
    |> Map.merge(enhanced_profile)
  end

  # Private profiling functions

  defp build_column_profiles(dataset, opts) do
    columns = ColumnExtractor.columns(dataset)
    detect_outliers = Keyword.get(opts, :detailed, false)
    outlier_method = Keyword.get(opts, :outlier_method, :iqr)

    columns
    |> Enum.map(fn column ->
      {column, profile_column(dataset, column, detect_outliers, outlier_method)}
    end)
    |> Enum.into(%{})
  end

  defp profile_column(dataset, column, detect_outliers, outlier_method) do
    values = ColumnExtractor.extract(dataset, column)
    non_nil_values = Enum.reject(values, &is_nil/1)
    missing_count = length(values) - length(non_nil_values)

    type = infer_type(non_nil_values)
    stats = calculate_column_stats(non_nil_values, type)

    outlier_info =
      if detect_outliers and type in [:integer, :float, :number] and length(non_nil_values) > 0 do
        outlier_result =
          ExDataCheck.Outliers.outlier_summary(non_nil_values, method: outlier_method)

        %{outliers: outlier_result}
      else
        %{}
      end

    stats
    |> Map.merge(outlier_info)
    |> Map.merge(%{
      type: type,
      missing: missing_count,
      cardinality: length(Enum.uniq(non_nil_values))
    })
  end

  defp infer_type([]), do: :unknown

  defp infer_type(values) do
    sample = Enum.take(values, 100)

    cond do
      Enum.all?(sample, &is_integer/1) -> :integer
      Enum.all?(sample, &is_float/1) -> :float
      Enum.all?(sample, &is_number/1) -> :number
      Enum.all?(sample, &is_binary/1) -> :string
      Enum.all?(sample, &is_boolean/1) -> :boolean
      Enum.all?(sample, &is_atom/1) -> :atom
      Enum.all?(sample, &is_list/1) -> :list
      Enum.all?(sample, &is_map/1) -> :map
      true -> :mixed
    end
  end

  defp calculate_column_stats(values, type)
       when type in [:integer, :float, :number] and length(values) > 0 do
    alias ExDataCheck.Statistics

    %{
      min: Statistics.min(values),
      max: Statistics.max(values),
      mean: Statistics.mean(values),
      median: Statistics.median(values),
      stdev: Statistics.stdev(values)
    }
  end

  defp calculate_column_stats(_values, _type), do: %{}

  defp add_advanced_profiling(dataset, column_profiles, _opts) do
    # Get numeric columns for correlation matrix
    numeric_columns =
      column_profiles
      |> Enum.filter(fn {_col, profile} -> profile.type in [:integer, :float, :number] end)
      |> Enum.map(fn {col, _profile} -> col end)

    correlation_matrix =
      if length(numeric_columns) > 1 do
        ExDataCheck.Correlation.correlation_matrix(dataset, numeric_columns)
      else
        %{}
      end

    %{correlation_matrix: correlation_matrix}
  end

  @doc """
  Validates a dataset against a list of expectations.

  Returns a `ValidationResult` struct containing:
  - Overall success/failure status
  - Count of met and failed expectations
  - Individual expectation results
  - Dataset metadata
  - Timestamp

  ## Parameters

    * `dataset` - List of maps or keyword lists representing the dataset
    * `expectations` - List of `Expectation` structs to validate against

  ## Examples

      iex> dataset = [%{age: 25}, %{age: 30}]
      iex> expectations = [
      ...>   ExDataCheck.Expectations.Schema.expect_column_to_exist(:age),
      ...>   ExDataCheck.Expectations.Schema.expect_column_to_be_of_type(:age, :integer)
      ...> ]
      iex> result = ExDataCheck.validate(dataset, expectations)
      iex> result.success
      true
      iex> result.total_expectations
      2

      iex> dataset = [%{name: "Alice"}]
      iex> expectations = [
      ...>   ExDataCheck.Expectations.Schema.expect_column_to_exist(:age)
      ...> ]
      iex> result = ExDataCheck.validate(dataset, expectations)
      iex> result.success
      false
      iex> result.expectations_failed
      1

  ## Error Handling

  `validate/2` never raises exceptions. It collects all validation failures
  and returns them in the `ValidationResult`. Use `validate!/2` if you want
  to raise on validation failure.

  """
  @spec validate(list(map() | keyword()), list(Expectation.t())) :: ValidationResult.t()
  def validate(dataset, expectations) do
    # Execute each expectation's validator
    results =
      Enum.map(expectations, fn expectation ->
        expectation.validator.(dataset)
      end)

    # Gather dataset info
    dataset_info = gather_dataset_info(dataset)

    # Create and return validation result
    ValidationResult.new(results, dataset_info)
  end

  @doc """
  Validates a dataset against expectations and raises on failure.

  Behaves like `validate/2` but raises `ExDataCheck.ValidationError` if
  any expectation fails.

  ## Parameters

    * `dataset` - List of maps or keyword lists
    * `expectations` - List of `Expectation` structs

  ## Returns

  Returns the `ValidationResult` if all expectations pass.

  ## Raises

  Raises `ExDataCheck.ValidationError` if any expectation fails. The
  exception includes the full `ValidationResult` for inspection.

  ## Examples

      iex> dataset = [%{age: 25}, %{age: 30}]
      iex> expectations = [
      ...>   ExDataCheck.Expectations.Schema.expect_column_to_exist(:age)
      ...> ]
      iex> result = ExDataCheck.validate!(dataset, expectations)
      iex> result.success
      true

      dataset = [%{name: "Alice"}]
      expectations = [
        ExDataCheck.Expectations.Schema.expect_column_to_exist(:age)
      ]

      # This will raise ValidationError
      ExDataCheck.validate!(dataset, expectations)

  """
  @spec validate!(list(map() | keyword()), list(Expectation.t())) ::
          ValidationResult.t() | no_return()
  def validate!(dataset, expectations) do
    result = validate(dataset, expectations)

    if result.success do
      result
    else
      raise ValidationError, result: result
    end
  end

  # Private functions

  @spec gather_dataset_info(list(map() | keyword())) :: map()
  defp gather_dataset_info(dataset) do
    columns = ColumnExtractor.columns(dataset)

    %{
      row_count: length(dataset),
      column_count: length(columns),
      columns: columns
    }
  end
end
