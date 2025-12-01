defmodule ExDataCheck.Stage do
  @moduledoc """
  Pipeline stage for data validation.

  Uses ExDataCheck expectations for data quality checks within pipeline workflows.
  This module provides a standard interface for integrating data validation into
  data processing pipelines.

  ## Usage

  The stage expects context to contain:
  - `:dataset` or `:examples` - The data to validate
  - Optional `:expectations` - List of validation expectations

  Configuration options:
  - `:expectations` - List of expectations to run
  - `:fail_fast` - Whether to raise on validation failure (default: false)
  - `:profile` - Whether to include profiling in results (default: false)

  ## Examples

      # Basic validation
      context = %{dataset: data}
      opts = %{expectations: [
        ExDataCheck.expect_column_to_exist(:age),
        ExDataCheck.expect_column_values_to_be_between(:age, 0, 120)
      ]}

      result = ExDataCheck.Stage.run(context, opts)

      # With profiling
      opts = %{
        expectations: expectations,
        profile: true
      }
      result = ExDataCheck.Stage.run(context, opts)

      # Fail fast mode
      opts = %{
        expectations: expectations,
        fail_fast: true
      }
      result = ExDataCheck.Stage.run(context, opts)  # Raises on failure

  """

  @doc """
  Runs data validation on context data.

  Expects context to have:
  - `dataset` or `examples` - Data to validate
  - Optional expectations config in opts

  Returns updated context with `:data_validation` results.

  ## Parameters

  - `context` - Map containing the dataset under `:dataset` or `:examples` key
  - `opts` - Map of configuration options:
    - `:expectations` - List of expectations to validate (required)
    - `:fail_fast` - Boolean, whether to raise on validation failure (default: false)
    - `:profile` - Boolean, whether to include data profiling (default: false)

  ## Returns

  Updated context with `:data_validation` key containing:
  - `:validation_result` - The ValidationResult struct
  - `:profile` - Data profile (if profile: true)
  - `:passed` - Boolean indicating if all validations passed

  ## Examples

      iex> dataset = [%{age: 25, name: "Alice"}]
      iex> context = %{dataset: dataset}
      iex> opts = %{expectations: [ExDataCheck.expect_column_to_exist(:age)]}
      iex> result = ExDataCheck.Stage.run(context, opts)
      iex> result.data_validation.passed
      true

  """
  @spec run(map(), map()) :: map()
  def run(context, opts \\ %{})

  def run(context, opts) when is_map(context) and is_map(opts) do
    # Extract dataset from context
    dataset = extract_dataset(context)

    # Get expectations from opts
    expectations = Map.get(opts, :expectations, [])
    fail_fast = Map.get(opts, :fail_fast, false)
    include_profile = Map.get(opts, :profile, false)

    # Validate expectations exist
    if expectations == [] do
      raise ArgumentError, "Stage requires :expectations to be provided in opts"
    end

    # Run validation
    validation_result =
      if fail_fast do
        ExDataCheck.validate!(dataset, expectations)
      else
        ExDataCheck.validate(dataset, expectations)
      end

    # Optionally generate profile
    profile =
      if include_profile do
        ExDataCheck.profile(dataset)
      else
        nil
      end

    # Build validation summary
    validation_summary = %{
      validation_result: validation_result,
      profile: profile,
      passed: validation_result.success,
      expectations_met: validation_result.expectations_met,
      expectations_failed: validation_result.expectations_failed,
      total_expectations: validation_result.total_expectations
    }

    # Add to context
    Map.put(context, :data_validation, validation_summary)
  end

  @doc """
  Returns a description of the stage configuration.

  ## Parameters

  - `opts` - Map of configuration options

  ## Returns

  A string describing the stage configuration.

  ## Examples

      iex> opts = %{expectations: [ExDataCheck.expect_column_to_exist(:age)]}
      iex> ExDataCheck.Stage.describe(opts)
      "Data validation stage with 1 expectation(s)"

  """
  @spec describe(map()) :: String.t()
  def describe(opts \\ %{}) do
    expectations = Map.get(opts, :expectations, [])
    count = length(expectations)
    fail_fast = Map.get(opts, :fail_fast, false)
    include_profile = Map.get(opts, :profile, false)

    base = "Data validation stage with #{count} expectation(s)"

    modifiers = []
    modifiers = if fail_fast, do: modifiers ++ ["fail-fast"], else: modifiers
    modifiers = if include_profile, do: modifiers ++ ["profiling"], else: modifiers

    if modifiers != [] do
      base <> " (" <> Enum.join(modifiers, ", ") <> ")"
    else
      base
    end
  end

  # Private helper to extract dataset from context
  defp extract_dataset(context) do
    cond do
      Map.has_key?(context, :dataset) ->
        Map.get(context, :dataset)

      Map.has_key?(context, :examples) ->
        Map.get(context, :examples)

      true ->
        raise ArgumentError,
              "Stage context must contain :dataset or :examples key. Got: #{inspect(Map.keys(context))}"
    end
  end
end
