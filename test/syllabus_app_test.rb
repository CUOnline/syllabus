require_relative './test_helper'

class SyllabusAppTest < Minitest::Test
  def test_get
    login
    get '/'
    assert_equal 200, last_response.status
  end

  def test_get_view
    course_id = '1'
    syllabus_body = 'Body'
    app.any_instance.expects(:canvas_api)
                    .with(:get, "courses/#{course_id}?include[]=syllabus_body")
                    .returns({'syllabus_body' => syllabus_body})

    login
    get "/view/#{course_id}"

    assert_equal 200, last_response.status
    assert_match /#{syllabus_body}/, last_response.body
  end


  def test_get_view_empty_syllabus
    course_id = '1'
    syllabus_body = ''
    app.any_instance.expects(:canvas_api)
                    .with(:get, "courses/#{course_id}?include[]=syllabus_body")
                    .returns({'syllabus_body' => syllabus_body})

    login
    get "/view/#{course_id}"

    assert_equal 200, last_response.status
    assert_match /Syllabus missing or empty/, last_response.body
  end

  def test_post_export
    export_ids = ['1', '2', '3']
    worker_params = {'export_ids' => export_ids, 'user_email' => 'test@gmail.com'}
    Resque.expects(:enqueue).with(SyllabusWorker, worker_params)

    login
    post '/export', {'export_ids' => export_ids}
  end

  def test_post
    courses = [
      {"id":123,"name":'Course 1'},
      {"id":124,"name":'Course 2'},
      {"id":125,"name":'Course 3'},
      {"id":126,"name":'Course 4'}
    ]

    app.any_instance.expects(:canvas_data).returns(courses)

    login
    post '/'

    assert_equal 200, last_response.status
    courses.each do |course|
      assert_match /#{course['name']}/, last_response.body
    end
  end
end
