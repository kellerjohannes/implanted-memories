(in-package :implanted-memories-2)


(defparameter *osc-out* nil)

;; localhost: "127.0.0.1"
;; arcinetwork:   "192.168.1.10"

(defun osc-init (&optional (port 5900) (host "127.0.0.1"))
  (incudine:rt-start)
  (setf *osc-out* (osc:open :port port :direction :output :host host)))

(defun osc-send (key state)
  (osc:message *osc-out* "/incudine-bridge" "ii" key (if state 1 0)))
