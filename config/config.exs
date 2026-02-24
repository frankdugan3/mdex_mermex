import Config

if Mix.env() == :dev do
  config :git_ops,
    mix_project: MDExMermex.MixProject,
    changelog_file: "CHANGELOG.md",
    repository_url: "https://github.com/frankdugan3/mdex_mermex",
    manage_mix_version?: true,
    manage_readme_version: true,
    version_tag_prefix: "v"
end
