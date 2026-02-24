defmodule MDExMermexTest do
  use ExUnit.Case

  @mermaid_diagram "flowchart LR\n  A-->B-->C"

  @markdown """
  # Hello

  ```mermaid
  #{@mermaid_diagram}
  ```
  """

  test "renders mermaid code block as inline SVG within wrapper" do
    html = MDEx.to_html!(@markdown, plugins: [MDExMermex])

    assert html =~ ~s(<div class="mdex-mermex" tabindex="0">)
    assert html =~ "<svg"
    assert html =~ "</svg>"
    assert html =~ "</div>"
  end

  test "inline SVG contains valid SVG namespace" do
    html = MDEx.to_html!(@markdown, plugins: [MDExMermex])

    assert html =~ "xmlns"
  end

  test "wrapper includes toolbar buttons" do
    html = MDEx.to_html!(@markdown, plugins: [MDExMermex])

    assert html =~ "mdex-mermex-toolbar"
    assert html =~ "mdex-mermex-zoom-in"
    assert html =~ "mdex-mermex-zoom-out"
    assert html =~ "mdex-mermex-reset"
    assert html =~ "mdex-mermex-fullscreen"
  end

  test "renders mermaid code block as base64 img tag within wrapper" do
    html = MDEx.to_html!(@markdown, plugins: [{MDExMermex, output: :img_base64}])

    assert html =~ ~s(<div class="mdex-mermex" tabindex="0">)
    assert html =~ ~s(<img src="data:image/svg+xml;base64,)
  end

  test "non-mermaid code blocks are left untouched" do
    markdown = """
    ```elixir
    IO.puts("hello")
    ```
    """

    html = MDEx.to_html!(markdown, plugins: [MDExMermex])

    assert html =~ "language-elixir"
    refute html =~ "<svg"
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

    svg_count = length(String.split(html, "<svg")) - 1
    assert svg_count == 2

    wrapper_count = length(String.split(html, ~s(class="mdex-mermex"))) - 1
    assert wrapper_count == 2
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
    assert html =~ "<svg"
  end

  test "inject_css: false skips only CSS injection" do
    html = MDEx.to_html!(@markdown, plugins: [{MDExMermex, inject_css: false}])

    refute html =~ "<style>"
    assert html =~ "<script>"
    assert html =~ "<svg"
  end

  test "both inject options false skips all asset injection" do
    html =
      MDEx.to_html!(@markdown,
        plugins: [{MDExMermex, inject_css: false, inject_js: false}]
      )

    refute html =~ "<style>"
    refute html =~ "<script>"
    assert html =~ "<svg"
    assert html =~ ~s(class="mdex-mermex")
  end

  test ":css_layer option wraps injected CSS in @layer rule" do
    html = MDEx.to_html!(@markdown, plugins: [{MDExMermex, css_layer: "components"}])

    assert html =~ "@layer components {"
    assert html =~ ".mdex-mermex"
  end
end
