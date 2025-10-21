defmodule ExDataCheck.Validator.ColumnExtractor do
  @moduledoc """
  Utilities for extracting column data from datasets.

  Supports multiple dataset formats:
  - List of maps with atom or string keys
  - List of keyword lists
  - Streams (for large datasets)

  Provides flexible column access with automatic key normalization
  between atoms and strings.

  ## Examples

      iex> dataset = [%{age: 25, name: "Alice"}, %{age: 30, name: "Bob"}]
      iex> ExDataCheck.Validator.ColumnExtractor.extract(dataset, :age)
      [25, 30]

      iex> dataset = [%{"age" => 25}, %{"age" => 30}]
      iex> ExDataCheck.Validator.ColumnExtractor.extract(dataset, :age)
      [25, 30]

      iex> dataset = [%{age: 25}, %{name: "Bob"}]
      iex> ExDataCheck.Validator.ColumnExtractor.column_exists?(dataset, :age)
      true

  ## Design Principles

  - **Flexible Key Access**: Automatically handles both atom and string keys
  - **Nil Handling**: Missing values are represented as nil
  - **Performance**: Optimized for common case (maps with atom keys)
  - **Streaming Support**: Works with lazy enumerables for large datasets

  """

  @typedoc """
  Dataset row - can be a map or keyword list.
  """
  @type row :: map() | keyword()

  @typedoc """
  Dataset - list of rows or stream.
  """
  @type dataset :: list(row()) | Enumerable.t()

  @typedoc """
  Column identifier - atom or string.
  """
  @type column :: atom() | String.t()

  @doc """
  Extracts all values for a given column from the dataset.

  Returns a list of values in the same order as the dataset rows.
  Missing values are represented as nil.

  ## Parameters

    * `dataset` - List of maps or keyword lists
    * `column` - Column name (atom or string)

  ## Examples

      iex> dataset = [%{age: 25}, %{age: 30}, %{age: 35}]
      iex> ExDataCheck.Validator.ColumnExtractor.extract(dataset, :age)
      [25, 30, 35]

      iex> dataset = [%{age: 25}, %{name: "Bob"}, %{age: 35}]
      iex> ExDataCheck.Validator.ColumnExtractor.extract(dataset, :age)
      [25, nil, 35]

      iex> dataset = [%{"age" => 25}, %{"age" => 30}]
      iex> ExDataCheck.Validator.ColumnExtractor.extract(dataset, :age)
      [25, 30]

      iex> ExDataCheck.Validator.ColumnExtractor.extract([], :age)
      []

  """
  @spec extract(dataset(), column()) :: list(any())
  def extract(dataset, column) do
    Enum.map(dataset, fn row -> get_value(row, column) end)
  end

  @doc """
  Checks if a column exists in the dataset.

  Returns true if the column exists in at least one row.

  ## Parameters

    * `dataset` - List of maps or keyword lists
    * `column` - Column name (atom or string)

  ## Examples

      iex> dataset = [%{age: 25, name: "Alice"}, %{age: 30, name: "Bob"}]
      iex> ExDataCheck.Validator.ColumnExtractor.column_exists?(dataset, :age)
      true

      iex> dataset = [%{age: 25}, %{name: "Bob"}]
      iex> ExDataCheck.Validator.ColumnExtractor.column_exists?(dataset, :email)
      false

      iex> ExDataCheck.Validator.ColumnExtractor.column_exists?([], :age)
      false

  """
  @spec column_exists?(dataset(), column()) :: boolean()
  def column_exists?(dataset, column) do
    Enum.any?(dataset, fn row -> has_key?(row, column) end)
  end

  @doc """
  Returns all unique column names from the dataset.

  Scans all rows and collects unique column names.

  ## Parameters

    * `dataset` - List of maps or keyword lists

  ## Examples

      iex> dataset = [%{age: 25, name: "Alice"}, %{age: 30, email: "bob@example.com"}]
      iex> columns = ExDataCheck.Validator.ColumnExtractor.columns(dataset)
      iex> :age in columns
      true
      iex> :name in columns
      true
      iex> :email in columns
      true

      iex> ExDataCheck.Validator.ColumnExtractor.columns([])
      []

  """
  @spec columns(dataset()) :: list(atom() | String.t())
  def columns(dataset) do
    dataset
    |> Enum.flat_map(&get_keys/1)
    |> Enum.uniq()
  end

  @doc """
  Counts non-nil values in a column.

  ## Parameters

    * `dataset` - List of maps or keyword lists
    * `column` - Column name (atom or string)

  ## Examples

      iex> dataset = [%{age: 25}, %{age: nil}, %{age: 30}]
      iex> ExDataCheck.Validator.ColumnExtractor.count_non_null(dataset, :age)
      2

      iex> dataset = [%{age: 25}, %{age: 30}, %{age: 35}]
      iex> ExDataCheck.Validator.ColumnExtractor.count_non_null(dataset, :age)
      3

      iex> ExDataCheck.Validator.ColumnExtractor.count_non_null([], :age)
      0

  """
  @spec count_non_null(dataset(), column()) :: non_neg_integer()
  def count_non_null(dataset, column) do
    dataset
    |> extract(column)
    |> Enum.count(&(!is_nil(&1)))
  end

  # Private functions

  # Gets value from row, trying both atom and string keys
  @spec get_value(row(), column()) :: any()
  defp get_value(row, column) when is_map(row) do
    cond do
      Map.has_key?(row, column) ->
        Map.get(row, column)

      is_atom(column) and Map.has_key?(row, Atom.to_string(column)) ->
        Map.get(row, Atom.to_string(column))

      is_binary(column) ->
        atom_key = String.to_existing_atom(column)
        Map.get(row, atom_key, nil)

      true ->
        nil
    end
  rescue
    ArgumentError ->
      # String.to_existing_atom fails if atom doesn't exist
      nil
  end

  defp get_value(row, column) when is_list(row) do
    Keyword.get(row, column)
  end

  # Checks if row has the given key
  @spec has_key?(row(), column()) :: boolean()
  defp has_key?(row, column) when is_map(row) do
    Map.has_key?(row, column) or
      (is_atom(column) and Map.has_key?(row, Atom.to_string(column))) or
      (is_binary(column) and
         try do
           atom_key = String.to_existing_atom(column)
           Map.has_key?(row, atom_key)
         rescue
           ArgumentError -> false
         end)
  end

  defp has_key?(row, column) when is_list(row) do
    Keyword.has_key?(row, column)
  end

  # Gets all keys from a row
  @spec get_keys(row()) :: list(atom() | String.t())
  defp get_keys(row) when is_map(row) do
    Map.keys(row)
  end

  defp get_keys(row) when is_list(row) do
    Keyword.keys(row)
  end
end
