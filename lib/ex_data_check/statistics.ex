defmodule ExDataCheck.Statistics do
  @moduledoc """
  Statistical utilities for data profiling.

  Provides common statistical functions for analyzing numeric data:
  - Basic statistics (min, max, mean, median)
  - Variability measures (standard deviation, variance)
  - Quantile calculations
  - Summary statistics

  ## Examples

      iex> values = [1, 2, 3, 4, 5]
      iex> ExDataCheck.Statistics.mean(values)
      3.0
      iex> ExDataCheck.Statistics.median(values)
      3
      iex> ExDataCheck.Statistics.stdev(values)
      1.4142135623730951

  """

  @typedoc """
  Statistical summary of a dataset.
  """
  @type summary :: %{
          count: non_neg_integer(),
          min: number() | nil,
          max: number() | nil,
          mean: float() | nil,
          median: number() | nil,
          stdev: float() | nil,
          variance: float() | nil,
          q25: float() | nil,
          q75: float() | nil
        }

  @doc """
  Returns the minimum value from a list.

  Returns `nil` for empty lists.

  ## Examples

      iex> ExDataCheck.Statistics.min([5, 2, 8, 1, 9])
      1

      iex> ExDataCheck.Statistics.min([])
      nil

  """
  @spec min(list(number())) :: number() | nil
  def min([]), do: nil
  def min(values), do: Enum.min(values)

  @doc """
  Returns the maximum value from a list.

  Returns `nil` for empty lists.

  ## Examples

      iex> ExDataCheck.Statistics.max([5, 2, 8, 1, 9])
      9

      iex> ExDataCheck.Statistics.max([])
      nil

  """
  @spec max(list(number())) :: number() | nil
  def max([]), do: nil
  def max(values), do: Enum.max(values)

  @doc """
  Calculates the arithmetic mean (average) of a list of numbers.

  Returns `nil` for empty lists.

  ## Examples

      iex> ExDataCheck.Statistics.mean([1, 2, 3, 4, 5])
      3.0

      iex> ExDataCheck.Statistics.mean([10, 20, 30])
      20.0

      iex> ExDataCheck.Statistics.mean([])
      nil

  """
  @spec mean(list(number())) :: float() | nil
  def mean([]), do: nil

  def mean(values) do
    Enum.sum(values) / length(values)
  end

  @doc """
  Calculates the median (middle value) of a list of numbers.

  For lists with odd length, returns the middle value.
  For lists with even length, returns the average of the two middle values.

  Returns `nil` for empty lists.

  ## Examples

      iex> ExDataCheck.Statistics.median([1, 2, 3, 4, 5])
      3

      iex> ExDataCheck.Statistics.median([1, 2, 3, 4])
      2.5

      iex> ExDataCheck.Statistics.median([])
      nil

  """
  @spec median(list(number())) :: number() | nil
  def median([]), do: nil

  def median(values) do
    sorted = Enum.sort(values)
    mid = div(length(sorted), 2)

    if rem(length(sorted), 2) == 1 do
      Enum.at(sorted, mid)
    else
      (Enum.at(sorted, mid - 1) + Enum.at(sorted, mid)) / 2
    end
  end

  @doc """
  Calculates the population standard deviation.

  Standard deviation measures the amount of variation in a dataset.

  Returns `nil` for empty lists, `0.0` for single-element lists.

  ## Examples

      iex> values = [2, 4, 4, 4, 5, 5, 7, 9]
      iex> stdev = ExDataCheck.Statistics.stdev(values)
      iex> Float.round(stdev, 2)
      2.0

      iex> ExDataCheck.Statistics.stdev([5, 5, 5, 5])
      0.0

  """
  @spec stdev(list(number())) :: float() | nil
  def stdev([]), do: nil
  def stdev([_]), do: 0.0

  def stdev(values) do
    var = variance(values)
    if var, do: :math.sqrt(var), else: nil
  end

  @doc """
  Calculates the population variance.

  Variance measures the average squared deviation from the mean.

  Returns `nil` for empty lists, `0.0` for single-element lists.

  ## Examples

      iex> values = [2, 4, 4, 4, 5, 5, 7, 9]
      iex> var = ExDataCheck.Statistics.variance(values)
      iex> Float.round(var, 2)
      4.0

      iex> ExDataCheck.Statistics.variance([5, 5, 5, 5])
      0.0

  """
  @spec variance(list(number())) :: float() | nil
  def variance([]), do: nil
  def variance([_]), do: 0.0

  def variance(values) do
    avg = mean(values)

    sum_of_squares =
      values
      |> Enum.map(fn x -> :math.pow(x - avg, 2) end)
      |> Enum.sum()

    sum_of_squares / length(values)
  end

  @doc """
  Calculates the quantile (percentile) of a dataset.

  Uses linear interpolation between closest ranks.

  ## Parameters

    * `values` - List of numeric values
    * `p` - Quantile to calculate (0.0 to 1.0)
      - 0.25 = 25th percentile (Q1)
      - 0.50 = 50th percentile (median)
      - 0.75 = 75th percentile (Q3)

  Returns `nil` for empty lists.

  ## Examples

      iex> values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      iex> ExDataCheck.Statistics.quantile(values, 0.5)
      5.5

      iex> ExDataCheck.Statistics.quantile(values, 0.75)
      7.75

  """
  @spec quantile(list(number()), float()) :: float() | nil
  def quantile([], _p), do: nil

  def quantile(values, p) when p >= 0.0 and p <= 1.0 do
    sorted = Enum.sort(values)
    n = length(sorted)

    # Use linear interpolation
    position = p * (n - 1)
    lower_index = floor(position)
    upper_index = ceil(position)

    if lower_index == upper_index do
      Enum.at(sorted, lower_index)
    else
      lower_value = Enum.at(sorted, lower_index)
      upper_value = Enum.at(sorted, upper_index)
      fraction = position - lower_index

      lower_value + fraction * (upper_value - lower_value)
    end
  end

  @doc """
  Returns a comprehensive statistical summary of a dataset.

  Includes:
  - Count of values
  - Min, max, mean, median
  - Standard deviation and variance
  - 25th and 75th percentiles (Q1, Q3)

  ## Examples

      iex> values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      iex> summary = ExDataCheck.Statistics.summary(values)
      iex> summary.count
      10
      iex> summary.mean
      5.5
      iex> summary.median
      5.5

  """
  @spec summary(list(number())) :: summary()
  def summary(values) do
    %{
      count: length(values),
      min: min(values),
      max: max(values),
      mean: mean(values),
      median: median(values),
      stdev: stdev(values),
      variance: variance(values),
      q25: quantile(values, 0.25),
      q75: quantile(values, 0.75)
    }
  end
end
