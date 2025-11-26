defmodule ExDataCheck.Outliers do
  @moduledoc """
  Outlier detection utilities for data quality analysis.

  Provides multiple methods for detecting outliers in numeric data:
  - **IQR Method**: Based on interquartile range (Tukey's fences)
  - **Z-Score Method**: Based on standard deviations from mean

  ## Examples

      values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100, 200]

      # IQR method
      result = ExDataCheck.Outliers.detect_iqr(values)
      # => %{outliers: [100, 200], outlier_count: 2, ...}

      # Z-score method
      result = ExDataCheck.Outliers.detect_zscore(values, threshold: 3)
      # => %{outliers: [100, 200], outlier_count: 2, ...}

  ## Methods

  ### IQR Method
  - Calculates Q1 (25th percentile) and Q3 (75th percentile)
  - IQR = Q3 - Q1
  - Lower fence = Q1 - 1.5 * IQR
  - Upper fence = Q3 + 1.5 * IQR
  - Values outside fences are outliers

  ### Z-Score Method
  - Calculates mean and standard deviation
  - Z-score = (value - mean) / stdev
  - Values with |z| > threshold are outliers
  - Common threshold: 3 (99.7% of normal data within ±3σ)

  """

  alias ExDataCheck.Statistics

  @typedoc """
  Outlier detection result using IQR method.
  """
  @type iqr_result :: %{
          outliers: list(number()),
          outlier_count: non_neg_integer(),
          q1: float(),
          q3: float(),
          iqr: float(),
          lower_fence: float(),
          upper_fence: float()
        }

  @typedoc """
  Outlier detection result using Z-score method.
  """
  @type zscore_result :: %{
          outliers: list(number()),
          outlier_count: non_neg_integer(),
          mean: float(),
          stdev: float(),
          threshold: float(),
          z_scores: map()
        }

  @doc """
  Detects outliers using the Interquartile Range (IQR) method.

  Uses Tukey's fences: values outside Q1 - 1.5*IQR and Q3 + 1.5*IQR
  are considered outliers.

  ## Parameters

    * `values` - List of numeric values

  ## Returns

  Map containing:
  - `:outliers` - List of outlier values
  - `:outlier_count` - Number of outliers
  - `:q1`, `:q3`, `:iqr` - Quartile statistics
  - `:lower_fence`, `:upper_fence` - Fence boundaries

  ## Examples

      iex> values = [1, 2, 3, 4, 5, 100]
      iex> result = ExDataCheck.Outliers.detect_iqr(values)
      iex> 100 in result.outliers
      true

  """
  @spec detect_iqr(list(number())) :: iqr_result()
  def detect_iqr([]) do
    %{
      outliers: [],
      outlier_count: 0,
      q1: nil,
      q3: nil,
      iqr: nil,
      lower_fence: nil,
      upper_fence: nil
    }
  end

  def detect_iqr(values) do
    q1 = Statistics.quantile(values, 0.25)
    q3 = Statistics.quantile(values, 0.75)
    iqr = q3 - q1

    lower_fence = q1 - 1.5 * iqr
    upper_fence = q3 + 1.5 * iqr

    outliers =
      Enum.filter(values, fn v ->
        v < lower_fence or v > upper_fence
      end)

    %{
      outliers: outliers,
      outlier_count: length(outliers),
      q1: q1,
      q3: q3,
      iqr: iqr,
      lower_fence: lower_fence,
      upper_fence: upper_fence
    }
  end

  @doc """
  Detects outliers using the Z-score method.

  Values with absolute Z-score greater than threshold are outliers.

  ## Parameters

    * `values` - List of numeric values
    * `opts` - Options
      * `:threshold` - Z-score threshold (default: 3)

  ## Returns

  Map containing:
  - `:outliers` - List of outlier values
  - `:outlier_count` - Number of outliers
  - `:mean`, `:stdev` - Distribution statistics
  - `:threshold` - Threshold used
  - `:z_scores` - Map of values to their Z-scores

  ## Examples

      iex> values = [1, 2, 3, 4, 5, 100]
      iex> result = ExDataCheck.Outliers.detect_zscore(values, threshold: 3)
      iex> 100 in result.outliers
      true

  """
  @spec detect_zscore(list(number()), keyword()) :: zscore_result()
  def detect_zscore(values, opts \\ [])

  def detect_zscore([], _opts) do
    %{
      outliers: [],
      outlier_count: 0,
      mean: nil,
      stdev: nil,
      threshold: 3,
      z_scores: %{}
    }
  end

  def detect_zscore(values, opts) do
    threshold = Keyword.get(opts, :threshold, 3)
    mean = Statistics.mean(values)
    stdev = Statistics.stdev(values)

    cond do
      is_nil(stdev) ->
        %{
          outliers: [],
          outlier_count: 0,
          mean: mean,
          stdev: stdev,
          threshold: threshold,
          z_scores: %{}
        }

      stdev == 0.0 ->
        %{
          outliers: [],
          outlier_count: 0,
          mean: mean,
          stdev: stdev,
          threshold: threshold,
          z_scores: %{}
        }

      true ->
        z_scores =
          values
          |> Enum.map(fn v -> {v, abs((v - mean) / stdev)} end)
          |> Enum.into(%{})

        outliers =
          z_scores
          |> Enum.filter(fn {_v, z} -> z > threshold end)
          |> Enum.map(fn {v, _z} -> v end)

        %{
          outliers: outliers,
          outlier_count: length(outliers),
          mean: mean,
          stdev: stdev,
          threshold: threshold,
          z_scores: z_scores
        }
    end
  end

  @doc """
  Returns a summary of outliers using the specified method.

  ## Parameters

    * `values` - List of numeric values
    * `opts` - Options
      * `:method` - Detection method (`:iqr` or `:zscore`, default: `:iqr`)
      * `:threshold` - Z-score threshold (only for `:zscore` method)

  ## Examples

      iex> values = [1, 2, 3, 4, 5, 100]
      iex> summary = ExDataCheck.Outliers.outlier_summary(values, method: :iqr)
      iex> summary.method
      :iqr

  """
  @spec outlier_summary(list(number()), keyword()) :: map()
  def outlier_summary(values, opts \\ []) do
    method = Keyword.get(opts, :method, :iqr)

    result =
      case method do
        :iqr -> detect_iqr(values)
        :zscore -> detect_zscore(values, opts)
      end

    Map.put(result, :method, method)
  end
end
