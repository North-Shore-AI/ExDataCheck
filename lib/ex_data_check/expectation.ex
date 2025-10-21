defmodule ExDataCheck.Expectation do
  @moduledoc """
  Defines the core Expectation struct and behavior for data validation.

  An Expectation represents a declarative assertion about data quality. Each
  expectation encapsulates a validation rule that can be executed against a dataset,
  returning structured results about whether the data meets the defined criteria.

  ## Expectation Structure

  An expectation consists of:
  - `type`: An atom identifying the expectation category (e.g., `:value_range`, `:not_null`)
  - `column`: The column name (atom or string) that the expectation validates
  - `validator`: A function that executes the validation logic
  - `metadata`: Additional context about the expectation (defaults, thresholds, etc.)

  ## Examples

      iex> validator_fn = fn dataset ->
      ...>   # Validation logic here
      ...>   %ExDataCheck.ExpectationResult{success: true}
      ...> end
      iex> expectation = ExDataCheck.Expectation.new(:value_range, :age, validator_fn, %{min: 0, max: 120})
      iex> expectation.type
      :value_range
      iex> expectation.column
      :age

  ## Validator Function Contract

  The validator function must accept a dataset and return an `ExpectationResult`:

      validator :: (dataset :: list(map()) -> ExpectationResult.t())

  ## Design Principles

  - **Declarative**: Expectations describe what should be true, not how to check
  - **Composable**: Expectations can be combined and chained
  - **Pure**: Validator functions should be pure with no side effects
  - **Informative**: Results include both success/failure and detailed context

  """

  @typedoc """
  The type of expectation being validated.

  Common types include:
  - `:column_exists` - Column presence validation
  - `:value_range` - Values within numeric range
  - `:value_set` - Values within allowed set
  - `:not_null` - No null/nil values
  - `:unique` - All values unique
  - `:mean_range` - Mean within range
  - `:stdev_range` - Standard deviation within range
  """
  @type expectation_type :: atom()

  @typedoc """
  Column identifier, can be atom or string.
  """
  @type column :: atom() | String.t()

  @typedoc """
  Validator function that executes the expectation logic.

  Accepts a dataset (list of maps) and returns an ExpectationResult.
  """
  @type validator_fn :: (dataset :: list(map()) -> ExDataCheck.ExpectationResult.t())

  @typedoc """
  Expectation metadata containing additional context.

  Common metadata fields:
  - `:min`, `:max` - Range boundaries
  - `:allowed_values` - Set of allowed values
  - `:pattern` - Regex pattern for matching
  - `:distribution` - Expected distribution parameters
  """
  @type metadata :: map()

  @type t :: %__MODULE__{
          type: expectation_type(),
          column: column(),
          validator: validator_fn(),
          metadata: metadata()
        }

  defstruct [:type, :column, :validator, metadata: %{}]

  @doc """
  Creates a new Expectation.

  ## Parameters

    * `type` - The expectation type as an atom
    * `column` - The column name (atom or string)
    * `validator` - A function that validates the expectation
    * `metadata` - Optional metadata map (defaults to empty map)

  ## Examples

      iex> validator = fn _dataset -> %ExDataCheck.ExpectationResult{success: true} end
      iex> exp = ExDataCheck.Expectation.new(:value_range, :age, validator, %{min: 0, max: 120})
      iex> exp.type
      :value_range
      iex> exp.column
      :age
      iex> exp.metadata
      %{min: 0, max: 120}

      iex> validator = fn _dataset -> %ExDataCheck.ExpectationResult{success: true} end
      iex> exp = ExDataCheck.Expectation.new(:not_null, :name, validator)
      iex> exp.metadata
      %{}

  """
  @spec new(expectation_type(), column(), validator_fn(), metadata()) :: t()
  def new(type, column, validator, metadata \\ %{}) do
    %__MODULE__{
      type: type,
      column: column,
      validator: validator,
      metadata: metadata
    }
  end
end
