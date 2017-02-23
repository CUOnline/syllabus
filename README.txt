This app provides an interface to view and export course syllabi, and is searchable by department, course name, and enrollment term. Departments do not exist as data entities in Canvas, so the abbreviations for these are hard-coded as an array in the "departments" app setting.

The search is performed through the wolf_core canvas_data helper, which queries the Canvas Redshift database. It searches for a course code matching the department code and a course name matching the search term, within the selected enrollment term. Each search result will have a "view syllabus" link for viewing the syllabus content itself.  Not all courses that turn up in search results will syllabus content, as there is no way to filter these out before the response comes back.

After search results are loaded, they are iterated through in javascript (main.js) and an asynchronous request is made to the "view" endpoint to check if there is any syllabus content. This allows filtering out of empty syllabi.

Finally, a user may select checkboxes of one or more (or all) search results and export them as a zip of html files. This is a potentially long-running process, and is therefore done in a Resque worker (syllabus_worker.rb). Once the worker has collected all the files, the zip is emailed to the user. The email used is obtained from Canvas when the user logs in (see wolf_core helpers.rb oauth_callback method) and stored in a session variable. There is a systemd worker service that runs the Resque rake:work task to ensure that the worker is always on and waiting for jobs.

All routes require authentication through Canvas (see sinatra-canvas_auth gem) and only Admin roles are permitted access.
