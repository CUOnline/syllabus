require 'zip'
require 'tempfile'
require './syllabus_app'

class SyllabusWorker
  @queue = 'syllabus'

  def self.perform(params)
    syllabus_files = []

    export_path = File.join(SyllabusApp.tmp_dir, 'syllabus.zip')
    File.delete(export_path) if File.exists?(export_path)

    # Generate zipfile of syllabi html docs
    ::Zip::File.open(export_path, ::Zip::File::CREATE) do |zipfile|

      params['export_ids'].each do |id|
        # Values cached in redis to skip API calls when possible
        syllabus_body = SyllabusApp.redis.get("course:#{id}:syllabus_body")
        course_code = SyllabusApp.redis.get("course:#{id}:course_code")

        if syllabus_body.nil? || course_code.nil?
          course = SyllabusApp.canvas_api(:get, "courses/#{id}?include[]=syllabus_body")

          syllabus_body = course['syllabus_body']
          course_code = course['course_code']


          SyllabusApp.redis.set("course:#{id}:syllabus_body", syllabus_body)
          SyllabusApp.redis.set("course:#{id}:course_code", course_code)
        end

        next if syllabus_body.nil? || syllabus_body.empty?

        filename = "#{course_code}-#{id}".gsub(/[\/\ ]/, '-')
        Tempfile.open([filename, '.html'], SyllabusApp.tmp_dir) do |file|
          file.write('<meta charset="utf-8">')
          file.write(syllabus_body)

          # Needs reference to tempfile to avoid garbage collection until zipped
          syllabus_files << file

          zipfile.add(file.path.split('/').last, file.path)
        end
      end

    end

    output_file = File.new(export_path)

    mail = Mail.new
    mail.from = SyllabusApp.from_email
    mail.to = params['user_email']
    mail.subject = SyllabusApp.email_subject
    mail.body = "Attached are your exported syllabi\n"
    mail.add_file export_path
    mail.deliver!

    ensure
      syllabus_files.each { |file| file.close! } if syllabus_files
    end
end
