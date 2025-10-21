defmodule ExDataCheck.ValidationError do
  @moduledoc """
  Exception raised when validation fails and using `validate!/2`.

  Contains the full ValidationResult for inspection.
  """

  defexception [:message, :result]

  @impl true
  def exception(opts) do
    result = Keyword.fetch!(opts, :result)

    failed_count = result.expectations_failed

    message = """
    Validation failed with #{failed_count} failed expectation(s).

    Failed expectations:
    #{format_failed_expectations(result)}
    """

    %__MODULE__{
      message: message,
      result: result
    }
  end

  defp format_failed_expectations(result) do
    result
    |> ExDataCheck.ValidationResult.failed_expectations()
    |> Enum.map_join("\n", fn exp ->
      "  - #{exp.expectation}"
    end)
  end
end
