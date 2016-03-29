require './syllabus_app'
require './syllabus_worker'

map('/auth') { run Wolf::Auth }
map('/')     { run SyllabusApp }
