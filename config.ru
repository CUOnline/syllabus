require './syllabus'
require './syllabus_worker'

map('/auth') { run Wolf::Auth }
map('/')     { run Syllabus }
