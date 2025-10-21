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

      # Define expectations
      dataset = [
        %{age: 25, name: "Alice", score: 0.85},
        %{age: 30, name: "Bob", score: 0.92}
      ]

      expectations = [
        expect_column_to_exist(:age),
        expect_column_to_be_of_type(:age, :integer),
        expect_column_to_be_of_type(:score, :float)
      ]

      # Validate
      result = ExDataCheck.validate(dataset, expectations)

      # Check results
      if result.success do
        IO.puts("All expectations met!")
      else
        failed = ExDataCheck.ValidationResult.failed_expectations(result)
        IO.inspect(failed, label: "Failed expectations")
      end

  ## Main API

  - `validate/2` - Validate dataset against expectations, returns ValidationResult
  - `validate!/2` - Validate and raise on failure

  ## Expectation Modules

  - `ExDataCheck.Expectations.Schema` - Schema expectations (column existence, types, counts)
  - `ExDataCheck.Expectations.Value` - Value expectations (ranges, sets, patterns) [Coming in v0.1]
  - `ExDataCheck.Expectations.Statistical` - Statistical expectations (mean, median, etc.) [Coming in v0.2]
  - `ExDataCheck.Expectations.ML` - ML-specific expectations (drift, distributions) [Coming in v0.2]

  """

  alias ExDataCheck.{ValidationResult, ValidationError, Expectation}
  alias ExDataCheck.Validator.ColumnExtractor

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
