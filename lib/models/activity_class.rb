require_relative '../db'

class ActivityClass
  def self.all
    Db.query('SELECT id, name, description, schedule, instructor FROM classes ORDER BY name')
  end

  def self.find(id)
    Db.query("SELECT * FROM classes WHERE id = :'id'::int", id: id).first
  end

  def self.members_of(class_id)
    sql = <<~SQL
      SELECT m.id, m.first_name, m.last_name
      FROM members m
      JOIN enrollments e ON e.member_id = m.id
      WHERE e.class_id = :'class_id'::int
      ORDER BY m.last_name, m.first_name
    SQL
    Db.query(sql, class_id: class_id)
  end

  def self.create(attrs)
    sql = <<~SQL
      INSERT INTO classes (name, description, schedule, instructor)
      VALUES (:'name', :'description', :'schedule', :'instructor')
    SQL
    Db.exec(sql, attrs)
  end

  def self.update(id, attrs)
    sql = <<~SQL
      UPDATE classes SET name = :'name', description = :'description',
                          schedule = :'schedule', instructor = :'instructor'
      WHERE id = :'id'::int
    SQL
    Db.exec(sql, attrs.merge(id: id))
  end

  def self.delete(id)
    Db.exec("DELETE FROM classes WHERE id = :'id'::int", id: id)
  end

  def self.enroll(member_id, class_id)
    sql = <<~SQL
      INSERT INTO enrollments (member_id, class_id)
      VALUES (:'member_id'::int, :'class_id'::int)
      ON CONFLICT DO NOTHING
    SQL
    Db.exec(sql, member_id: member_id, class_id: class_id)
  end
end
