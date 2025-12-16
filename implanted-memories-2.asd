(asdf:defsystem "implanted-memories-2"
  :depends-on (:incudine :alexandria :log4cl)
  :serial t
  :components ((:file "package")
               (:file "midi")
               (:file "osc")
               (:file "effects")
               ))
