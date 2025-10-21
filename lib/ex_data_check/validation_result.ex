defmodule ExDataCheck.ValidationResult do
  @moduledoc """
  Represents the complete result of validating a dataset against a suite of expectations.

  A ValidationResult aggregates multiple ExpectationResults and provides:
  - Overall success/failure status
  - Counts of met and failed expectations
  - Individual expectation results
  - Dataset metadata
  - Timestamp of validation

  ## Examples

      iex> results = [
      ...>   ExDataCheck.ExpectationResult.new(true, "column exists", %{}),
      ...>   ExDataCheck.ExpectationResult.new(true, "values in range", %{})
      ...> ]
      iex> validation = ExDataCheck.ValidationResult.new(results, %{row_count: 100})
      iex> validation.success
      true
      iex> validation.total_expectations
      2
      iex> validation.expectations_met
      2

      iex> results = [
      ...>   ExDataCheck.ExpectationResult.new(true, "test 1", %{}),
      ...>   ExDataCheck.ExpectationResult.new(false, "test 2", %{})
      ...> ]
      iex> validation = ExDataCheck.ValidationResult.new(results, %{})
      iex> validation.success
      false
      iex> validation.expectations_failed
      1

  ## Design Principles

  - **Aggregate View**: Provides high-level success/failure status
  - **Detailed Results**: Retains all individual expectation results for inspection
  - **Timestamp**: Records when validation occurred for auditing
  - **Dataset Context**: Captures dataset metadata for reporting

  """

  alias ExDataCheck.ExpectationResult

  @typedoc """
  Dataset metadata and statistics.

  Common fields:
  - `:row_count` - Number of rows in dataset
  - `:column_count` - Number of columns
  - `:columns` - List of column names
  """
  @type dataset_info :: map()

  @type t :: %__MODULE__{
          success: boolean(),
          total_expectations: non_neg_integer(),
          expectations_met: non_neg_integer(),
          expectations_failed: non_neg_integer(),
          results: list(ExpectationResult.t()),
          dataset_info: dataset_info(),
          timestamp: DateTime.t()
        }

  defstruct [
    :success,
    :total_expectations,
    :expectations_met,
    :expectations_failed,
    :results,
    :dataset_info,
    :timestamp
  ]

  @doc """
  Creates a new ValidationResult from a list of ExpectationResults.

  Automatically calculates:
  - Overall success (true only if all expectations pass)
  - Total expectations count
  - Count of met expectations
  - Count of failed expectations
  - Current timestamp

  ## Parameters

    * `results` - List of ExpectationResult structs
    * `dataset_info` - Map containing dataset metadata

  ## Examples

      iex> results = [
      ...>   ExDataCheck.ExpectationResult.new(true, "test 1", %{}),
      ...>   ExDataCheck.ExpectationResult.new(true, "test 2", %{})
      ...> ]
      iex> validation = ExDataCheck.ValidationResult.new(results, %{row_count: 50})
      iex> validation.success
      true
      iex> validation.total_expectations
      2

      iex> results = [
      ...>   ExDataCheck.ExpectationResult.new(true, "test 1", %{}),
      ...>   ExDataCheck.ExpectationResult.new(false, "test 2", %{})
      ...> ]
      iex> validation = ExDataCheck.ValidationResult.new(results, %{})
      iex> validation.success
      false
      iex> validation.expectations_failed
      1

  """
  @spec new(list(ExpectationResult.t()), dataset_info()) :: t()
  def new(results, dataset_info) do
    total = length(results)
    met = Enum.count(results, &ExpectationResult.success?/1)
    failed = total - met
    success = failed == 0

    %__MODULE__{
      success: success,
      total_expectations: total,
      expectations_met: met,
      expectations_failed: failed,
      results: results,
      dataset_info: dataset_info,
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Returns true if all expectations passed.

  ## Examples

      iex> results = [ExDataCheck.ExpectationResult.new(true, "test", %{})]
      iex> validation = ExDataCheck.ValidationResult.new(results, %{})
      iex> ExDataCheck.ValidationResult.success?(validation)
      true

      iex> results = [
      ...>   ExDataCheck.ExpectationResult.new(true, "test 1", %{}),
      ...>   ExDataCheck.ExpectationResult.new(false, "test 2", %{})
      ...> ]
      iex> validation = ExDataCheck.ValidationResult.new(results, %{})
      iex> ExDataCheck.ValidationResult.success?(validation)
      false

  """
  @spec success?(t()) :: boolean()
  def success?(%__MODULE__{success: success}), do: success

  @doc """
  Returns true if any expectation failed.

  ## Examples

      iex> results = [ExDataCheck.ExpectationResult.new(true, "test", %{})]
      iex> validation = ExDataCheck.ValidationResult.new(results, %{})
      iex> ExDataCheck.ValidationResult.failed?(validation)
      false

      iex> results = [
      ...>   ExDataCheck.ExpectationResult.new(true, "test 1", %{}),
      ...>   ExDataCheck.ExpectationResult.new(false, "test 2", %{})
      ...> ]
      iex> validation = ExDataCheck.ValidationResult.new(results, %{})
      iex> ExDataCheck.ValidationResult.failed?(validation)
      true

  """
  @spec failed?(t()) :: boolean()
  def failed?(%__MODULE__{success: success}), do: !success

  @doc """
  Returns only the failed expectation results.

  ## Examples

      iex> results = [
      ...>   ExDataCheck.ExpectationResult.new(true, "test 1", %{}),
      ...>   ExDataCheck.ExpectationResult.new(false, "test 2", %{}),
      ...>   ExDataCheck.ExpectationResult.new(false, "test 3", %{})
      ...> ]
      iex> validation = ExDataCheck.ValidationResult.new(results, %{})
      iex> failed = ExDataCheck.ValidationResult.failed_expectations(validation)
      iex> length(failed)
      2
      iex> Enum.all?(failed, &(&1.success == false))
      true

  """
  @spec failed_expectations(t()) :: list(ExpectationResult.t())
  def failed_expectations(%__MODULE__{results: results}) do
    Enum.filter(results, &ExpectationResult.failed?/1)
  end

  @doc """
  Returns only the passed expectation results.

  ## Examples

      iex> results = [
      ...>   ExDataCheck.ExpectationResult.new(true, "test 1", %{}),
      ...>   ExDataCheck.ExpectationResult.new(false, "test 2", %{}),
      ...>   ExDataCheck.ExpectationResult.new(true, "test 3", %{})
      ...> ]
      iex> validation = ExDataCheck.ValidationResult.new(results, %{})
      iex> passed = ExDataCheck.ValidationResult.passed_expectations(validation)
      iex> length(passed)
      2
      iex> Enum.all?(passed, &(&1.success == true))
      true

  """
  @spec passed_expectations(t()) :: list(ExpectationResult.t())
  def passed_expectations(%__MODULE__{results: results}) do
    Enum.filter(results, &ExpectationResult.success?/1)
  end
end
