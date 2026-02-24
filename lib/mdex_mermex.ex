defmodule MDExMermex do
  @moduledoc """
  MDEx plugin that renders Mermaid diagrams server-side using Mermex (Rust NIF).

  Each rendered diagram is wrapped in an interactive container with zoom, pan,
  and fullscreen controls. CSS and JS assets are injected once per document by
  default, or can be imported manually from `assets/mdex_mermex.css` and
  `assets/mdex_mermex.js` in the package.

  ## Usage

      MDEx.to_html!(markdown, plugins: [MDExMermex])

  ## Options

    * `:output` - Output format for rendered diagrams. Defaults to `:inline_svg`.
      * `:inline_svg` - Raw SVG markup directly in HTML
      * `:img_base64` - `<img>` tag with base64-encoded SVG data URI

    * `:class` - Additional CSS class(es) to add to the wrapper `<div>`.
      The wrapper always has `mdex-mermex`; your classes are appended.

          MDEx.to_html!(md, plugins: [{MDExMermex, class: "my-diagram"}])
          # produces: <div class="mdex-mermex my-diagram" tabindex="0">

    * `:inject_css` - Whether to inject the `<style>` block into the document.
      Defaults to `true`. Set to `false` when including CSS separately.

    * `:inject_js` - Whether to inject the `<script>` block into the document.
      Defaults to `true`. Set to `false` when including JS separately
      (e.g. in a root layout for LiveView).

    * `:css_layer` - When set, wraps the injected CSS in a `@layer` rule.
      Useful for controlling specificity in projects that use CSS cascade layers.

          MDEx.to_html!(md, plugins: [{MDExMermex, css_layer: "components"}])

  ## Including Assets Manually

  When injection is disabled, import the assets directly from the package:

    * CSS — `assets/mdex_mermex.css` (e.g. via `@import` in your CSS bundle)
    * JS — `assets/mdex_mermex.js` (e.g. via `import` in your JS bundle)

  The JS uses a `MutationObserver` so new diagrams added via DOM patches
  (e.g. LiveView navigation) are automatically initialized.
  """

  alias MDEx.Document

  @css_path Path.expand("../assets/mdex_mermex.css", __DIR__)
  @external_resource @css_path
  @raw_css File.read!(@css_path)

  @js_path Path.expand("../assets/mdex_mermex.js", __DIR__)
  @external_resource @js_path
  @raw_js File.read!(@js_path)

  @doc """
  Attaches the MDExMermex plugin to an MDEx document.

  See the module documentation for available options.
  """
  @spec attach(Document.t(), keyword()) :: Document.t()
  def attach(document, options \\ []) do
    document
    |> Document.register_options([:output, :class, :inject_css, :inject_js, :css_layer])
    |> Document.put_options(options)
    |> Document.append_steps(
      enable_unsafe: &enable_unsafe/1,
      inject_assets: &maybe_inject_assets/1,
      render_mermaid: &render_mermaid/1
    )
  end

  defp style_tag do
    "<style>\n#{@raw_css}</style>\n"
  end

  defp style_tag(layer) do
    "<style>\n@layer #{layer} {\n#{@raw_css}}</style>\n"
  end

  defp script_tag do
    "<script>\n#{@raw_js}</script>\n"
  end

  defp enable_unsafe(document) do
    Document.put_render_options(document, unsafe: true)
  end

  defp maybe_inject_assets(document) do
    inject_css? = Document.get_option(document, :inject_css) != false
    inject_js? = Document.get_option(document, :inject_js) != false
    css_layer = Document.get_option(document, :css_layer)
    already? = Document.get_private(document, :mdex_mermex_assets_injected) == true

    document =
      if inject_css? and not already? do
        css_html = if css_layer, do: style_tag(css_layer), else: style_tag()

        Document.put_node_in_document_root(
          document,
          %MDEx.HtmlBlock{literal: css_html},
          :top
        )
      else
        document
      end

    document =
      if inject_js? and not already? do
        Document.put_node_in_document_root(
          document,
          %MDEx.HtmlBlock{literal: script_tag()},
          :bottom
        )
      else
        document
      end

    if (inject_css? or inject_js?) and not already? do
      Document.put_private(document, :mdex_mermex_assets_injected, true)
    else
      document
    end
  end

  defp render_mermaid(document) do
    output = Document.get_option(document, :output) || :inline_svg
    extra_class = Document.get_option(document, :class)

    wrapper_class =
      case extra_class do
        nil -> "mdex-mermex"
        cls -> "mdex-mermex #{cls}"
      end

    MDEx.traverse_and_update(document, fn
      %MDEx.CodeBlock{info: "mermaid" <> _} = node ->
        svg = Mermex.render!(String.trim(node.literal))

        inner =
          case output do
            :inline_svg ->
              svg

            :img_base64 ->
              encoded = Base.encode64(svg)
              ~s(<img src="data:image/svg+xml;base64,#{encoded}">)
          end

        literal = wrap(inner, wrapper_class)
        %MDEx.HtmlBlock{literal: literal, nodes: node.nodes}

      node ->
        node
    end)
  end

  defp wrap(inner, wrapper_class) do
    """
    <div class="#{wrapper_class}" tabindex="0">\
    <div class="mdex-mermex-toolbar">\
    <button class="mdex-mermex-btn mdex-mermex-zoom-in" title="Zoom in">+</button>\
    <button class="mdex-mermex-btn mdex-mermex-zoom-out" title="Zoom out">&minus;</button>\
    <button class="mdex-mermex-btn mdex-mermex-reset" title="Reset">&#x21ba;</button>\
    <button class="mdex-mermex-btn mdex-mermex-fullscreen" title="Fullscreen">&#x26F6;</button>\
    </div>\
    #{inner}\
    </div>\
    """
  end
end
