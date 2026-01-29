;; sketches for polina

(defvar *oscout* (osc:open :direction :output :host "10.209.132.109" :port 5900))

(defun connect ()
  (osc:open :direction :output :protocol :udp :host "10.209.132.109" :port 5900))


(defun key (key-number state)
  (format t "[~a:~a]" key-number (if (equal state 'on) "on" "off"))
  (osc:message *oscout*
	       "/studio31/v1.0/jkeller/arciorgano/nkey"
	       "ii"
	       key-number
	       (if (equal state 'on) 1 0))
  nil)

(defun note (key-number duration)
  (key key-number 'on)
  (at (+ (now) (* duration *sample-rate*))
      #'key key-number 'off))

(defun upside-down (time)
  (at (+ (now) time) (setq *durations* '((short 5) (medium 1) (long .5)))))

(defvar *durations* '((short .3) (medium .8) (long 1))))

(defun dur (id)
  (first (rest (assoc id *durations*))))


(defun note-future (key-number start-time duration)
  (at (+ (now) (* start-time *sample-rate*))
      #'note key-number duration))

