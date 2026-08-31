require 'minitest/autorun'
require_relative '../lib/router'
require_relative '../lib/models/member'
require_relative '../lib/models/activity_class'
require_relative '../lib/models/attendance'
require 'cgi'

# Setup test DB: crea un'istanza pulita prima di ogni test.
class Minitest::Test
  def setup
    # Usa la DB di test (env var o default 'gymmanager_test')
    ENV['GYMMANAGER_DB_NAME'] = 'gymmanager_test'

    # Pulisci le tabelle
    sql = <<~SQL
      TRUNCATE TABLE attendances RESTART IDENTITY CASCADE;
      TRUNCATE TABLE enrollments RESTART IDENTITY CASCADE;
      TRUNCATE TABLE classes RESTART IDENTITY CASCADE;
      TRUNCATE TABLE members RESTART IDENTITY CASCADE;
    SQL
    Db.run(sql, {}, csv: false)
  end
end

# Helper per fare richieste HTTP contro il router senza avviare un TCP server.
def get(path, params = {})
  request = build_request('GET', path, params)
  yield request if block_given?
  request
end

def post(path, params = {})
  request = build_request('POST', path, params)
  yield request if block_given?
  request
end

def build_request(method, path, params = {})
  query = method == 'GET' ? params : {}
  body_str = ''

  if method == 'POST' && params.any?
    body_str = URI.encode_www_form(params)
  end

  Request.new(
    method: method,
    path: path,
    query: query,
    headers: method == 'POST' ? { 'content-type' => 'application/x-www-form-urlencoded', 'content-length' => body_str.bytesize.to_s } : {},
    body: body_str
  )
end

# Helper per dispatchare una richiesta tramite il router.
def dispatch(request, router)
  router.dispatch(request)
end
