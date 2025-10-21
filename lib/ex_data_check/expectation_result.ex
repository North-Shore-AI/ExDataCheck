defmodule ExDataCheck.ExpectationResult do
  @moduledoc """
  Represents the result of executing a single expectation against a dataset.

  An ExpectationResult contains:
  - `success`: Boolean indicating if the expectation was met
  - `expectation`: Human-readable description of what was expected
  - `observed`: Map containing observed values, failing values, and examples
  - `metadata`: Additional context from the expectation

  ## Examples

      iex> result = ExDataCheck.ExpectationResult.new(
      ...>   true,
      ...>   "column age values between 0 and 120",
      ...>   %{total_values: 100, failing_values: 0}
      ...> )
      iex> result.success
      true
      iex> ExDataCheck.ExpectationResult.success?(result)
      true

      iex> result = ExDataCheck.ExpectationResult.new(
      ...>   false,
      ...>   "column age values between 0 and 120",
      ...>   %{total_values: 100, failing_values: 2, failing_examples: [150, 200]}
      ...> )
      iex> result.success
      false
      iex> ExDataCheck.ExpectationResult.failed?(result)
      true

  ## Observed Data Structure

  The `observed` field typically contains:
  - `total_values`: Total number of values checked
  - `failing_values`: Number of values that failed the expectation
  - `failing_examples`: Sample of failing values (usually first 5)
  - Additional metrics specific to the expectation type

  """

  @typedoc """
  Observed data from expectation validation.

  Common fields:
  - `:total_values` - Total values validated
  - `:failing_values` - Count of failing values
  - `:failing_examples` - Sample of failing values
  - `:passing_values` - Count of passing values (optional)
  - Type-specific metrics (mean, median, etc.)
  """
  @type observed :: map()

  @type t :: %__MODULE__{
          success: boolean(),
          expectation: String.t(),
          observed: observed(),
          metadata: map()
        }

  defstruct [:success, :expectation, :observed, metadata: %{}]

  @doc """
  Creates a new ExpectationResult.

  ## Parameters

    * `success` - Boolean indicating if the expectation was met
    * `expectation` - Human-readable description of the expectation
    * `observed` - Map of observed values and metrics
    * `metadata` - Optional metadata from the expectation (defaults to empty map)

  ## Examples

      iex> ExDataCheck.ExpectationResult.new(
      ...>   true,
      ...>   "column age values between 0 and 120",
      ...>   %{total_values: 100, failing_values: 0}
      ...> )
      %ExDataCheck.ExpectationResult{
        success: true,
        expectation: "column age values between 0 and 120",
        observed: %{total_values: 100, failing_values: 0},
        metadata: %{}
      }

      iex> ExDataCheck.ExpectationResult.new(
      ...>   false,
      ...>   "column age not null",
      ...>   %{total_values: 100, null_count: 5},
      ...>   %{column: :age}
      ...> )
      %ExDataCheck.ExpectationResult{
        success: false,
        expectation: "column age not null",
        observed: %{total_values: 100, null_count: 5},
        metadata: %{column: :age}
      }

  """
  @spec new(boolean(), String.t(), observed(), map()) :: t()
  def new(success, expectation, observed, metadata \\ %{}) do
    %__MODULE__{
      success: success,
      expectation: expectation,
      observed: observed,
      metadata: metadata
    }
  end

  @doc """
  Returns true if the expectation was met.

  ## Examples

      iex> result = ExDataCheck.ExpectationResult.new(true, "test", %{})
      iex> ExDataCheck.ExpectationResult.success?(result)
      true

      iex> result = ExDataCheck.ExpectationResult.new(false, "test", %{})
      iex> ExDataCheck.ExpectationResult.success?(result)
      false

  """
  @spec success?(t()) :: boolean()
  def success?(%__MODULE__{success: success}), do: success

  @doc """
  Returns true if the expectation failed.

  ## Examples

      iex> result = ExDataCheck.ExpectationResult.new(true, "test", %{})
      iex> ExDataCheck.ExpectationResult.failed?(result)
      false

      iex> result = ExDataCheck.ExpectationResult.new(false, "test", %{})
      iex> ExDataCheck.ExpectationResult.failed?(result)
      true

  """
  @spec failed?(t()) :: boolean()
  def failed?(%__MODULE__{success: success}), do: !success
end
