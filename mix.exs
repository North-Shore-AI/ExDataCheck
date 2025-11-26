defmodule ExDataCheck.MixProject do
  use Mix.Project

  @version "0.2.1"
  @source_url "https://github.com/North-Shore-AI/ExDataCheck"

  def project do
    [
      app: :ex_data_check,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url,
      name: "ExDataCheck"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:stream_data, "~> 1.1", only: :test}
    ]
  end

  defp description do
    "Production-ready data validation and quality library for Elixir ML pipelines. " <>
      "Provides 22 built-in expectations, drift detection, advanced profiling with outliers and correlations, " <>
      "statistical analysis, and comprehensive quality metrics for machine learning workflows."
  end

  defp package do
    [
      name: "ex_data_check",
      description: description(),
      files: ~w(lib mix.exs README.md CHANGELOG.md LICENSE IMPLEMENTATION_SUMMARY.md docs),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Online documentation" => "https://hexdocs.pm/ex_data_check"
      },
      maintainers: ["nshkrdotcom"]
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "ExDataCheck",
      source_ref: "v#{@version}",
      source_url: @source_url,
      homepage_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "IMPLEMENTATION_SUMMARY.md",
        "docs/architecture.md",
        "docs/expectations.md",
        "docs/validators.md",
        "docs/roadmap.md",
        "docs/20251020/future_vision_phase3_4.md"
      ],
      groups_for_extras: [
        Guides: [
          "docs/architecture.md",
          "docs/expectations.md",
          "docs/validators.md"
        ],
        Planning: [
          "docs/roadmap.md",
          "docs/20251020/future_vision_phase3_4.md"
        ],
        Project: [
          "README.md",
          "CHANGELOG.md",
          "IMPLEMENTATION_SUMMARY.md"
        ]
      ],
      assets: %{"assets" => "assets"},
      logo: "assets/ExDataCheck.svg",
      before_closing_head_tag: &mermaid_config/1
    ]
  end

  defp mermaid_config(:html) do
    """
    <script defer src="https://cdn.jsdelivr.net/npm/mermaid@10.2.3/dist/mermaid.min.js"></script>
    <script>
      let initialized = false;

      window.addEventListener("exdoc:loaded", () => {
        if (!initialized) {
          mermaid.initialize({
            startOnLoad: false,
            theme: document.body.className.includes("dark") ? "dark" : "default"
          });
          initialized = true;
        }

        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition).then(({svg, bindFunctions}) => {
            graphEl.innerHTML = svg;
            bindFunctions?.(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }
      });
    </script>
    """
  end

  defp mermaid_config(_), do: ""
end
