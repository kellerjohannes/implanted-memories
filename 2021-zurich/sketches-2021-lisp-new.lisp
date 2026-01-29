;(require :incudine)

;(in-package :scratch)

;(rt-start)


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

(defun aux (id state)
  (format t "[aux~a:~a]" (if (equal id 'a) "A" "B") (if (equal state 'on) "on" "off"))
  (osc:message *oscout*
	       "/studio31/v1.0/jkeller/arciorgano/aux" ...))
  

(defun note (key-number duration)
  (key key-number 'on)
  (at (+ (now) duration)
      #'key key-number 'off))

(defun note-t (time key-number duration)
  (at time #'note key-number duration))
   
(defun cluster (first-key last-key duration)
  (do ((i first-key (1+ i)))
      ((> i last-key) nil)
    (note i duration)))

(defun cluster-arp (first-key last-key duration spread)
  (do ((i first-key (1+ i))
       (timer 0 (+ timer spread))
       (timer2 (* (- last-key first-key) spread) (- timer2 spread)))
      ((> i last-key) nil)
    (note-t (+ (now) timer) i (+ duration timer2))))

(defun gliss (first-key last-key duration spread)
  (cond ((= first-key last-key) nil)
	(t (note first-key duration)
	   (at (+ (now) spread)
	       #'gliss
	       (1+ first-key)
	       last-key
	       duration
	       spread))))

(defvar *durations* '((short 2000) (medium 30000) (long 88000)))
(setq *durations* '((short 3000) (medium 30000) (long 88000)))

(defun dur (id)
  (first (rest (assoc id *durations*))))


(defun panic ()
  (do ((i 0 (1+ i)))
      ((> i 146) nil)
    (key i 'off)))

