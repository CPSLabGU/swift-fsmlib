
;;;; Common Lisp simulation generated from LLFSM arrangement: PingPongTikiTakaForC

;;; ========================================================================
;;; Constants
;;; ========================================================================

(defconstant +max-steps+ 20)
(defconstant +num-machines+ 1)

;;; ========================================================================
;;; State encoding
;;; ========================================================================

;; States for PingPong
(defconstant +PingPong-DINIT+ 0)
(defconstant +PingPong-START_PING_PONG+ 1)

(defconstant +PingPong-PING+ 2)

(defconstant +PingPong-PONG+ 3)

(defparameter *PingPong-state-names*
  (vector "dInitPingPong" "START_PING_PONG" "PING" "PONG"))


;;; ========================================================================
;;; Variables
;;; ========================================================================




;; Program counter for PingPong
(defparameter *pc-PingPong* 0)




;;; ========================================================================
;;; OnEntry actions
;;; ========================================================================

(defun on-entry-PingPong-START_PING_PONG ()



  (format t "Start Ping Pong~%")


)

(defun on-entry-PingPong-PING ()



  (format t "ping~%")


)

(defun on-entry-PingPong-PONG ()



  (format t "pong~%")


)



;;; ========================================================================
;;; Step functions
;;; ========================================================================

(defun step-PingPong ()
  (let ((old-pc *pc-PingPong*))
    ;; Pseudo-initial transition
    (when (= *pc-PingPong* +PingPong-DINIT+)
      (setf *pc-PingPong* +PingPong-START_PING_PONG+)
      (on-entry-PingPong-START_PING_PONG)
      (format t "  [PingPong] ~A -> ~A~%" (aref *PingPong-state-names* old-pc) (aref *PingPong-state-names* *pc-PingPong*))
      (return-from step-PingPong))
    ;; Transitions with priority ordering

    ;; Transition: START_PING_PONG -> PING
    (when (and (= *pc-PingPong* +PingPong-START_PING_PONG+)
               t)
      (setf *pc-PingPong* +PingPong-PING+)
      (on-entry-PingPong-PING)
      (format t "  [PingPong] ~A -> ~A~%" (aref *PingPong-state-names* old-pc) (aref *PingPong-state-names* *pc-PingPong*))
      (return-from step-PingPong))

    ;; Transition: PING -> PONG
    (when (and (= *pc-PingPong* +PingPong-PING+)
               t)
      (setf *pc-PingPong* +PingPong-PONG+)
      (on-entry-PingPong-PONG)
      (format t "  [PingPong] ~A -> ~A~%" (aref *PingPong-state-names* old-pc) (aref *PingPong-state-names* *pc-PingPong*))
      (return-from step-PingPong))

    ;; Transition: PONG -> PING
    (when (and (= *pc-PingPong* +PingPong-PONG+)
               t)
      (setf *pc-PingPong* +PingPong-PING+)
      (on-entry-PingPong-PING)
      (format t "  [PingPong] ~A -> ~A~%" (aref *PingPong-state-names* old-pc) (aref *PingPong-state-names* *pc-PingPong*))
      (return-from step-PingPong))

    ;; Default: no transition taken
    ))


;;; ========================================================================
;;; Main: round-robin scheduler
;;; ========================================================================
(defun run-scheduler ()
  (let ((turn 0))
    (format t "LLFSM Arrangement: PingPongTikiTakaForC~%")
    (format t "Running ~D scheduler steps~%~%" +max-steps+)
    (dotimes (i +max-steps+)
      (format t "Step ~D (turn=~D):~%" i turn)
      (case turn


        (0 (step-PingPong))


        )
      (setf turn (mod (1+ turn) +num-machines+)))
    (format t "~%Simulation complete.~%")))

(run-scheduler)
