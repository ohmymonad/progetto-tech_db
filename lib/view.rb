require 'erb'
require 'cgi'

VIEWS_DIR = File.join(__dir__, '..', 'views')

# Contesto di rendering: espone helper alle view ERB.
class ViewContext
  attr_accessor :flash_message, :current_path, :content

  def initialize(locals)
    locals.each do |k, v|
      instance_variable_set("@#{k}", v)
      define_singleton_method(k) { v }
    end
  end

  def h(text)
    CGI.escapeHTML(text.to_s)
  end

  def nav_class(prefix)
    current_path.to_s.start_with?(prefix) ? 'bg-ink-100 text-ink-900' : 'text-ink-600 hover:bg-ink-100'
  end

  def render_partial(name, locals = {})
    partial = self.class.new(locals.merge(flash_message: flash_message, current_path: current_path))
    ERB.new(File.read(File.join(VIEWS_DIR, "#{name}.erb"))).result(partial.get_binding)
  end

  def get_binding
    binding
  end
end

def render(view, locals = {}, request: nil, flash: nil)
  ctx = ViewContext.new(locals)
  ctx.flash_message = flash
  ctx.current_path = request&.path
  content = ERB.new(File.read(File.join(VIEWS_DIR, "#{view}.erb"))).result(ctx.get_binding)

  layout_ctx = ViewContext.new(locals.merge(title: 'GymManager'))
  layout_ctx.flash_message = flash
  layout_ctx.current_path = request&.path
  layout_ctx.content = content

  ERB.new(File.read(File.join(VIEWS_DIR, 'layout.erb'))).result(layout_ctx.get_binding)
end
