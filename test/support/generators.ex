defmodule ExDataCheck.Generators do
  @moduledoc """
  Test data generators for property-based testing with StreamData.

  Provides generators for datasets, expectations, and validation scenarios
  to enable comprehensive property-based testing of ExDataCheck.
  """

  use ExUnitProperties

  @doc """
  Generates a random dataset as a list of maps.

  ## Examples

      iex> dataset <- ExDataCheck.Generators.dataset()
      [%{age: 25, name: "Alice"}, %{age: 30, name: "Bob"}]

  """
  def dataset do
    gen all(
          row_count <- integer(1..100),
          columns <- column_list()
        ) do
      for _ <- 1..row_count do
        Enum.into(columns, %{})
      end
    end
  end

  @doc """
  Generates a list of column definitions with random values.
  """
  def column_list do
    gen all(
          column_count <- integer(1..10),
          columns <- list_of(column_with_value(), length: column_count)
        ) do
      columns
    end
  end

  @doc """
  Generates a single column with a random value.
  """
  def column_with_value do
    gen all(
          column_name <- column_name(),
          value <- column_value()
        ) do
      {column_name, value}
    end
  end

  @doc """
  Generates a valid column name (atom).
  """
  def column_name do
    member_of([
      :id,
      :name,
      :age,
      :email,
      :score,
      :status,
      :created_at,
      :updated_at,
      :value,
      :amount
    ])
  end

  @doc """
  Generates a random column value of various types.
  """
  def column_value do
    one_of([
      integer(0..1000),
      float(min: 0.0, max: 1000.0),
      string(:alphanumeric, min_length: 1, max_length: 50),
      boolean(),
      constant(nil)
    ])
  end

  @doc """
  Generates a simple dataset with consistent structure.
  """
  def simple_dataset do
    gen all(row_count <- integer(1..50)) do
      for i <- 1..row_count do
        %{
          id: i,
          age: :rand.uniform(100),
          score: :rand.uniform() * 100
        }
      end
    end
  end
end
