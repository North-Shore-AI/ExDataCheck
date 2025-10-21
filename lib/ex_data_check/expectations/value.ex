defmodule ExDataCheck.Expectations.Value do
  @moduledoc """
  Value-based expectations for data validation.

  Value expectations test individual values in a column against defined criteria
  such as ranges, sets, patterns, nullability, uniqueness, and ordering.

  ## Examples

      # Range validation
      expect_column_values_to_be_between(:age, 0, 120)

      # Set membership
      expect_column_values_to_be_in_set(:status, ["active", "pending", "completed"])

      # Pattern matching
      expect_column_values_to_match_regex(:email, ~r/@/)

      # Null checking
      expect_column_values_to_not_be_null(:user_id)

      # Uniqueness
      expect_column_values_to_be_unique(:email)

  ## Design Principles

  - **Value-Level Validation**: Focus on individual data values
  - **Nil Handling**: Most expectations ignore nil values by default
  - **Type Flexibility**: Works with various data types (numbers, strings, atoms, lists)
  - **Detailed Feedback**: Provides failing examples and counts

  """

  alias ExDataCheck.{Expectation, ExpectationResult}
  alias ExDataCheck.Validator.ColumnExtractor

  @doc """
  Expects all non-nil values in a column to fall within a specified range (inclusive).

  ## Parameters

    * `column` - Column name (atom or string)
    * `min` - Minimum value (inclusive)
    * `max` - Maximum value (inclusive)

  ## Examples

      iex> dataset = [%{age: 25}, %{age: 30}, %{age: 35}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_values_to_be_between(:age, 20, 40)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

      iex> dataset = [%{age: 25}, %{age: 150}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_values_to_be_between(:age, 0, 120)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      false

  """
  @spec expect_column_values_to_be_between(atom() | String.t(), number(), number()) ::
          Expectation.t()
  def expect_column_values_to_be_between(column, min, max) do
    validator = fn dataset ->
      values =
        dataset
        |> ColumnExtractor.extract(column)
        |> Enum.reject(&is_nil/1)

      failing = Enum.filter(values, fn v -> v < min or v > max end)

      observed = %{
        total_values: length(values),
        failing_values: length(failing),
        failing_examples: Enum.take(failing, 5),
        min: min,
        max: max
      }

      ExpectationResult.new(
        length(failing) == 0,
        "expect column #{inspect(column)} values to be between #{min} and #{max}",
        observed,
        %{min: min, max: max}
      )
    end

    Expectation.new(:value_range, column, validator, %{min: min, max: max})
  end

  @doc """
  Expects all non-nil values in a column to be members of a specified set.

  ## Parameters

    * `column` - Column name (atom or string)
    * `allowed_values` - List of allowed values

  ## Examples

      iex> dataset = [%{status: "active"}, %{status: "pending"}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_values_to_be_in_set(:status, ["active", "pending", "completed"])
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

      iex> dataset = [%{status: "active"}, %{status: "invalid"}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_values_to_be_in_set(:status, ["active", "pending"])
      iex> result = expectation.validator.(dataset)
      iex> result.success
      false

  """
  @spec expect_column_values_to_be_in_set(atom() | String.t(), list(any())) :: Expectation.t()
  def expect_column_values_to_be_in_set(column, allowed_values) do
    validator = fn dataset ->
      values =
        dataset
        |> ColumnExtractor.extract(column)
        |> Enum.reject(&is_nil/1)

      allowed_set = MapSet.new(allowed_values)
      failing = Enum.reject(values, fn v -> MapSet.member?(allowed_set, v) end)

      observed = %{
        total_values: length(values),
        failing_values: length(failing),
        failing_examples: Enum.take(failing, 5),
        allowed_values: allowed_values
      }

      ExpectationResult.new(
        length(failing) == 0,
        "expect column #{inspect(column)} values to be in set #{inspect(allowed_values)}",
        observed,
        %{allowed_values: allowed_values}
      )
    end

    Expectation.new(:value_set, column, validator, %{allowed_values: allowed_values})
  end

  @doc """
  Expects all non-nil string values in a column to match a regular expression.

  Non-string values are considered failures.

  ## Parameters

    * `column` - Column name (atom or string)
    * `pattern` - Regular expression pattern

  ## Examples

      iex> dataset = [%{email: "alice@example.com"}, %{email: "bob@test.org"}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_values_to_match_regex(:email, ~r/@/)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

      iex> dataset = [%{email: "alice@example.com"}, %{email: "invalid"}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_values_to_match_regex(:email, ~r/^[^@]+@[^@]+\\.[^@]+$/)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      false

  """
  @spec expect_column_values_to_match_regex(atom() | String.t(), Regex.t()) :: Expectation.t()
  def expect_column_values_to_match_regex(column, pattern) do
    validator = fn dataset ->
      values =
        dataset
        |> ColumnExtractor.extract(column)
        |> Enum.reject(&is_nil/1)

      failing =
        Enum.reject(values, fn v ->
          is_binary(v) and Regex.match?(pattern, v)
        end)

      observed = %{
        total_values: length(values),
        failing_values: length(failing),
        failing_examples: Enum.take(failing, 5),
        pattern: inspect(pattern)
      }

      ExpectationResult.new(
        length(failing) == 0,
        "expect column #{inspect(column)} values to match regex #{inspect(pattern)}",
        observed,
        %{pattern: pattern}
      )
    end

    Expectation.new(:value_regex, column, validator, %{pattern: pattern})
  end

  @doc """
  Expects no null (nil) values in a column.

  Missing keys are also considered null.

  ## Parameters

    * `column` - Column name (atom or string)

  ## Examples

      iex> dataset = [%{user_id: 1}, %{user_id: 2}, %{user_id: 3}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_values_to_not_be_null(:user_id)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

      iex> dataset = [%{user_id: 1}, %{user_id: nil}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_values_to_not_be_null(:user_id)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      false

  """
  @spec expect_column_values_to_not_be_null(atom() | String.t()) :: Expectation.t()
  def expect_column_values_to_not_be_null(column) do
    validator = fn dataset ->
      values = ColumnExtractor.extract(dataset, column)
      null_count = Enum.count(values, &is_nil/1)

      observed = %{
        total_values: length(values),
        null_count: null_count,
        non_null_count: length(values) - null_count
      }

      ExpectationResult.new(
        null_count == 0,
        "expect column #{inspect(column)} to have no null values",
        observed,
        %{column: column}
      )
    end

    Expectation.new(:not_null, column, validator, %{})
  end

  @doc """
  Expects all non-nil values in a column to be unique.

  Nil values are ignored and not checked for uniqueness.

  ## Parameters

    * `column` - Column name (atom or string)

  ## Examples

      iex> dataset = [%{user_id: 1}, %{user_id: 2}, %{user_id: 3}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_values_to_be_unique(:user_id)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

      iex> dataset = [%{user_id: 1}, %{user_id: 2}, %{user_id: 1}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_values_to_be_unique(:user_id)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      false

  """
  @spec expect_column_values_to_be_unique(atom() | String.t()) :: Expectation.t()
  def expect_column_values_to_be_unique(column) do
    validator = fn dataset ->
      values =
        dataset
        |> ColumnExtractor.extract(column)
        |> Enum.reject(&is_nil/1)

      frequencies = Enum.frequencies(values)
      duplicates = Enum.filter(frequencies, fn {_value, count} -> count > 1 end)
      duplicate_values = Enum.map(duplicates, fn {value, _count} -> value end)

      observed = %{
        total_values: length(values),
        unique_values: map_size(frequencies),
        duplicate_count: length(duplicates),
        duplicate_examples: Enum.take(duplicate_values, 5)
      }

      ExpectationResult.new(
        length(duplicates) == 0,
        "expect column #{inspect(column)} values to be unique",
        observed,
        %{column: column}
      )
    end

    Expectation.new(:unique, column, validator, %{})
  end

  @doc """
  Expects values in a column to be in strictly increasing order.

  Nil values are removed before checking. Equal consecutive values are considered a violation.

  ## Parameters

    * `column` - Column name (atom or string)

  ## Examples

      iex> dataset = [%{timestamp: 1}, %{timestamp: 2}, %{timestamp: 3}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_values_to_be_increasing(:timestamp)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

      iex> dataset = [%{timestamp: 1}, %{timestamp: 3}, %{timestamp: 2}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_values_to_be_increasing(:timestamp)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      false

  """
  @spec expect_column_values_to_be_increasing(atom() | String.t()) :: Expectation.t()
  def expect_column_values_to_be_increasing(column) do
    validator = fn dataset ->
      values =
        dataset
        |> ColumnExtractor.extract(column)
        |> Enum.reject(&is_nil/1)

      violations = count_order_violations(values, :increasing)

      observed = %{
        total_values: length(values),
        violations: violations,
        is_increasing: violations == 0
      }

      ExpectationResult.new(
        violations == 0,
        "expect column #{inspect(column)} values to be in increasing order",
        observed,
        %{column: column}
      )
    end

    Expectation.new(:increasing, column, validator, %{})
  end

  @doc """
  Expects values in a column to be in strictly decreasing order.

  Nil values are removed before checking. Equal consecutive values are considered a violation.

  ## Parameters

    * `column` - Column name (atom or string)

  ## Examples

      iex> dataset = [%{temperature: 100}, %{temperature: 75}, %{temperature: 50}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_values_to_be_decreasing(:temperature)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

      iex> dataset = [%{temperature: 100}, %{temperature: 50}, %{temperature: 75}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_values_to_be_decreasing(:temperature)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      false

  """
  @spec expect_column_values_to_be_decreasing(atom() | String.t()) :: Expectation.t()
  def expect_column_values_to_be_decreasing(column) do
    validator = fn dataset ->
      values =
        dataset
        |> ColumnExtractor.extract(column)
        |> Enum.reject(&is_nil/1)

      violations = count_order_violations(values, :decreasing)

      observed = %{
        total_values: length(values),
        violations: violations,
        is_decreasing: violations == 0
      }

      ExpectationResult.new(
        violations == 0,
        "expect column #{inspect(column)} values to be in decreasing order",
        observed,
        %{column: column}
      )
    end

    Expectation.new(:decreasing, column, validator, %{})
  end

  @doc """
  Expects the length of non-nil values in a column to fall within a specified range.

  Works with strings (byte size), lists (length), and any value that implements `Enumerable`.

  ## Parameters

    * `column` - Column name (atom or string)
    * `min_length` - Minimum length (inclusive)
    * `max_length` - Maximum length (inclusive)

  ## Examples

      iex> dataset = [%{name: "Alice"}, %{name: "Bob"}, %{name: "Charlie"}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_value_lengths_to_be_between(:name, 2, 10)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

      iex> dataset = [%{name: "A"}, %{name: "Bob"}]
      iex> expectation = ExDataCheck.Expectations.Value.expect_column_value_lengths_to_be_between(:name, 2, 10)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      false

  """
  @spec expect_column_value_lengths_to_be_between(
          atom() | String.t(),
          non_neg_integer(),
          non_neg_integer()
        ) :: Expectation.t()
  def expect_column_value_lengths_to_be_between(column, min_length, max_length) do
    validator = fn dataset ->
      values =
        dataset
        |> ColumnExtractor.extract(column)
        |> Enum.reject(&is_nil/1)

      failing =
        Enum.reject(values, fn v ->
          length = get_length(v)
          length >= min_length and length <= max_length
        end)

      observed = %{
        total_values: length(values),
        failing_values: length(failing),
        failing_examples: Enum.take(failing, 5),
        min_length: min_length,
        max_length: max_length
      }

      ExpectationResult.new(
        length(failing) == 0,
        "expect column #{inspect(column)} value lengths to be between #{min_length} and #{max_length}",
        observed,
        %{min_length: min_length, max_length: max_length}
      )
    end

    Expectation.new(:value_length_range, column, validator, %{
      min_length: min_length,
      max_length: max_length
    })
  end

  # Private helper functions

  @spec count_order_violations(list(any()), :increasing | :decreasing) :: non_neg_integer()
  defp count_order_violations(values, _order) when length(values) <= 1, do: 0

  defp count_order_violations(values, order) do
    values
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.count(fn [a, b] ->
      case order do
        :increasing -> a >= b
        :decreasing -> a <= b
      end
    end)
  end

  @spec get_length(any()) :: non_neg_integer()
  defp get_length(value) when is_binary(value), do: String.length(value)
  defp get_length(value) when is_list(value), do: length(value)

  defp get_length(value) do
    # Try to enumerate it
    try do
      Enum.count(value)
    rescue
      Protocol.UndefinedError -> 0
    end
  end
end
