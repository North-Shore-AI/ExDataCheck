defmodule ExDataCheck.Correlation do
  @moduledoc """
  Correlation analysis utilities for feature relationships.

  Provides correlation calculations for understanding relationships between
  variables, essential for ML feature engineering and validation.

  ## Correlation Methods

  - **Pearson**: Measures linear correlation (-1 to 1)
  - **Spearman**: Measures monotonic correlation using ranks
  - **Correlation Matrix**: Pairwise correlations for multiple columns

  ## Examples

      iex> x = [1, 2, 3, 4, 5]
      iex> y = [2, 4, 6, 8, 10]
      iex> ExDataCheck.Correlation.pearson(x, y)
      1.0

      iex> x = [1, 2, 3, 4, 5]
      iex> y = [1, 4, 9, 16, 25]
      iex> corr = ExDataCheck.Correlation.spearman(x, y)
      iex> corr == 1.0
      true

  """

  alias ExDataCheck.{Statistics, Validator.ColumnExtractor}

  @doc """
  Calculates Pearson correlation coefficient between two numeric lists.

  Pearson correlation measures the linear relationship between variables.
  Returns a value between -1 (perfect negative correlation) and 1 (perfect positive correlation).

  Returns `nil` if:
  - Lists are different lengths
  - Either list is empty or has < 2 elements
  - Either list has zero variance

  ## Examples

      iex> ExDataCheck.Correlation.pearson([1, 2, 3], [2, 4, 6])
      1.0

      iex> ExDataCheck.Correlation.pearson([1, 2, 3], [3, 2, 1])
      -1.0

  """
  @spec pearson(list(number()), list(number())) :: float() | nil
  def pearson(x, y) when length(x) != length(y), do: nil
  def pearson(x, _y) when length(x) < 2, do: nil

  def pearson(x, y) do
    n = length(x)
    mean_x = Statistics.mean(x)
    mean_y = Statistics.mean(y)

    # Calculate covariance
    covariance =
      Enum.zip(x, y)
      |> Enum.map(fn {xi, yi} -> (xi - mean_x) * (yi - mean_y) end)
      |> Enum.sum()

    # Calculate standard deviations
    stdev_x = Statistics.stdev(x)
    stdev_y = Statistics.stdev(y)

    # Check for zero variance
    cond do
      is_nil(stdev_x) or is_nil(stdev_y) ->
        nil

      stdev_x == 0.0 or stdev_y == 0.0 ->
        nil

      true ->
        # Pearson correlation = covariance / (stdev_x * stdev_y)
        covariance / (n * stdev_x * stdev_y)
    end
  end

  @doc """
  Calculates Spearman rank correlation coefficient between two lists.

  Spearman correlation measures monotonic relationships using ranks rather
  than actual values. More robust to outliers than Pearson correlation.

  Returns a value between -1 and 1, or `nil` for invalid inputs.

  ## Examples

      iex> # Monotonic but non-linear
      iex> x = [1, 2, 3, 4, 5]
      iex> y = [1, 4, 9, 16, 25]
      iex> ExDataCheck.Correlation.spearman(x, y)
      1.0

  """
  @spec spearman(list(number()), list(number())) :: float() | nil
  def spearman(x, y) when length(x) != length(y), do: nil
  def spearman(x, _y) when length(x) < 2, do: nil

  def spearman(x, y) do
    # Convert to ranks
    rank_x = ranks(x)
    rank_y = ranks(y)

    # Calculate Pearson correlation on ranks
    pearson(rank_x, rank_y)
  end

  @doc """
  Calculates a correlation matrix for multiple columns in a dataset.

  Returns a nested map where `matrix[col1][col2]` contains the Pearson
  correlation between col1 and col2.

  ## Parameters

    * `dataset` - List of maps
    * `columns` - List of column names to include in the matrix

  ## Examples

      iex> dataset = [%{a: 1, b: 2}, %{a: 2, b: 4}, %{a: 3, b: 6}]
      iex> matrix = ExDataCheck.Correlation.correlation_matrix(dataset, [:a, :b])
      iex> matrix[:a][:a]
      1.0

  """
  @spec correlation_matrix(list(map()), list(atom() | String.t())) :: map()
  def correlation_matrix(dataset, columns) do
    # Extract values for each column
    column_data =
      columns
      |> Enum.map(fn col ->
        values =
          dataset
          |> ColumnExtractor.extract(col)
          |> Enum.reject(&is_nil/1)

        {col, values}
      end)
      |> Enum.into(%{})

    # Calculate pairwise correlations
    columns
    |> Enum.map(fn col1 ->
      correlations =
        columns
        |> Enum.map(fn col2 ->
          corr =
            if col1 == col2 do
              1.0
            else
              pearson(column_data[col1], column_data[col2]) || 0.0
            end

          {col2, corr}
        end)
        |> Enum.into(%{})

      {col1, correlations}
    end)
    |> Enum.into(%{})
  end

  # Private functions

  @spec ranks(list(number())) :: list(float())
  defp ranks(values) do
    # Create indexed values
    indexed = Enum.with_index(values)

    # Sort by value
    sorted = Enum.sort_by(indexed, fn {val, _idx} -> val end)

    # Assign ranks (handling ties with average rank)
    ranks_map =
      sorted
      |> assign_ranks()
      |> Enum.into(%{})

    # Return ranks in original order
    indexed
    |> Enum.map(fn {_val, idx} -> ranks_map[idx] end)
  end

  @spec assign_ranks(list({number(), integer()})) :: list({integer(), float()})
  defp assign_ranks(sorted_indexed) do
    sorted_indexed
    |> Enum.chunk_by(fn {val, _idx} -> val end)
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {group, start_rank} ->
      group_size = length(group)
      # Average rank for tied values
      avg_rank = (start_rank + start_rank + group_size - 1) / 2

      Enum.map(group, fn {_val, orig_idx} ->
        {orig_idx, avg_rank}
      end)
    end)
  end
end
