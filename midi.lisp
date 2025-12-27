(in-package :implanted-memories-2)


(defun fill-array (arr val)
  (dotimes (i (array-total-size arr))
    (setf (row-major-aref arr i) val)))

(defconstant +number-of-midi-channels+ 16)
(defconstant +number-of-midi-notes+ 128)

(defparameter *key-pitchclasses* '((0 . 1)
                                   (1 . 3)
                                   (2 . 7)
                                   (3 . 11)
                                   (4 . 13)
                                   (5 . 16)
                                   (6 . 18)
                                   (7 . 22)
                                   (8 . 24)
                                   (9 . 28)
                                   (10 . 32)
                                   (11 . 34))
  "CAR is MIDI pitchclass, CDR is Arciorgano key number class (ordini 1 and 2).")

(defun lookup-key-pitchclass (midi-pitchclass)
  (cdr (assoc midi-pitchclass *key-pitchclasses*)))

(defun midi-to-keynum (midi-pitch)
  (let ((octaves (- (floor (/ midi-pitch 12)) 3))
        (midi-pitchclass (mod midi-pitch 12)))
    (+ (* 36 octaves) (lookup-key-pitchclass midi-pitchclass))))


(defparameter *aftertouch-states*
  (make-array (list +number-of-midi-channels+ +number-of-midi-notes+) :initial-element 0))

(defun valid-aftertouch-subscripts-p (channel note)
  (and (< -1 channel +number-of-midi-channels+)
       (< -1 note +number-of-midi-notes+)))

(defun update-aftertouch-state (channel note value)
  (when (valid-aftertouch-subscripts-p channel note)
    (when (and (get-midi-note-state channel note)
               (not (= value (aref *aftertouch-states* channel note))))
      (parse-key channel nil note))
    (setf (aref *aftertouch-states* channel note) value)
    (when (get-midi-note-state channel note)
      (parse-key channel t note))))

(defun get-aftertouch-state (channel note)
  (when (valid-aftertouch-subscripts-p channel note)
    (aref *aftertouch-states* channel note)))

(defun reset-all-aftertouch-states ()
  (fill-array *aftertouch-states* 0))



(defparameter *midi-note-states*
  (make-array (list +number-of-midi-channels+ +number-of-midi-notes+) :initial-element nil))

(defun valid-midi-state-subscripts-p (channel note)
  (and (< -1 channel +number-of-midi-channels+)
       (< -1 note +number-of-midi-notes+)))

(defun update-midi-note-state (channel note state)
  (when (valid-midi-state-subscripts-p channel note)
    (setf (aref *midi-note-states* channel note) state)))

(defun get-midi-note-state (channel note)
  (when (valid-midi-state-subscripts-p channel note)
    (aref *midi-note-states* channel note)))

(defun reset-all-midi-note-states ()
  (fill-array *midi-note-states* nil))


(defconstant +number-of-keys+ 146)

(defparameter *key-states* (make-array +number-of-keys+ :initial-element nil))

(defun valid-key-state-subscript-p (key)
  (< 0 key 147))

(defun update-key-state (channel key state)
  (when (valid-key-state-subscript-p key)
    (let ((original-state (aref *key-states* key)))
      (if state
          (unless (member channel (aref *key-states* key))
            (push channel (aref *key-states* key)))
          (setf (aref *key-states* key)
                (remove channel (aref *key-states* key))))
      (let ((new-state (aref *key-states* key)))
        (when (or (and original-state (not new-state))
                  (and (not original-state) new-state))
          ;; (format t "~&TRIGGER: Key ~a updated to state ~a" key new-state)
          (trigger-effects-processing channel key new-state)
          ;; (osc-send key new-state)
          )))))

(defun get-key-state (key)
  (when (valid-key-state-subscript-p key)
    (aref *key-states* key)))

(defun get-all-active-keys (channel)
  (let ((result nil))
    (dotimes (key +number-of-keys+)
      (when (member channel (aref *key-states* key))
        (push key result)))
    result))

(defun reset-all-key-states ()
  (fill-array *key-states* nil))







(defun parse-key (channel onp midi-note)
  "If ONP is T, the key will be switched on, if NIL, switched off."
  (let ((aftertouch (get-aftertouch-state channel midi-note)))
    (when (zerop aftertouch) (setf aftertouch 64))
    (update-key-state channel
                      (+ (- aftertouch 64) (midi-to-keynum midi-note))
                      onp)))







(defconstant +number-of-controllers+ 16
  "Number of used controller IDs. On the Faderfox EC4 this refers to the number of 'Setups', which is 16.")

(defconstant +number-of-channels+ 127
  "Number of channels in use. On the Faderfox EC4 this is 127 channels per 'Setup'.")

(defparameter *midi-callbacks* (make-array (list +number-of-controllers+ +number-of-channels+)
                                           :initial-element nil)
  "Stores the callback function for each MIDI channel. Can be populated from anywhere.")

