require_relative './test_helper'

class SyllabusWorkerTest < Minitest::Test
  def setup
    @tmp_dir = app.send(:tmp_dir) || '/tmp'
    app.set :tmp_dir, @tmp_dir

    @zip_file = File.join(@tmp_dir, 'syllabus.zip')
    SyllabusApp.settings.stubs(:tmp_dir).returns(@tmp_dir)

    Mail::Message.any_instance.expects(:deliver!)

    super
  end

  def teardown
    File.delete(@zip_file) if File.exists?(@zip_file)
  end

  def test_perform
    export_ids = ['1', '2', '3']
    export_courses = [
      {'syllabus_body' => 'A Syllabus Body', 'course_code' => 'COSC123'},
      {'syllabus_body' => 'Another one', 'course_code' => 'COSC124'},
      {'syllabus_body' => 'Do your assignments!', 'course_code' => 'COSC125'}
    ]

    export_courses.each_with_index do |response, i|
      stub_request(:get, /courses\/#{export_ids[i]}\?access_token=.+&include\[\]=syllabus_body/)
        .to_return(:body => response.to_json, :headers => {'Content-Type' => 'application/json'})
    end

    Redis.any_instance.stubs(:get).returns(nil)
    export_ids.each_with_index do |id, i|
      Redis.any_instance.expects(:set).with("course:#{id}:syllabus_body", export_courses[i]['syllabus_body'])
      Redis.any_instance.expects(:set).with("course:#{id}:course_code", export_courses[i]['course_code'])
    end

    SyllabusWorker.perform({'export_ids' => export_ids, 'user_email' => 'test@gmail.com'})

    assert File.exists?(@zip_file)
    Zip::File.open(@zip_file) do |zip|
      assert_equal export_ids.count, zip.size

      zip.each_with_index do |f, i|
        syllabus_file = File.join(@tmp_dir, f.name)
        zip.extract(f, syllabus_file)
        body = File.open(syllabus_file, 'r') {|f| f.read}
        assert_match /#{export_courses[i]['course_code']}.*\.html/, f.name
        assert_match /#{export_courses[i]['syllabus_body']}/, body
      end
    end
  end

  def test_perform_with_cached_data
    export_ids = ['1', '2', '3']
    export_courses = [
      {'syllabus_body' => 'A Syllabus Body', 'course_code' => 'COSC123'},
      {'syllabus_body' => 'Another one', 'course_code' => 'COSC124'},
      {'syllabus_body' => 'Do your assignments!', 'course_code' => 'COSC125'}
    ]

    export_ids.each_with_index do |id, i|
      Redis.any_instance.expects(:get).with("course:#{id}:syllabus_body")
                                      .returns(export_courses[i]['syllabus_body'])
      Redis.any_instance.expects(:get).with("course:#{id}:course_code")
                                       .returns(export_courses[i]['course_code'])
    end

    SyllabusWorker.perform({'export_ids' => export_ids, 'user_email' => 'test@gmail.com'})

    assert File.exists?(@zip_file)
    Zip::File.open(@zip_file) do |zip|
      assert_equal export_ids.count, zip.size
      zip.each_with_index do |f, i|
        syllabus_file = File.join(@tmp_dir, f.name)
        zip.extract(f, syllabus_file)
        body = File.open(syllabus_file, 'r') {|f| f.read}
        assert_match /#{export_courses[i]['course_code']}.*\.html/, f.name
        assert_match /#{export_courses[i]['syllabus_body']}/, body
      end
    end

    assert_not_requested :get, /.*/
  end

  def test_perform_with_empty_syllabus
    export_ids = ['1', '2', '3']
    export_courses = [
      {'syllabus_body' => 'A Syllabus Body', 'course_code' => 'COSC123'},
      {'syllabus_body' => 'Another one', 'course_code' => 'COSC124'},
      {'syllabus_body' => '', 'course_code' => 'COSC125'}
    ]

    export_courses.each_with_index do |response, i|
      stub_request(:get, /courses\/#{export_ids[i]}\?access_token=.+&include\[\]=syllabus_body/)
        .to_return(:body => response.to_json, :headers => {'Content-Type' => 'application/json'})
    end

    Redis.any_instance.stubs(:get).returns(nil)
    Redis.any_instance.stubs(:set)

    SyllabusWorker.perform({'export_ids' => export_ids, 'user_email' => 'test@gmail.com'})

    assert File.exists?(@zip_file)
    Zip::File.open(@zip_file) do |zip|
      assert_equal export_ids.count - 1, zip.size
      zip.each_with_index do |f, i|
        syllabus_file = File.join(@tmp_dir, f.name)
        zip.extract(f, syllabus_file)
        body = File.open(syllabus_file, 'r') {|f| f.read}
        assert_match /#{export_courses[i]['course_code']}.*\.html/, f.name
        assert_match /#{export_courses[i]['syllabus_body']}/, body
      end
    end
  end
end
