defmodule E.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps folder
  defp deps do
    []
  end

  defp releases() do
    [
      lv: [
        include_executables_for: [:unix],
        steps: [:assemble, &copy_rel_files/1]
      ],
      lv_web: [
        include_executables_for: [:unix],
        steps: [:assemble, &copy_rel_files/1]
      ]
    ]
  end

  defp copy_rel_files(release) do
    File.cp("rel/envvars.exs", Path.join(release.path, "envvars.exs"))
    release
  end
end
