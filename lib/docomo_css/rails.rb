require "docomo_css"

module DocomoCss::Rails

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def docomo_filter
      after_filter DocomoCssFilter.new
    end
  end

  class DocomoCssFilter
    def after(controller)
      content = controller.response.body
      css_dir = File.join(RAILS_ROOT, 'public')
      controller.response.body = DocomoCss.inline_css(content,css_dir)
    end
  end
end
