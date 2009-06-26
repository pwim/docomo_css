require 'hpricot'
require 'tiny_css'

module DocomoCss

  def self.handlers
    unless defined?(@handlers)
      element_handler = UnsupportedElementHandler.new(
        (1..6).map {|i| "h#{i}"} + %w{p},
        %w{font-size color})
      @handlers = Hash.new {|h,k| h[k] = DefaultHandler.new(k, element_handler)}
      ["a:link", "a:focus", "a:visited"].each do |k|
        @handlers[k] = PseudoSelectorHandler.new(k)
      end
    end
    @handlers
  end

  def self.inline_css(content, css_dir)
    content.gsub!(/&#(\d+);/, 'HTMLCSSINLINERESCAPE\1::::::::')

    doc = Hpricot(content)

    linknodes = doc/'//link[@rel="stylesheet"]'
    linknodes.each do |linknode|
      href = linknode['href'] 
      next unless href && allowed_media_type?(linknode['media'])

      cssfile = File.join(css_dir, href)
      cssfile.gsub!(/\?.+/, '')
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
    doc.search('//link[@docomo_css="remove_after_inline"]').remove

    content = doc.to_html

    content.gsub!(/HTMLCSSINLINERESCAPE(\d+)::::::::/, '&#\1;')
    content
  end

  def self.allowed_media_type?(s)
    s.nil? || s =~ /handheld|all|tty/
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
    def initialize(selector, element_handler)
      super(selector)
      @element_handler = element_handler
    end

    def replace(doc, style_style, style)
      (doc/(@selector)).each do |element|
        @element_handler.add_style(element, style)
      end
    end
  end

  class UnsupportedElementHandler
    def initialize(unsupported_elements, unsupported_styles)
      @unsupported_elements = unsupported_elements
      @unsupported_styles = unsupported_styles
    end

    def add_style(element, style)
      if @unsupported_elements.include?(element.name)
        unsupported = TinyCss::OrderedHash.new
        supported = TinyCss::OrderedHash.new
        style.each do |k,v|
          s = @unsupported_styles.include?(k) ? unsupported : supported
          s[k] = v
        end

        #TODO: unit test
        _add_style(element, supported) unless supported.keys.empty? 
        
        unless unsupported.keys.empty?
          # BUG: assumes source contains no span wrapped in selector
          wrapped_children = element.search("span")
          if wrapped_children.empty?
            element.search("/").wrap("<span></span>")
            wrapped_children = element.search("span")
          end
          wrapped_children.each do |c|
            add_style(c, unsupported)
          end
        end
      else
        _add_style(element, style)
      end
    end

    def _add_style(element, style)
      style_attr = element[:style]
      style_attr = (!style_attr) ? stringify_style(style) :
        [style_attr, stringify_style(style)].join(';')
      element[:style] = style_attr
    end

    private

    def stringify_style(style)
      style.map { |k, v| "#{ k }:#{ v }" }.join ';'
    end
  end
end
