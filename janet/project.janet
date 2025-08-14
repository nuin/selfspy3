(declare-project
  :name "selfspy"
  :description "Modern activity monitoring in Janet - Lisp-like with C interop"
  :author "Selfspy Team"
  :license "MIT"
  :url "https://github.com/selfspy/selfspy3"
  :repo "git+https://github.com/selfspy/selfspy3.git"
  :dependencies [
    "https://github.com/janet-lang/sqlite3.git"
    "https://github.com/janet-lang/json.git"
  ])

(declare-source
  :source ["selfspy.janet"])

(declare-executable
  :name "selfspy"
  :entry "selfspy.janet")

(declare-binpath "/usr/local/bin")