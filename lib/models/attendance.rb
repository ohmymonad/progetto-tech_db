require_relative '../db'

class Attendance
  def self.register(member_id, checked_in_at)
    sql = <<~SQL
      INSERT INTO attendances (member_id, checked_in_at)
      VALUES (:'member_id'::int, COALESCE(NULLIF(:'checked_in_at', '')::timestamp, now()))
    SQL
    Db.exec(sql, member_id: member_id, checked_in_at: checked_in_at)
  end

  def self.history(member_id)
    sql = <<~SQL
      SELECT id, checked_in_at
      FROM attendances
      WHERE member_id = :'member_id'::int
      ORDER BY checked_in_at DESC
    SQL
    Db.query(sql, member_id: member_id)
  end

  def self.stats(member_id)
    sql = <<~SQL
      SELECT
        COUNT(*) AS total_visits,
        ROUND(
          COUNT(*)::numeric /
          GREATEST(1, CEIL(EXTRACT(EPOCH FROM (now() - MIN(checked_in_at))) / 604800)::int),
          2
        ) AS weekly_average
      FROM attendances
      WHERE member_id = :'member_id'::int
    SQL
    Db.query(sql, member_id: member_id).first
  end
end
