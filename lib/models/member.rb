require_relative '../db'

class Member
  def self.all(name_filter: nil, status_filter: nil)
    sql = <<~SQL
      SELECT id, first_name, last_name, birth_date, address, phone, email, active
      FROM members
      WHERE (:'name' = '' OR (first_name || ' ' || last_name) ILIKE '%' || :'name' || '%')
        AND (:'status' = '' OR active = (:'status' = 'active'))
      ORDER BY last_name, first_name
    SQL
    Db.query(sql, name: name_filter.to_s, status: status_filter.to_s)
  end

  def self.find(id)
    Db.query("SELECT * FROM members WHERE id = :'id'::int", id: id).first
  end

  def self.create(attrs)
    sql = <<~SQL
      INSERT INTO members (first_name, last_name, birth_date, address, phone, email, active)
      VALUES (:'first_name', :'last_name', NULLIF(:'birth_date', '')::date, :'address', :'phone', :'email', TRUE)
    SQL
    Db.exec(sql, attrs)
  end

  def self.update(id, attrs)
    sql = <<~SQL
      UPDATE members
      SET first_name = :'first_name', last_name = :'last_name',
          birth_date = NULLIF(:'birth_date', '')::date,
          address = :'address', phone = :'phone', email = :'email',
          active = (:'active' = 'true')
      WHERE id = :'id'::int
    SQL
    Db.exec(sql, attrs.merge(id: id))
  end

  def self.delete(id)
    Db.exec("DELETE FROM members WHERE id = :'id'::int", id: id)
  end
end
