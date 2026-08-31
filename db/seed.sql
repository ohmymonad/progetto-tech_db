-- Dati di esempio per GymManager

INSERT INTO members (first_name, last_name, birth_date, address, phone, email, active) VALUES
  ('Giulia', 'Ferrari', '1994-03-12', 'Via Roma 10, Milano', '333-1234567', 'giulia.ferrari@example.com', TRUE),
  ('Marco', 'Bianchi', '1988-07-22', 'Via Dante 5, Milano', '333-2345678', 'marco.bianchi@example.com', TRUE),
  ('Elena', 'Conti', '1999-11-02', 'Corso Italia 3, Milano', '333-3456789', 'elena.conti@example.com', FALSE)
ON CONFLICT DO NOTHING;

INSERT INTO classes (name, description, schedule, instructor) VALUES
  ('Yoga', 'Lezione di yoga per tutti i livelli', 'Lun-Mer-Ven 09:00', 'Sara Villa'),
  ('Functional Training', 'Allenamento funzionale ad alta intensita''', 'Mar-Gio 18:30', 'Luca Rinaldi'),
  ('Pilates', 'Rinforzo muscolare e postura', 'Sab 10:00', 'Sara Villa')
ON CONFLICT DO NOTHING;

INSERT INTO enrollments (member_id, class_id)
SELECT m.id, c.id FROM members m, classes c
WHERE m.email = 'giulia.ferrari@example.com' AND c.name = 'Yoga'
ON CONFLICT DO NOTHING;

INSERT INTO enrollments (member_id, class_id)
SELECT m.id, c.id FROM members m, classes c
WHERE m.email = 'marco.bianchi@example.com' AND c.name = 'Functional Training'
ON CONFLICT DO NOTHING;

INSERT INTO attendances (member_id, checked_in_at)
SELECT m.id, now() - interval '2 days' FROM members m WHERE m.email = 'giulia.ferrari@example.com'
UNION ALL
SELECT m.id, now() - interval '9 days' FROM members m WHERE m.email = 'giulia.ferrari@example.com'
UNION ALL
SELECT m.id, now() - interval '1 day' FROM members m WHERE m.email = 'marco.bianchi@example.com';
