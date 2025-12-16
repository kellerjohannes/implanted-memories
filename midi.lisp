(in-package :implanted-memories-2)

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
  (cond ((< 143 a 160)
         (format t "~&Note on [pitch ~a, velocity ~a], Channel ~a.~%" b c (- a 143)))
        ((< 127 a 144)
         (format t "~&Note off [pitch ~a, off velocity ~a], Channel ~a.~%" b c (- a 127)))
        ((< 175 a 192)
         (format t "~&Parameter ~a, value ~a. Channel: ~a~%" (- a 175) c (1+ b)))
        (t (format t "~&Ignored MIDI data: [~a, ~a, ~a]." a b c)))


  ;; TODO This is old Faderfox code, to be adapted to act on data properly.
  ;; (if (valid-subscripts-p controller channel)
  ;;     (let ((callback-fun (aref *midi-callbacks* controller channel)))
  ;;       (if callback-fun
  ;;           (funcall callback-fun value-raw)
  ;;           (log:warn "No callback function defined for setup ~a, channel ~a."
  ;;                     controller channel)))
  ;;     (log:warn "No MIDI slot defined for setup ~a, channel ~a." controller channel))
  )

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
