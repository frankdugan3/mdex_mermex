defmodule MDExMermexTest do
  use ExUnit.Case

  @mermaid_diagram "flowchart LR\n  A-->B-->C"

  @markdown """
  # Hello

  ```mermaid
  #{@mermaid_diagram}
  ```
  """

  test "renders mermaid as base64 img tag within wrapper" do
    html = MDEx.to_html!(@markdown, plugins: [MDExMermex])

    assert html =~ ~s(<div class="mdex-mermex" tabindex="0">)
    assert html =~ ~s(<img src="data:image/svg+xml;base64,)
    assert html =~ "</div>"
  end

  test "base64 img decodes to well-formed XML" do
    html = MDEx.to_html!(@markdown, plugins: [MDExMermex])

    [_, encoded] = String.split(html, ~s(src="data:image/svg+xml;base64,), parts: 2)
    encoded = String.split(encoded, "\"") |> hd()
    svg = Base.decode64!(encoded)

    assert svg =~ "<svg"
    assert svg =~ "xmlns"
    assert svg =~ "</svg>"

    # mermaid-rs-renderer has a known bug where font-family attributes contain
    # unescaped double quotes (e.g. "Segoe UI"). Verify sanitize_svg escapes
    # them so the SVG is valid XML when parsed standalone via data: URI.
    refute String.contains?(svg, ~s("Segoe UI"))
    assert String.contains?(svg, "&quot;Segoe UI&quot;")
  end

  test "wrapper includes toolbar buttons" do
    html = MDEx.to_html!(@markdown, plugins: [MDExMermex])

    assert html =~ "mdex-mermex-toolbar"
    assert html =~ "mdex-mermex-zoom-in"
    assert html =~ "mdex-mermex-zoom-out"
    assert html =~ "mdex-mermex-reset"
    assert html =~ "mdex-mermex-fullscreen"
  end

  test "non-mermaid code blocks are left untouched" do
    markdown = """
    ```elixir
    IO.puts("hello")
    ```
    """

    html = MDEx.to_html!(markdown, plugins: [MDExMermex])

    refute html =~ "data:image/svg+xml;base64,"
  end

  test "renders multiple mermaid blocks" do
    markdown = """
    ```mermaid
    flowchart LR
      A-->B
    ```

    Some text

    ```mermaid
    flowchart LR
      C-->D
    ```
    """

    html = MDEx.to_html!(markdown, plugins: [MDExMermex])

    img_count = length(String.split(html, "data:image/svg+xml;base64,")) - 1
    assert img_count == 2

    wrapper_count = length(String.split(html, ~s(class="mdex-mermex"))) - 1
    assert wrapper_count == 2
  end

  test "renders many diverse diagram types" do
    markdown = """
    ## Flowcharts

    ```mermaid
    flowchart TD
        A[Raw Material] --> B{Inspect?}
        B -->|Yes| C[Accept]
        B -->|No| D[Reject]
    ```

    ```mermaid
    flowchart LR
        X[Order] --> Y[Schedule]
        Y --> Z[Ship]
    ```

    ## Sequence Diagrams

    ```mermaid
    sequenceDiagram
        participant Op as Operator
        participant WC as Workcenter
        Op->>WC: Start cycle
        WC-->>Op: Done
    ```

    ## State Diagrams

    ```mermaid
    stateDiagram-v2
        [*] --> Draft
        Draft --> Submitted
        Submitted --> Approved
        Approved --> [*]
    ```

    ## Pie Charts

    ```mermaid
    pie title Defects
        "Dimensional" : 42
        "Surface" : 27
        "Material" : 15
    ```
    """

    html = MDEx.to_html!(markdown, plugins: [MDExMermex])

    img_count = length(String.split(html, "data:image/svg+xml;base64,")) - 1
    assert img_count == 5

    wrapper_count = length(String.split(html, ~s(class="mdex-mermex"))) - 1
    assert wrapper_count == 5
  end

  test "works with pre-parsed Document structs" do
    doc = MDEx.parse_document!(@markdown)
    html = MDEx.to_html!(doc, plugins: [MDExMermex])

    assert html =~ ~s(<div class="mdex-mermex" tabindex="0">)
    assert html =~ ~s(<img src="data:image/svg+xml;base64,)
  end

  test "injects CSS style block once by default" do
    html = MDEx.to_html!(@markdown, plugins: [MDExMermex])

    assert html =~ "<style>"
    assert html =~ ".mdex-mermex"

    style_count = length(String.split(html, "<style>")) - 1
    assert style_count == 1
  end

  test "injects JS script block once by default" do
    html = MDEx.to_html!(@markdown, plugins: [MDExMermex])

    assert html =~ "<script>"
    assert html =~ "MutationObserver"

    script_count = length(String.split(html, "<script>")) - 1
    assert script_count == 1
  end

  test "multiple diagrams still get only one set of injected assets" do
    markdown = """
    ```mermaid
    flowchart LR
      A-->B
    ```

    ```mermaid
    flowchart LR
      C-->D
    ```
    """

    html = MDEx.to_html!(markdown, plugins: [MDExMermex])

    style_count = length(String.split(html, "<style>")) - 1
    script_count = length(String.split(html, "<script>")) - 1
    assert style_count == 1
    assert script_count == 1
  end

  test ":class option appends custom class to wrapper" do
    html = MDEx.to_html!(@markdown, plugins: [{MDExMermex, class: "my-diagram"}])

    assert html =~ ~s(<div class="mdex-mermex my-diagram" tabindex="0">)
  end

  test "inject_js: false skips only JS injection" do
    html = MDEx.to_html!(@markdown, plugins: [{MDExMermex, inject_js: false}])

    assert html =~ "<style>"
    refute html =~ "<script>"
    assert html =~ "data:image/svg+xml;base64,"
  end

  test "inject_css: false skips only CSS injection" do
    html = MDEx.to_html!(@markdown, plugins: [{MDExMermex, inject_css: false}])

    refute html =~ "<style>"
    assert html =~ "<script>"
    assert html =~ "data:image/svg+xml;base64,"
  end

  test "both inject options false skips all asset injection" do
    html =
      MDEx.to_html!(@markdown,
        plugins: [{MDExMermex, inject_css: false, inject_js: false}]
      )

    refute html =~ "<style>"
    refute html =~ "<script>"
    assert html =~ "data:image/svg+xml;base64,"
    assert html =~ ~s(class="mdex-mermex")
  end

  test ":css_layer option wraps injected CSS in @layer rule" do
    html = MDEx.to_html!(@markdown, plugins: [{MDExMermex, css_layer: "components"}])

    assert html =~ "@layer components {"
    assert html =~ ".mdex-mermex"
  end
end
