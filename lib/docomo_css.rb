require 'hpricot'
require 'tiny_css'

module DocomoCss

  def self.inline_css(content, css_dir)
    content.gsub! /&#(\d+);/, 'HTMLCSSINLINERESCAPE\1::::::::'

    doc = Hpricot(content)

    linknodes = doc/'//link[@rel="stylesheet"]'
    linknodes.each do |linknode|
      href = linknode['href'] or next

      cssfile = File.join(css_dir, href)
      cssfile.gsub! /\?.+/, ''
      css = TinyCss.new.read(cssfile)

      pseudo_selectors = css.style.keys.reject { |v|
        v !~ /a:(link|focus|visited)/
      }
      unless pseudo_selectors.empty?
        style_style = TinyCss.new
        pseudo_selectors.each do |v|
          style_style.style[v] = css.style[v]
          css.style.delete v
        end

        style = %(<style type="text/css">#{ style_style.write_string }</style>)
        (doc/('head')).append style
      end

      css.style.each do |selector, style|
        (doc/(selector)).each do |element|
          style_attr = element[:style]
          style_attr = (!style_attr) ? stringify_style(style) :
            [style_attr, stringify_style(style)].join(';')
          element[:style] = style_attr
        end
      end
    end

    content = doc.to_html

    content.gsub! /HTMLCSSINLINERESCAPE(\d+)::::::::/, '&#\1;'
    content
  end

  private
  def self.stringify_style(style)
    style.map { |k, v| "#{ k }:#{ v }" }.join ';'
  end
end
