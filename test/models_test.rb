require_relative 'test_helper'

class MemberModelTest < Minitest::Test
  def test_create_member
    Member.create({
      'first_name' => 'Mario',
      'last_name' => 'Rossi',
      'birth_date' => '1990-01-01',
      'address' => 'Via Roma 1',
      'phone' => '3334445555',
      'email' => 'mario@example.com'
    })

    members = Member.all
    assert_equal 1, members.length
    assert_equal 'Mario', members[0]['first_name']
    assert_equal 'Rossi', members[0]['last_name']
    assert_equal 't', members[0]['active']
  end

  def test_find_member
    Member.create({
      'first_name' => 'Alice',
      'last_name' => 'Bianchi',
      'birth_date' => '',
      'address' => 'Via Verdi 2',
      'phone' => '3339998888',
      'email' => 'alice@example.com'
    })

    members = Member.all
    id = members[0]['id']

    member = Member.find(id)
    assert_equal 'Alice', member['first_name']
    assert_equal 'Bianchi', member['last_name']
  end

  def test_update_member
    Member.create({
      'first_name' => 'Bob',
      'last_name' => 'Neri',
      'birth_date' => '1985-05-15',
      'address' => 'Via Blu 3',
      'phone' => '3331112222',
      'email' => 'bob@example.com'
    })

    members = Member.all
    id = members[0]['id']

    Member.update(id, {
      'first_name' => 'Roberto',
      'last_name' => 'Neri',
      'birth_date' => '1985-05-15',
      'address' => 'Via Blu 3',
      'phone' => '3331112222',
      'email' => 'roberto@example.com',
      'active' => 'false'
    })

    updated = Member.find(id)
    assert_equal 'Roberto', updated['first_name']
    assert_equal 'f', updated['active']
  end

  def test_delete_member
    Member.create({
      'first_name' => 'Carol',
      'last_name' => 'Verdi',
      'birth_date' => '',
      'address' => 'Via Gialla 4',
      'phone' => '3337776666',
      'email' => 'carol@example.com'
    })

    assert_equal 1, Member.all.length

    members = Member.all
    id = members[0]['id']

    Member.delete(id)
    assert_equal 0, Member.all.length
  end

  def test_member_with_accents_and_apostrophes
    Member.create({
      'first_name' => "José D'Angelo",
      'last_name' => 'Pérez',
      'birth_date' => '',
      'address' => "Via dell'Università",
      'phone' => '3334445555',
      'email' => 'jose@example.com'
    })

    members = Member.all
    assert_equal 1, members.length
    assert_equal "José D'Angelo", members[0]['first_name']
    assert_equal 'Pérez', members[0]['last_name']
  end

  def test_member_with_newline_in_address
    Member.create({
      'first_name' => 'Dave',
      'last_name' => 'Smith',
      'birth_date' => '',
      'address' => "123 Main St\nApt 4B",
      'phone' => '3334445555',
      'email' => 'dave@example.com'
    })

    members = Member.all
    assert_equal 1, members.length
    assert_equal "123 Main St\nApt 4B", members[0]['address']
  end

  def test_find_nonexistent_returns_nil
    result = Member.find('99999')
    assert_nil result
  end
end

class ActivityClassModelTest < Minitest::Test
  def test_create_activity_class
    ActivityClass.create({
      'name' => 'Yoga',
      'description' => 'Corsi di yoga per principianti',
      'schedule' => 'Lunedì ore 10',
      'instructor' => 'Anna'
    })

    classes = ActivityClass.all
    assert_equal 1, classes.length
    assert_equal 'Yoga', classes[0]['name']
  end

  def test_find_activity_class
    ActivityClass.create({
      'name' => 'Pilates',
      'description' => 'Pilates avanzato',
      'schedule' => 'Martedì ore 15',
      'instructor' => 'Marco'
    })

    classes = ActivityClass.all
    id = classes[0]['id']

    activity_class = ActivityClass.find(id)
    assert_equal 'Pilates', activity_class['name']
  end

  def test_delete_activity_class
    ActivityClass.create({
      'name' => 'CrossFit',
      'description' => 'Allenamento intenso',
      'schedule' => 'Giovedì ore 18',
      'instructor' => 'Luca'
    })

    assert_equal 1, ActivityClass.all.length

    classes = ActivityClass.all
    id = classes[0]['id']

    ActivityClass.delete(id)
    assert_equal 0, ActivityClass.all.length
  end

  def test_find_nonexistent_returns_nil
    result = ActivityClass.find('99999')
    assert_nil result
  end
end

class EnrollmentTest < Minitest::Test
  def test_enroll_member_in_class
    Member.create({
      'first_name' => 'Emma',
      'last_name' => 'Gialli',
      'birth_date' => '',
      'address' => 'Via Rossa 5',
      'phone' => '3335554444',
      'email' => 'emma@example.com'
    })

    ActivityClass.create({
      'name' => 'Zumba',
      'description' => 'Danza e fitness',
      'schedule' => 'Mercoledì ore 19',
      'instructor' => 'Sofia'
    })

    members = Member.all
    classes = ActivityClass.all
    member_id = members[0]['id']
    class_id = classes[0]['id']

    ActivityClass.enroll(member_id, class_id)

    enrolled = ActivityClass.members_of(class_id)
    assert_equal 1, enrolled.length
    assert_equal 'Emma', enrolled[0]['first_name']
  end
end
