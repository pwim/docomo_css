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

      style_style = TinyCss.new
      css.style.each do |selector, style|
        if pseudo_selector?(selector)
          style_style.style[selector] = style
        else
          (doc/(selector)).each do |element|
            style_attr = element[:style]
            style_attr = (!style_attr) ? stringify_style(style) :
              [style_attr, stringify_style(style)].join(';')
            element[:style] = style_attr
          end
        end
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

  private

  def self.pseudo_selector?(k)
    ["a:link", "a:focus", "a:visited"].include?(k)
  end

  def self.stringify_style(style)
    style.map { |k, v| "#{ k }:#{ v }" }.join ';'
  end
end
