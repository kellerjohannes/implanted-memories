(in-package :implanted-memories-2)






(defparameter *effect-key-states*
  (make-array +number-of-keys+ :initial-element nil))

(defun update-effect-key (channel key state)
  (let ((original-state (aref *effect-key-states* key)))
    (if state
        (unless (member channel (aref *effect-key-states* key))
          (push channel (aref *effect-key-states* key)))
        (setf (aref *effect-key-states* key)
              (remove channel (aref *effect-key-states* key))))
    (let ((new-state (aref *effect-key-states* key)))
      (when (or (and original-state (not new-state))
                (and (not original-state) new-state))
        (format t "~&TRIGGER OSC SENT.")
        (osc-send key new-state)))))

(defun get-effect-key-state (key)
  (aref *effect-key-states* key))


(defun reset-all-effect-keys ()
  (fill-array *effect-key-states* nil))



(defun reset-all-states ()
  (reset-all-effect-keys)
  (reset-all-key-states)
  (reset-all-aftertouch-states)
  (reset-all-midi-note-states))

(defun panic ()
  (reset-all-states)
  (loop for key from 1 to +number-of-keys+
        do (osc-send key nil)))

(defun show-all-states ()
  (dotimes (channel +number-of-midi-channels+)
    (dotimes (note +number-of-midi-notes+)
      (when (plusp (get-aftertouch-state channel note))
        (format t "~&Aftertouch channel ~a, note ~a is ~a."
                channel
                note
                (get-aftertouch-state channel note)))
      (when (get-midi-note-state channel note)
        (format t "~&MIDI note state channel ~a, note ~a is ~a."
                channel
                note
                (get-midi-note-state channel note)))))
  (dotimes (key (1- +number-of-keys+))
    (when (get-key-state (1+ key))
      (format t "~&Key ~a state is ~a." (1+ key) (get-key-state (1+ key))))
    (when (get-effect-key-state (1+ key))
      (format t "~&Effect key ~a state is ~a." (1+ key) (get-effect-key-state (1+ key))))))


(defclass effect ()
  ((name :initform "" :initarg :name :accessor name)
   (channel :initform 0 :initarg :channel :accessor channel)))

(defgeneric update-parameters (effect parameters))

(defgeneric process (effect &optional channel key state))



(defclass passthrough (effect)
  ((activep :initform t :initarg :activep :accessor activep)))

(defmethod update-parameters ((e passthrough) parameters)
  "Expected PARAMETERS list: (activep)."
  (when (first parameters)
    (setf (activep e) (first parameters))))

(defmethod process ((e passthrough) &optional channel key state)
  (when (and (activep e)
             channel
             key
             (= channel (channel e)))
    (update-effect-key channel key state)))




(defclass clustercloud (effect)
  ((range :initform 0 :initarg :range :accessor range)))

(defmethod update-parameters ((e clustercloud) parameters)
  "Expected PARAMETERS list: (range)."
  (let ((new-range (first parameters)))
    (when new-range
      (let ((original-range (range e)))
        (dolist (focused-key (get-all-active-keys (channel e)))
          (do ((i original-range))
              ((= i new-range))
            (dolist (fun (list #'+ #'-))
              (update-effect-key (channel e)
                                 (funcall fun focused-key i)
                                 (if (> new-range original-range) t nil)))
            (if (> new-range original-range) (incf i) (decf i)))))
      (setf (range e) new-range)
      ;; (format t "~&Parameter 'range' of effect '~a' (channel ~a) updated to ~a."
      ;;         (name e)
      ;;         (channel e)
      ;;         (range e))
      )))

(defmethod process ((e clustercloud) &optional channel key state)
  (when (and channel key (= channel (channel e)))
    (format t "~&PROCESSING clustercloud note triggered.")
    (loop for counter from (- key (range e)) to (+ key (range e))
          do (update-effect-key (channel e) counter state))))




(defparameter *effect-instances*
  (make-array +number-of-midi-channels+ :initial-element nil))

(defun init-effects ()
  (dotimes (channel +number-of-midi-channels+)
    (push (make-instance 'clustercloud
                         :name "clustercloud"
                         :channel channel
                         :range 0)
          (aref *effect-instances* channel))
    (push (make-instance 'passthrough
                         :name "passthrough"
                         :channel channel
                         :activep t)
          (aref *effect-instances* channel))))

(defun find-effect-by-name (channel name)
  (find name (aref *effect-instances* channel)
        :key #'name
        :test #'string-equal))

(defun update-effect (channel name &rest parameters)
  (update-parameters (find-effect-by-name channel name) parameters))

(defun trigger-effects-processing (triggering-channel triggering-key state)
  (dotimes (channel +number-of-midi-channels+)
    (dolist (effect (aref *effect-instances* channel))
      (process effect triggering-channel triggering-key state))))




(defun init ()
  (init-midi)
  (osc-init)
  (init-effects))
