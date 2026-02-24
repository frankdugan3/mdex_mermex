[
  tools: [
    {:compiler, "mix compile --warnings-as-errors"},
    {:formatter, "mix format --check-formatted"},
    {:credo, "mix credo --strict"},
    {:dialyzer, "mix dialyzer"},
    {:ex_doc, "mix docs"},
    {:mix_audit, "mix deps.audit"},
    {:unused_deps, "mix deps.unlock --check-unused"},
    {:ex_unit, "mix test"}
  ]
]
