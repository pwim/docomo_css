require 'test/unit'
require 'rubygems'
$LOAD_PATH << File.join(File.dirname(__FILE__), '..',  'lib')
require 'docomo_css'

class DocomoCssTest < Test::Unit::TestCase
  def test_inline_css_empty
    s = DocomoCss.inline_css(no_stylesheet_xhtml, "")
    assert_equal no_stylesheet_xhtml, s
  end

  def no_stylesheet_xhtml
<<-EOD
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//i-mode group (ja)//DTD XHTML i-XHTML(Locale/Ver.=ja/1.1) 1.0//EN" "i-xhtml_4ja_10.dtd">
<html xml:lang="ja" lang="ja" xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Foo</title>
</head>
<body>
  Foo
</body>
</html>
EOD
  end
end
