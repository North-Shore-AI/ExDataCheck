defmodule ExDataCheck.Expectations.Schema do
  @moduledoc """
  Schema-based expectations for data validation.

  Schema expectations validate the structure and metadata of datasets:
  - Column existence
  - Column types
  - Column counts
  - Row counts

  ## Examples

      # Check if column exists
      expectation = expect_column_to_exist(:age)

      # Verify column type
      expectation = expect_column_to_be_of_type(:age, :integer)

      # Validate column count
      expectation = expect_column_count_to_equal(10)

  ## Design Principles

  - **Structure Validation**: Focus on dataset structure rather than values
  - **Type Safety**: Ensure data conforms to expected types
  - **Early Detection**: Catch schema issues before value validation

  """

  alias ExDataCheck.{Expectation, ExpectationResult}
  alias ExDataCheck.Validator.ColumnExtractor

  @doc """
  Expects a column to exist in the dataset.

  Returns success if the column exists in at least one row.

  ## Parameters

    * `column` - Column name (atom or string)

  ## Examples

      iex> dataset = [%{age: 25, name: "Alice"}, %{age: 30, name: "Bob"}]
      iex> expectation = ExDataCheck.Expectations.Schema.expect_column_to_exist(:age)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

      iex> dataset = [%{name: "Alice"}, %{name: "Bob"}]
      iex> expectation = ExDataCheck.Expectations.Schema.expect_column_to_exist(:age)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      false

  """
  @spec expect_column_to_exist(atom() | String.t()) :: Expectation.t()
  def expect_column_to_exist(column) do
    validator = fn dataset ->
      exists = ColumnExtractor.column_exists?(dataset, column)
      available_columns = ColumnExtractor.columns(dataset)

      observed =
        if exists do
          %{
            column: column,
            exists: true
          }
        else
          %{
            column: column,
            exists: false,
            available_columns: available_columns
          }
        end

      ExpectationResult.new(
        exists,
        "expect column #{inspect(column)} to exist",
        observed,
        %{column: column}
      )
    end

    Expectation.new(:column_exists, column, validator, %{})
  end

  @doc """
  Expects all non-nil values in a column to be of a specific type.

  Supported types:
  - `:integer` - Integer values
  - `:float` - Float values
  - `:string` - String/binary values
  - `:boolean` - Boolean values (true/false)
  - `:atom` - Atom values
  - `:list` - List values
  - `:map` - Map values

  Nil values are ignored by default.

  ## Parameters

    * `column` - Column name (atom or string)
    * `expected_type` - Expected type as atom

  ## Examples

      iex> dataset = [%{age: 25}, %{age: 30}, %{age: 35}]
      iex> expectation = ExDataCheck.Expectations.Schema.expect_column_to_be_of_type(:age, :integer)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

      iex> dataset = [%{age: "25"}, %{age: "30"}]
      iex> expectation = ExDataCheck.Expectations.Schema.expect_column_to_be_of_type(:age, :integer)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      false

  """
  @spec expect_column_to_be_of_type(atom() | String.t(), atom()) :: Expectation.t()
  def expect_column_to_be_of_type(column, expected_type) do
    validator = fn dataset ->
      values = ColumnExtractor.extract(dataset, column)
      non_nil_values = Enum.reject(values, &is_nil/1)

      incorrect_values =
        Enum.reject(non_nil_values, fn value ->
          value_matches_type?(value, expected_type)
        end)

      total_values = length(non_nil_values)
      incorrect_count = length(incorrect_values)
      success = incorrect_count == 0

      observed = %{
        column: column,
        expected_type: expected_type,
        total_values: total_values,
        incorrect_type_count: incorrect_count,
        incorrect_examples: Enum.take(incorrect_values, 5)
      }

      ExpectationResult.new(
        success,
        "expect column #{inspect(column)} values to be of type #{expected_type}",
        observed,
        %{expected_type: expected_type}
      )
    end

    Expectation.new(:column_type, column, validator, %{expected_type: expected_type})
  end

  @doc """
  Expects the dataset to have a specific number of columns.

  Counts unique columns across all rows in the dataset.

  ## Parameters

    * `expected_count` - Expected number of columns

  ## Examples

      iex> dataset = [%{a: 1, b: 2, c: 3}]
      iex> expectation = ExDataCheck.Expectations.Schema.expect_column_count_to_equal(3)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

      iex> dataset = [%{a: 1, b: 2}, %{c: 3, d: 4}]
      iex> expectation = ExDataCheck.Expectations.Schema.expect_column_count_to_equal(4)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

  """
  @spec expect_column_count_to_equal(non_neg_integer()) :: Expectation.t()
  def expect_column_count_to_equal(expected_count) do
    validator = fn dataset ->
      columns = ColumnExtractor.columns(dataset)
      actual_count = length(columns)
      success = actual_count == expected_count

      observed = %{
        expected_count: expected_count,
        actual_count: actual_count,
        columns: columns
      }

      ExpectationResult.new(
        success,
        "expect dataset to have #{expected_count} columns",
        observed,
        %{expected_count: expected_count}
      )
    end

    Expectation.new(:column_count, nil, validator, %{expected_count: expected_count})
  end

  # Private helper functions

  @spec value_matches_type?(any(), atom()) :: boolean()
  defp value_matches_type?(value, :integer), do: is_integer(value)
  defp value_matches_type?(value, :float), do: is_float(value)
  defp value_matches_type?(value, :string), do: is_binary(value)
  defp value_matches_type?(value, :boolean), do: is_boolean(value)
  defp value_matches_type?(value, :atom), do: is_atom(value)
  defp value_matches_type?(value, :list), do: is_list(value)
  defp value_matches_type?(value, :map), do: is_map(value)
  defp value_matches_type?(_value, _type), do: false
end
