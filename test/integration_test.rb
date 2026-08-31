require_relative 'test_helper'
require_relative '../app'

class IntegrationTest < Minitest::Test
  def setup
    super
    @router = setup_router
  end

  def setup_router
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
      raise "Member not found" unless member
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
      raise "ActivityClass not found" unless activity_class
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

    router
  end

  def test_root_redirects_to_members
    request = Request.new(method: 'GET', path: '/', query: {}, headers: {}, body: '')
    response = @router.dispatch(request)
    assert_equal 302, response.status
    assert_equal '/members', response.headers['Location']
  end

  def test_create_member
    request = Request.new(
      method: 'POST',
      path: '/members',
      query: {},
      headers: { 'content-type' => 'application/x-www-form-urlencoded' },
      body: URI.encode_www_form({
        'first_name' => 'John',
        'last_name' => 'Doe',
        'birth_date' => '1990-01-01',
        'address' => 'Via Roma 1',
        'phone' => '3334445555',
        'email' => 'john@example.com'
      })
    )

    response = @router.dispatch(request)
    assert_equal 302, response.status

    members = Member.all
    assert_equal 1, members.length
    assert_equal 'John', members[0]['first_name']
  end

  def test_delete_member
    # Crea un membro
    Member.create({
      'first_name' => 'Jane',
      'last_name' => 'Smith',
      'birth_date' => '',
      'address' => 'Via Verdi 2',
      'phone' => '3339998888',
      'email' => 'jane@example.com'
    })

    members = Member.all
    assert_equal 1, members.length
    member_id = members[0]['id']

    # Cancella il membro
    request = Request.new(
      method: 'POST',
      path: "/members/#{member_id}/delete",
      query: {},
      headers: {},
      body: ''
    )

    response = @router.dispatch(request)
    assert_equal 302, response.status

    members = Member.all
    assert_equal 0, members.length
  end

  def test_update_member
    Member.create({
      'first_name' => 'Bob',
      'last_name' => 'Brown',
      'birth_date' => '1985-05-15',
      'address' => 'Via Blu 3',
      'phone' => '3331112222',
      'email' => 'bob@example.com'
    })

    members = Member.all
    member_id = members[0]['id']

    request = Request.new(
      method: 'POST',
      path: "/members/#{member_id}/edit",
      query: {},
      headers: { 'content-type' => 'application/x-www-form-urlencoded' },
      body: URI.encode_www_form({
        'first_name' => 'Roberto',
        'last_name' => 'Brown',
        'birth_date' => '1985-05-15',
        'address' => 'Via Blu 3',
        'phone' => '3331112222',
        'email' => 'roberto@example.com'
      })
    )

    response = @router.dispatch(request)
    assert_equal 302, response.status

    updated = Member.find(member_id)
    assert_equal 'Roberto', updated['first_name']
  end

  def test_create_activity_class
    request = Request.new(
      method: 'POST',
      path: '/classes',
      query: {},
      headers: { 'content-type' => 'application/x-www-form-urlencoded' },
      body: URI.encode_www_form({
        'name' => 'Yoga',
        'description' => 'Corsi di yoga',
        'schedule' => 'Lunedì ore 10',
        'instructor' => 'Anna'
      })
    )

    response = @router.dispatch(request)
    assert_equal 302, response.status

    classes = ActivityClass.all
    assert_equal 1, classes.length
    assert_equal 'Yoga', classes[0]['name']
  end

  def test_delete_activity_class
    ActivityClass.create({
      'name' => 'Pilates',
      'description' => 'Pilates avanzato',
      'schedule' => 'Martedì ore 15',
      'instructor' => 'Marco'
    })

    classes = ActivityClass.all
    assert_equal 1, classes.length
    class_id = classes[0]['id']

    request = Request.new(
      method: 'POST',
      path: "/classes/#{class_id}/delete",
      query: {},
      headers: {},
      body: ''
    )

    response = @router.dispatch(request)
    assert_equal 302, response.status

    classes = ActivityClass.all
    assert_equal 0, classes.length
  end

  def test_enroll_member_in_class
    Member.create({
      'first_name' => 'Emma',
      'last_name' => 'Wilson',
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

    request = Request.new(
      method: 'POST',
      path: "/classes/#{class_id}/enroll",
      query: {},
      headers: { 'content-type' => 'application/x-www-form-urlencoded' },
      body: URI.encode_www_form({ 'member_id' => member_id })
    )

    response = @router.dispatch(request)
    assert_equal 302, response.status

    enrolled = ActivityClass.members_of(class_id)
    assert_equal 1, enrolled.length
    assert_equal 'Emma', enrolled[0]['first_name']
  end
end
