defmodule ExDataCheck.DriftResult do
  @moduledoc """
  Result of drift detection analysis.

  Contains information about distribution changes between baseline and current data.

  ## Examples

      iex> result = %ExDataCheck.DriftResult{
      ...>   drifted: true,
      ...>   columns_drifted: [:age, :income],
      ...>   drift_scores: %{age: 0.23, income: 0.45},
      ...>   method: :ks
      ...> }
      iex> result.drifted
      true

  """

  @type t :: %__MODULE__{
          drifted: boolean(),
          columns_drifted: list(atom() | String.t()),
          drift_scores: %{optional(atom() | String.t()) => float()},
          method: atom(),
          threshold: float(),
          details: map()
        }

  defstruct [
    :drifted,
    :columns_drifted,
    :drift_scores,
    :method,
    :threshold,
    details: %{}
  ]

  @doc """
  Creates a new DriftResult.

  ## Parameters

    * `drift_scores` - Map of column names to drift scores
    * `threshold` - Drift threshold (scores above this indicate drift)
    * `method` - Detection method used (:ks, :chi_square, :psi)
    * `details` - Additional details (optional)

  """
  @spec new(map(), float(), atom(), map()) :: t()
  def new(drift_scores, threshold, method, details \\ %{}) do
    columns_drifted =
      drift_scores
      |> Enum.filter(fn {_col, score} -> score > threshold end)
      |> Enum.map(fn {col, _score} -> col end)

    %__MODULE__{
      drifted: length(columns_drifted) > 0,
      columns_drifted: columns_drifted,
      drift_scores: drift_scores,
      method: method,
      threshold: threshold,
      details: details
    }
  end
end
