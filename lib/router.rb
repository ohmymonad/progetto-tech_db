require 'cgi'
require 'uri'

# Router HTTP minimale su TCPServer puro (stdlib), niente framework.
class Router
  Route = Struct.new(:method, :pattern, :keys, :handler)

  def initialize
    @routes = []
  end

  %w[GET POST].each do |verb|
    define_method(verb.downcase) do |path, &block|
      add(verb, path, &block)
    end
  end

  def add(method, path, &block)
    keys = []
    pattern = path.split('/').map do |seg|
      if seg.start_with?(':')
        keys << seg[1..]
        '([^/]+)'
      else
        Regexp.escape(seg)
      end
    end.join('/')
    @routes << Route.new(method, /\A#{pattern}\z/, keys, block)
  end

  def dispatch(request)
    @routes.each do |route|
      next unless route.method == request.method
      match = route.pattern.match(request.path)
      next unless match

      params = route.keys.zip(match.captures).to_h
      request.params.merge!(params)
      return route.handler.call(request)
    end
    Response.new(404, "Pagina non trovata: #{request.method} #{request.path}")
  end
end

# Rappresenta una richiesta HTTP gia' parsata.
class Request
  attr_reader :method, :path, :query, :headers, :body, :params

  def initialize(method:, path:, query:, headers:, body:)
    @method = method
    @path = path
    @query = query
    @headers = headers
    @body = body
    @params = query.merge(parse_form_body(body, headers))
  end

  private

  def parse_form_body(body, headers)
    return {} if body.nil? || body.empty?
    return {} unless (headers['content-type'] || '').include?('application/x-www-form-urlencoded')

    parse_query_string(body)
  end

  def self.parse_query_string(str)
    Hash[URI.decode_www_form(str)]
  end

  def parse_query_string(str)
    self.class.parse_query_string(str)
  end
end

# Rappresenta una risposta HTTP.
class Response
  attr_accessor :status, :body, :headers

  def initialize(status = 200, body = '', headers = {})
    @status = status
    @body = body
    @headers = { 'Content-Type' => 'text/html; charset=utf-8' }.merge(headers)
  end

  def self.redirect(location)
    new(302, '', 'Location' => location)
  end
end
