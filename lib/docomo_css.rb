require 'hpricot'
require 'tiny_css'

module DocomoCss

  def self.handlers
    if @handlers.nil?
      @handlers = Hash.new {|h,k| h[k] = DefaultHandler.new(k)}
      ["a:link", "a:focus", "a:visited"].each do |k|
        @handlers[k] = PseudoSelectorHandler.new(k)
      end
    end
    @handlers
  end

  def self.inline_css(content, css_dir)
    content.gsub! /&#(\d+);/, 'HTMLCSSINLINERESCAPE\1::::::::'

    doc = Hpricot(content)

    linknodes = doc/'//link[@rel="stylesheet"]'
    linknodes.each do |linknode|
      href = linknode['href'] or next

      cssfile = File.join(css_dir, href)
      cssfile.gsub! /\?.+/, ''
      css = TinyCss.new.read(cssfile)

      style_style = TinyCss.new
      css.style.each do |selector, style|
        handlers[selector].replace(doc, style_style, style)
      end
      unless style_style.style.keys.empty?
        style = %(<style type="text/css">#{ style_style.write_string }</style>)
        (doc/('head')).append style
      end

    end

    content = doc.to_html

    content.gsub! /HTMLCSSINLINERESCAPE(\d+)::::::::/, '&#\1;'
    content
  end

  class Handler
    def initialize(selector)
      @selector = selector
    end
  end

  class PseudoSelectorHandler < Handler
    def replace(doc, style_style, style)
      style_style.style[@selector] = style
    end
  end

  class DefaultHandler < Handler
    def replace(doc, style_style, style)
      (doc/(@selector)).each do |element|
        style_attr = element[:style]
        style_attr = (!style_attr) ? stringify_style(style) :
          [style_attr, stringify_style(style)].join(';')
        element[:style] = style_attr
      end
    end

    private

    def stringify_style(style)
      style.map { |k, v| "#{ k }:#{ v }" }.join ';'
    end
  end
end
