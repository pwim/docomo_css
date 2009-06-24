require 'test/unit'
require 'rubygems'
$LOAD_PATH << File.join(File.dirname(__FILE__), '..',  'lib')
require 'docomo_css'

class DocomoCssTest < Test::Unit::TestCase
  %w{ no_stylesheet empty_stylesheet element pseudo_selectors 
      unicode_entity overlay
  }.each do |s|
    define_method("test_#{s}") do
      e = expected(s)
      i = inline(s)
      e_lines = e.split("\n")
      i_lines = i.split("\n")
      e_lines.each_with_index do |s,j|
        assert_equal(s, i_lines[j])
      end
      assert_equal e, i, "#{s} did not match"
    end
  end

  def inline(file_name)
    DocomoCss.inline_css(html(file_name), data_path)
  end

  def html(file_name)
    read_html("html", file_name)
  end

  def expected(file_name)
    read_html("expected_html", file_name)
  end

  def read_html(dir, file_name)
    File.open(File.join(data_path, dir, "#{file_name}.html")) do |f|
      f.read
    end
  end

  def data_path
    File.join(File.dirname(__FILE__), "data") 
  end
end
