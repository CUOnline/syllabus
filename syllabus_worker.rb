require 'zip'
require 'tempfile'
require './syllabus'

class SyllabusWorker
  @queue = 'syllabus'

  def self.perform(params)
    syllabus_files = []

    Syllabus.resque_log.info(params)

    export_path = File.join('tmp', 'syllabus.zip')
    File.delete(export_path) if File.exists?(export_path)

    # Generate zipfile of syllabi html docs
    ::Zip::File.open(export_path, ::Zip::File::CREATE) do |zipfile|

      params['export_ids'].each do |id|
        # Values cached in redis to skip API calls when possible
        syllabus_body = Syllabus.redis.get("course:#{id}:syllabus_body")
        course_code = Syllabus.redis.get("course:#{id}:course_code")

        if syllabus_body.nil? || course_code.nil?
          url = "#{Syllabus.api_base}/courses/#{id}?include[]=syllabus_body"
          auth_token = {Authorization: "Bearer #{Syllabus.canvas_token}"}
          response = JSON.parse(RestClient.get(url, auth_token))

          syllabus_body = response['syllabus_body']
          course_code = response['course_code']

          Syllabus.redis.set("course:#{id}:syllabus_body", syllabus_body)
          Syllabus.redis.set("course:#{id}:course_code", course_code)
        end

        next if syllabus_body.empty?

        filename = "#{course_code}-#{id}".gsub(/[\/\ ]/, '-')
        Tempfile.open([filename, '.html'], 'tmp') do |file|
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
    mail.from = Syllabus.from_email
    mail.to = params['user_email']
    mail.subject = Syllabus.email_subject
    mail.body = "Attached are your exported syllabi\n"
    mail.add_file export_path
    mail.deliver!

    ensure
      syllabus_files.each { |file| file.close! } if syllabus_files
    end
end
