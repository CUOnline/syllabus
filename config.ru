require './syllabus_app'
require './syllabus_worker'

map('/auth') { run WolfCore::Auth }
map('/')     { run SyllabusApp }
