require_relative 'test_helper'

class RouterTest < Minitest::Test
  def test_root_path_matches
    router = Router.new
    router.get('/') { |_req| Response.new(200, 'home') }

    request = Request.new(
      method: 'GET',
      path: '/',
      query: {},
      headers: {},
      body: ''
    )

    response = router.dispatch(request)
    assert_equal 200, response.status
    assert_equal 'home', response.body
  end

  def test_unknown_route_returns_404
    router = Router.new
    request = Request.new(
      method: 'GET',
      path: '/unknown',
      query: {},
      headers: {},
      body: ''
    )

    response = router.dispatch(request)
    assert_equal 404, response.status
  end

  def test_route_params_are_strings_not_symbols
    router = Router.new
    router.get('/members/:id') do |req|
      # I parametri devono essere recuperati come String, non Symbol
      id = req.params['id']
      Response.new(200, id.nil? ? 'nil' : id)
    end

    request = Request.new(
      method: 'GET',
      path: '/members/42',
      query: {},
      headers: {},
      body: ''
    )

    response = router.dispatch(request)
    assert_equal 200, response.status
    assert_equal '42', response.body
  end

  def test_post_params_from_body
    router = Router.new
    router.post('/members') do |req|
      name = req.params['name']
      Response.new(200, name || 'nil')
    end

    request = Request.new(
      method: 'POST',
      path: '/members',
      query: {},
      headers: { 'content-type' => 'application/x-www-form-urlencoded' },
      body: 'name=Alice'
    )

    response = router.dispatch(request)
    assert_equal 200, response.status
    assert_equal 'Alice', response.body
  end
end
