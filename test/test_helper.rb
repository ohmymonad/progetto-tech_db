# Helper comune ai test: prepara un database di test isolato e lo ripulisce
# prima di ogni test, cosi' le asserzioni sulle righe sono deterministiche.
ENV['GYMMANAGER_DB_NAME'] ||= 'gymmanager_test'

require 'minitest/autorun'
require 'open3'
require_relative '../lib/db'
require_relative '../lib/application'

module TestDatabase
  SCHEMA = File.expand_path('../db/schema.sql', __dir__)

  def self.setup!
    role = Db::ROLE
    socket = Db::SOCKET_DIR
    name = Db::DB_NAME

    exists, = Open3.capture2('psql', '-U', role, '-h', socket, '-d', 'postgres', '-tAc',
                             "SELECT 1 FROM pg_database WHERE datname='#{name}'")
    system('createdb', '-U', role, '-h', socket, name, exception: true) if exists.strip != '1'

    system('psql', '-X', '-q', '-v', 'ON_ERROR_STOP=1', '-U', role, '-h', socket,
           '-d', name, '-f', SCHEMA, exception: true)
  end

  def self.reset!
    Db.exec('TRUNCATE members, classes, enrollments, attendances RESTART IDENTITY CASCADE')
  end
end

TestDatabase.setup!

class GymTest < Minitest::Test
  def setup
    TestDatabase.reset!
  end

  # --- fixture ---

  def create_member(first: 'Mario', last: 'Rossi')
    Member.create('first_name' => first, 'last_name' => last, 'birth_date' => '1990-01-01',
                  'address' => 'Via Roma 1', 'phone' => '333', 'email' => "#{first}@example.com")
    Member.all.last['id']
  end

  def create_class(name: 'Yoga')
    ActivityClass.create('name' => name, 'description' => 'Descrizione',
                         'schedule' => 'Lun 18:00', 'instructor' => 'Anna')
    ActivityClass.all.find { |c| c['name'] == name }['id']
  end

  # --- helper HTTP ---

  def get(path, query = {})
    dispatch('GET', path, query: query)
  end

  def post(path, form = {})
    body = URI.encode_www_form(form)
    dispatch('POST', path, body: body,
             headers: { 'content-type' => 'application/x-www-form-urlencoded' })
  end

  def dispatch(method, path, query: {}, body: '', headers: {})
    request = Request.new(method: method, path: path, query: query, headers: headers, body: body)
    GymManager.router.dispatch(request)
  end

  def count(table)
    Db.query("SELECT COUNT(*) AS n FROM #{table}").first['n'].to_i
  end
end
