require 'socket'
require 'erb'
require 'cgi'
require_relative 'lib/router'
require_relative 'lib/models/member'
require_relative 'lib/models/activity_class'
require_relative 'lib/models/attendance'

VIEWS_DIR = File.join(__dir__, 'views')

# Contesto di rendering: espone helper e variabili alle view ERB.
class ViewContext
  attr_accessor :flash_message, :current_path

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

  # Binding il cui self e' questo contesto, cosi' le view vedono
  # gli helper e le variabili definite qui sopra.
  def view_binding
    binding
  end
end

# Renderizza una view dentro il layout condiviso.
def render(view, locals = {}, request: nil, flash: nil)
  content = render_template(view, locals, request: request, flash: flash)
  render_template('layout', locals.merge(title: 'GymManager', content: content),
                  request: request, flash: flash)
end

def render_template(name, locals, request:, flash:)
  ctx = ViewContext.new(locals)
  ctx.flash_message = flash
  ctx.current_path = request&.path
  template = File.read(File.join(VIEWS_DIR, "#{name}.erb"))
  ERB.new(template, trim_mode: '-').result(ctx.view_binding)
end

router = Router.new

# --- Home: redirige ai membri ---
router.get('/') { |_req| Response.redirect('/members') }

# --- Membri ---
router.get('/members') do |req|
  members = Member.all(name_filter: req.params['name'], status_filter: req.params['status'])
  Response.new(200, render('members/index', {
    members: members, name_filter: req.params['name'], status_filter: req.params['status']
  }, request: req))
end

router.get('/members/new') do |req|
  Response.new(200, render('members/new', { member: nil }, request: req))
end

router.post('/members') do |req|
  Member.create(req.params.slice('first_name', 'last_name', 'birth_date', 'address', 'phone', 'email'))
  Response.redirect('/members')
end

router.get('/members/:id/edit') do |req|
  member = Member.find(req.params['id'])
  Response.new(200, render('members/new', { member: member }, request: req))
end

router.post('/members/:id/edit') do |req|
  attrs = req.params.slice('first_name', 'last_name', 'birth_date', 'address', 'phone', 'email')
  attrs['active'] = req.params.key?('active') ? 'true' : 'false'
  Member.update(req.params['id'], attrs)
  Response.redirect('/members')
end

router.post('/members/:id/delete') do |req|
  Member.delete(req.params['id'])
  Response.redirect('/members')
end

# --- Presenze ---
router.get('/attendance') do |req|
  members = Member.all
  Response.new(200, render('attendance/index', { members: members }, request: req))
end

router.post('/attendance') do |req|
  Attendance.register(req.params['member_id'], req.params['checked_in_at'])
  Response.redirect("/attendance/#{req.params['member_id']}")
end

router.get('/attendance/:id') do |req|
  member = Member.find(req.params['id'])
  history = Attendance.history(req.params['id'])
  stats = Attendance.stats(req.params['id'])
  Response.new(200, render('attendance/show', {
    member: member, history: history, stats: stats
  }, request: req))
end

# --- Classi ---
router.get('/classes') do |req|
  classes = ActivityClass.all
  enrolled_members = classes.to_h { |c| [c['id'], ActivityClass.members_of(c['id'])] }
  Response.new(200, render('classes/index', {
    classes: classes, enrolled_members: enrolled_members, all_members: Member.all
  }, request: req))
end

router.get('/classes/new') do |req|
  Response.new(200, render('classes/new', { activity_class: nil }, request: req))
end

router.post('/classes') do |req|
  ActivityClass.create(req.params.slice('name', 'description', 'schedule', 'instructor'))
  Response.redirect('/classes')
end

router.get('/classes/:id/edit') do |req|
  activity_class = ActivityClass.find(req.params['id'])
  Response.new(200, render('classes/new', { activity_class: activity_class }, request: req))
end

router.post('/classes/:id/edit') do |req|
  ActivityClass.update(req.params['id'], req.params.slice('name', 'description', 'schedule', 'instructor'))
  Response.redirect('/classes')
end

router.post('/classes/:id/delete') do |req|
  ActivityClass.delete(req.params['id'])
  Response.redirect('/classes')
end

router.post('/classes/:id/enroll') do |req|
  ActivityClass.enroll(req.params['member_id'], req.params['id'])
  Response.redirect('/classes')
end

# --- Server HTTP minimale ---
class Server
  def initialize(router, port: 4567)
    @router = router
    @port = port
  end

  def start
    server = TCPServer.new('0.0.0.0', @port)
    puts "GymManager in ascolto su http://localhost:#{@port}"
    loop do
      client = server.accept
      handle(client)
    end
  end

  private

  def handle(client)
    request_line = client.gets
    return client.close if request_line.nil?

    method, full_path, = request_line.split(' ')
    path, query_string = full_path.split('?', 2)

    headers = {}
    while (line = client.gets) && line != "\r\n"
      key, value = line.split(':', 2)
      headers[key.strip.downcase] = value.strip if key && value
    end

    body = ''
    if headers['content-length']
      body = client.read(headers['content-length'].to_i)
    end

    query = query_string ? Hash[URI.decode_www_form(query_string)] : {}
    request = Request.new(method: method, path: path, query: query, headers: headers, body: body)

    response = begin
      @router.dispatch(request)
    rescue Db::QueryError => e
      Response.new(500, "Errore database: #{CGI.escapeHTML(e.message)}")
    rescue StandardError => e
      Response.new(500, "Errore interno: #{CGI.escapeHTML(e.message)}")
    end

    write_response(client, response)
  rescue Errno::EPIPE, Errno::ECONNRESET
    # client disconnesso, ignora
  ensure
    client.close
  end

  def write_response(client, response)
    status_text = { 200 => 'OK', 302 => 'Found', 404 => 'Not Found', 500 => 'Internal Server Error' }[response.status] || 'OK'
    client.print "HTTP/1.1 #{response.status} #{status_text}\r\n"
    response.headers.each { |k, v| client.print "#{k}: #{v}\r\n" }
    client.print "Content-Length: #{response.body.bytesize}\r\n"
    client.print "Connection: close\r\n"
    client.print "\r\n"
    client.print response.body
  end
end

Server.new(router).start if __FILE__ == $0
