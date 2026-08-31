require 'open3'
require 'csv'

# Wrapper minimale verso PostgreSQL tramite il client 'psql'.
# Nessuna gemma esterna: i parametri sono passati come variabili psql
# (-v nome=valore) e sostituiti nello script SQL con :'nome' o :nome,
# cosi' psql stesso si occupa dell'escaping -> nessuna SQL injection.
class Db
  class QueryError < StandardError; end

  ROLE = ENV.fetch('GYMMANAGER_DB_ROLE') { `whoami`.strip }
  DB_NAME = ENV.fetch('GYMMANAGER_DB_NAME', 'gymmanager')
  SOCKET_DIR = ENV.fetch('GYMMANAGER_DB_SOCKET', '/var/run/postgresql')

  # Esegue una query SQL con parametri nominali, restituisce un Array di Hash
  # (chiavi = nomi colonna, valori = String o nil per NULL).
  def self.query(sql, params = {})
    rows_csv = run(sql, params, csv: true)
    return [] if rows_csv.strip.empty?

    table = CSV.parse(rows_csv, headers: true, liberal_parsing: true)
    table.map do |row|
      row.to_h.transform_values { |v| v == '' ? nil : v }
    end
  end

  # Esegue un comando SQL (INSERT/UPDATE/DELETE) senza risultato tabellare.
  def self.exec(sql, params = {})
    run(sql, params, csv: false)
    true
  end

  def self.run(sql, params, csv:)
    args = %w[psql -X -q -v ON_ERROR_STOP=1]
    args += %w[-A --csv] if csv
    args += ['-U', ROLE, '-h', SOCKET_DIR, '-d', DB_NAME]
    params.each { |k, v| args += ['-v', "#{k}=#{v.nil? ? '' : v}"] }

    stdout, stderr, status = Open3.capture3(*args, stdin_data: sql)
    raise QueryError, stderr unless status.success?

    stdout
  end
end
