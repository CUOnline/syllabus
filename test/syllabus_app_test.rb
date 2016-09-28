require_relative './test_helper'

class SyllabusAppTest < Minitest::Test
  def test_get
    app.expects(:enrollment_terms).returns({
      'Spring 2015' => '1234',
      'Fall 2016' => '4567',
    })

    login
    get '/'

    assert_equal 200, last_response.status
    assert_match /Fall 2016/, last_response.body
    assert_match /Spring 2015/, last_response.body
  end

  def test_get_unauthenticated
    get '/'
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/canvas-auth-login', last_request.path
  end

  def test_get_unauthorized
    login({'user_roles' => ['StudentEnrollment']})
    get '/'
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/unauthorized', last_request.path
  end

  def test_get_view
    course_id = '1'
    syllabus_body = 'Body'
    stub_request(:get, /courses\/#{course_id}\?access_token=.+&include\[\]=syllabus_body/)
      .to_return(:body => {'syllabus_body' => syllabus_body}.to_json,
                 :headers => {'Content-Type' => 'application/json'})

    login
    get "/view/#{course_id}"

    assert_equal 200, last_response.status
    assert_match /#{syllabus_body}/, last_response.body
  end

  def test_get_view_empty_syllabus
    course_id = '2'
    stub_request(:get, /courses\/#{course_id}\?access_token=.+&include\[\]=syllabus_body/)
      .to_return(:body => {'syllabus_body' => ''}.to_json,
                 :headers => {'Content-Type' => 'application/json'})

    login
    get "/view/#{course_id}"

    assert_equal 200, last_response.status
    assert_match /Syllabus missing or empty/, last_response.body
  end

  def test_get_view_unauthenticated
    get '/view/1'
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/canvas-auth-login', last_request.path
  end

  def test_get_view_unauthorized
    login({'user_roles' => ['StudentEnrollment']})
    get '/view/1'
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/unauthorized', last_request.path
  end

  def test_post_export
    export_ids = ['1', '2', '3']
    worker_params = {'export_ids' => export_ids, 'user_email' => 'test@example.com'}
    Resque.expects(:enqueue).with(SyllabusWorker, worker_params)

    login
    post '/export', {'export_ids' => export_ids}

    assert_equal 302, last_response.status
    assert_match /Syllabi are being collected/,
                 last_request.env['rack.session']['flash'][:success]

    follow_redirect!
    assert_equal '/', last_request.path
    assert_equal 200, last_response.status
  end

  def test_post_export_without_ids
    login
    post '/export'

    assert_equal 302, last_response.status
    assert_match /You must select at least one/,
                 last_request.env['rack.session']['flash'][:danger]

    follow_redirect!
    assert_equal '/', last_request.path
    assert_equal 200, last_response.status
  end

  def test_post
    courses = [
      {"id":123,"name":'Course 1'},
      {"id":124,"name":'Course 2'},
      {"id":125,"name":'Course 3'},
      {"id":126,"name":'Course 4'}
    ]

    app.expects(:enrollment_terms).returns({})
    app.any_instance.expects(:canvas_data).returns(courses)

    login
    post '/'

    assert_equal 200, last_response.status
    courses.each do |course|
      assert_match /#{course['name']}/, last_response.body
    end
  end

  def test_post_unauthenticated
    post '/'
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/canvas-auth-login', last_request.path
  end

  def test_post_unauthorized
    login({'user_roles' => ['StudentEnrollment']})
    post '/'
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/unauthorized', last_request.path
  end
end