(defun valid-subscripts-p (controller channel)
  "Checks ranges."
  (and (>= controller 0)
       (< controller +number-of-controllers+)
       (>= channel 0)
       (< channel +number-of-channels+)))

(defun midi-responder (a b c &optional d)
  "Callback function for the MIDI listener. This function is called whenever there is incoming MIDI
data."
  (declare (ignore d))
  (cond
    ;; MIDI note off messages
    ((< 127 a 144)
     (let ((channel (- a 128))
           (midi-note b)
           (velocity c))
       (format t "~&Note off, channel ~a, pitch ~a, off velocity ~a.~%"
               channel midi-note velocity)
       (update-midi-note-state channel midi-note nil)
       (parse-key channel nil midi-note)))
    ;; MIDI note on messages
    ((< 143 a 160)
     (let ((channel (- a 144))
           (midi-note b)
           (velocity c))
       (format t "~&Note on, channel ~a, pitch ~a, velocity ~a.~%"
               channel midi-note velocity)
       (update-midi-note-state channel midi-note t)
       (parse-key channel t midi-note)))
    ;; MIDI aftertouch (per note, per channel) messages
    ((< 159 a 176)
     (let ((channel (- a 160))
           (midi-note b)
           (value c))
       (format t "~&Poly aftertouch, channel ~a, midi note ~a, value ~a.~%"
               channel midi-note value)
       (update-aftertouch-state channel midi-note value)))
    ;; MIDI controller change messages
    ((< 175 a 192)
     (let ((channel (- a 176))
           (controller b)
           (value c))
       (format t "~&Controller, channel ~a, controller id ~a, value ~a.~%"
               channel
               controller
               value)
       (case controller
         (102 (update-effect channel "clustercloud" value)))))
    (t (format t "~&Ignored MIDI data: [~a, ~a, ~a]." a b c))))






;; TODO This is old Faderfox code, to be adapted to act on data properly.
;; (if (valid-subscripts-p controller channel)
;;     (let ((callback-fun (aref *midi-callbacks* controller channel)))
;;       (if callback-fun
;;           (funcall callback-fun value-raw)
;;           (log:warn "No callback function defined for setup ~a, channel ~a."
;;                     controller channel)))
;;     (log:warn "No MIDI slot defined for setup ~a, channel ~a." controller channel))

(defun register-callback (controller channel callback-fun)
  "Exported function to be used to store a callback function for a controller channel."
  (cond ((valid-subscripts-p controller channel)
         (when (functionp (aref *midi-callbacks* controller channel))
           (log:info "Redefining callback function for controller ~a, channel ~a."
                     controller channel))
         (setf (aref *midi-callbacks* controller channel) callback-fun))
        (t (error "MIDI subscripts out of range."))))

(defun print-callbacks ()
  (dotimes (controller +number-of-controllers+)
    (dotimes (channel +number-of-channels+)
      (let ((callback (aref *midi-callbacks* controller channel)))
        (when callback (format t "~&Setup ~a, Controller ~a: ~a"
                               (1+ controller)
                               channel
                               (documentation callback 'function)))))))





(defparameter *midi-in* nil)
(defparameter *midi-responder* nil)

(defun incudine-real-time-p ()
  (let ((status (incudine:rt-status)))
    (cond ((eq status :started) t)
          ((eq status :stopped) nil)
          (t (log:warn "Incudine RT-STATUS '~a' is unknown and will be treated as :STOPPED."
                       status)))))

(defun start-incudine-rt ()
  (unless (incudine-real-time-p)
    (incudine:rt-start))
  (unless (incudine-real-time-p)
    (error "Incudine is not able to run in real time.")))





;; Not necessary if only internal MIDI data from JackMIDI is used.
;; (defun init-port-midi ()
;;   (let ((status (pm:initialize)))
;;     (unless (eq status :pm-no-error)
;;       (error "Portmidi could not be initialized."))))

;; (defun find-faderfox-id (faderfox-name-string)
;;   (pm:print-devices-info :input)
;;   (let ((id (pm:get-device-id-by-name faderfox-name-string :input)))
;;     (if id id (error 'acond:faderfox-id-not-found
;;                      :faderfox-name faderfox-name-string))))




(defun init-jack-midi ()
  (when (and *midi-in* (jackmidi:open-p *midi-in*)) (jackmidi:close *midi-in*))
  (setf *midi-in* (jackmidi:open)))


(defun init-midi ()
  (init-jack-midi)

  (when *midi-in*
    (incudine:recv-stop *midi-in*)
    (incudine:remove-all-responders *midi-in*)
    (setf *midi-responder*
          (incudine:make-responder *midi-in* (lambda (a b c) (midi-responder a b c))))
    (incudine:recv-start *midi-in*)
    (sleep 1)
    (if (eq (incudine:recv-status *midi-in*) :running)
      (log:info "MIDI listener is running.")
      (log:warn "MIDI listener is not running.")))

  (restart-case (start-incudine-rt)
    (continue-without-rt () :report "Don't attempt to start real time." nil)))
