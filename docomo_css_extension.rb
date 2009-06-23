require 'docomo_css'
class DocomoCssExtension < Radiant::Extension
  version "0.1"
  description "Inlining of CSS"
  url "http://github.com/pwim/docomo_css"

  def activate
    SiteController.send :include, DocomoCss
    SiteController.send :docomo_filter
  end
end
