require 'hpricot'
require 'tiny_css'

module DocomoCss

  def self.handlers
    if @handlers.nil?
      @handlers = Hash.new {|h,k| h[k] = DefaultHandler.new(k)}
      ["a:link", "a:focus", "a:visited"].each do |k|
        @handlers[k] = PseudoSelectorHandler.new(k)
      end
      (1..6).map {|i| "h#{i}"}.each do |k|
        @handlers[k] = UnsupportedStyleHandler.new(k, %w{font-size color})
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
        add_style(element, style)
      end
    end

    private

    def add_style(element, style)
      style_attr = element[:style]
      style_attr = (!style_attr) ? stringify_style(style) :
        [style_attr, stringify_style(style)].join(';')
      element[:style] = style_attr
    end

    def stringify_style(style)
      style.map { |k, v| "#{ k }:#{ v }" }.join ';'
    end
  end

  class UnsupportedStyleHandler < DefaultHandler
    def initialize(selector, unsupported_styles)
      super(selector)
      @unsupported_styles = unsupported_styles
    end

    def replace(doc, style_style, style)
      unsupported = TinyCss::OrderedHash.new
      supported = TinyCss::OrderedHash.new
      style.each do |k,v|
        s = @unsupported_styles.include?(k) ? unsupported : supported
        s[k] = v
      end
      super(doc, style, supported) unless supported.keys.empty?
      unless unsupported.keys.empty?
        # BUG: assumes source contains no span wrapped in selector
        wrapped_children = doc.search("#{@selector}/span")
        if wrapped_children.empty?
          (doc/("#{@selector}/")).wrap("<span></span>")
          wrapped_children = doc.search("#{@selector}/span")
        end
        wrapped_children.each do |c|
          add_style(c, unsupported)
        end
      end
    end
  end
end
