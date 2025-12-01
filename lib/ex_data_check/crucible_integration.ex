defmodule ExDataCheck.CrucibleIntegration do
  @moduledoc """
  Optional integration with CrucibleIR for pipeline usage.

  This module provides integration between ExDataCheck and the Crucible framework's
  Intermediate Representation (IR) for defining data processing pipelines. It allows
  ExDataCheck to be used as a pipeline stage within Crucible workflows.

  **Note**: This integration is only available when `crucible_ir` is included as a
  dependency in your `mix.exs`:

      def deps do
        [
          {:ex_data_check, "~> 0.3.0"},
          {:crucible_ir, "~> 0.1.1"}
        ]
      end

  ## Usage

  When `crucible_ir` is available, you can use ExDataCheck as a pipeline stage:

      # Define validation stage
      stage = ExDataCheck.CrucibleIntegration.stage()

      # Use in a pipeline
      pipeline = [
        load_data_stage,
        ExDataCheck.CrucibleIntegration.stage(),
        process_data_stage
      ]

  ## Examples

      # With CrucibleIR available
      if Code.ensure_loaded?(CrucibleIR) do
        stage = ExDataCheck.CrucibleIntegration.stage()
        # Use stage in your Crucible pipeline
      end

  """

  if Code.ensure_loaded?(CrucibleIR) do
    @doc """
    Creates a pipeline stage for data validation.

    Returns the `ExDataCheck.Stage` module which implements the pipeline stage
    interface for data validation within Crucible workflows.

    ## Returns

    The `ExDataCheck.Stage` module.

    ## Examples

        stage = ExDataCheck.CrucibleIntegration.stage()
        # Use in Crucible pipeline

    """
    @spec stage() :: module()
    def stage do
      ExDataCheck.Stage
    end

    @doc """
    Checks if CrucibleIR integration is available.

    ## Returns

    `true` if CrucibleIR is loaded, `false` otherwise.

    ## Examples

        iex> ExDataCheck.CrucibleIntegration.available?()
        true

    """
    @spec available?() :: boolean()
    def available? do
      true
    end
  else
    @doc """
    Checks if CrucibleIR integration is available.

    ## Returns

    `false` when CrucibleIR is not loaded.

    ## Examples

        iex> ExDataCheck.CrucibleIntegration.available?()
        false

    """
    @spec available?() :: boolean()
    def available? do
      false
    end

    @doc """
    Creates a pipeline stage for data validation.

    This function is not available when CrucibleIR is not loaded as a dependency.

    ## Returns

    Raises an error indicating that CrucibleIR is required.
    """
    @spec stage() :: no_return()
    def stage do
      raise RuntimeError, """
      CrucibleIR integration is not available.

      To use ExDataCheck with Crucible pipelines, add crucible_ir to your dependencies:

          def deps do
            [
              {:ex_data_check, "~> 0.3.0"},
              {:crucible_ir, "~> 0.1.1"}
            ]
          end

      Then run: mix deps.get
      """
    end
  end
end
