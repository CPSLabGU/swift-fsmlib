
;;;; Common Lisp simulation generated from LLFSM arrangement: FischerDelaysByBooleanSensors

;;; ========================================================================
;;; Constants
;;; ========================================================================


(defconstant +NotAThread+ 0)


(defconstant +max-steps+ 20)
(defconstant +num-machines+ 3)

;;; ========================================================================
;;; State encoding
;;; ========================================================================

;; States for STARTER
(defconstant +STARTER-DINIT+ 0)
(defconstant +STARTER-START+ 1)

(defparameter *STARTER-state-names*
  (vector "dInitSTARTER" "START"))

;; States for THREAD_1
(defconstant +THREAD_1-DINIT+ 0)
(defconstant +THREAD_1-T1NonCriticalSection+ 1)

(defconstant +THREAD_1-T1Wait+ 2)

(defconstant +THREAD_1-T1Assign+ 3)

(defconstant +THREAD_1-T1CriticalSection+ 4)

(defconstant +THREAD_1-T1LetGo+ 5)

(defparameter *THREAD_1-state-names*
  (vector "dInitTHREAD_1" "T1NonCriticalSection" "T1Wait" "T1Assign" "T1CriticalSection" "T1LetGo"))

;; States for THREAD_2
(defconstant +THREAD_2-DINIT+ 0)
(defconstant +THREAD_2-T2NonCriticalSection+ 1)

(defconstant +THREAD_2-T2Wait+ 2)

(defconstant +THREAD_2-T2Assign+ 3)

(defconstant +THREAD_2-T2CriticalSection+ 4)

(defconstant +THREAD_2-T2LetGo+ 5)

(defparameter *THREAD_2-state-names*
  (vector "dInitTHREAD_2" "T2NonCriticalSection" "T2Wait" "T2Assign" "T2CriticalSection" "T2LetGo"))


;;; ========================================================================
;;; Variables
;;; ========================================================================

;; Whiteboard variables

(defparameter *SharedX* 0)



;; Boolean sensor variables

(defparameter *T1NonCriticalSectionDelay* nil)

(defparameter *T1CriticalSectionDelay* nil)

(defparameter *T2NonCriticalSectionDelay* nil)

(defparameter *T2CriticalSectionDelay* nil)




;; Program counter for STARTER
(defparameter *pc-STARTER* 0)



;; Program counter for THREAD_1
(defparameter *pc-THREAD_1* 0)

;; Local variables for THREAD_1

(defparameter *IamThreadT1* 0)




;; Program counter for THREAD_2
(defparameter *pc-THREAD_2* 0)

;; Local variables for THREAD_2

(defparameter *IamThreadT2* 0)





;;; ========================================================================
;;; OnEntry actions
;;; ========================================================================

(defun on-entry-STARTER-START ()



  (format t "Initialise shared variable~%")




  (setf *SharedX* +NotAThread+)



)


(defun on-entry-THREAD_1-T1NonCriticalSection ()



  (format t "T1 in non-critical section~%")




  (setf *IamThreadT1* 1)



)

(defun on-entry-THREAD_1-T1Wait ()

  nil
)

(defun on-entry-THREAD_1-T1Assign ()




  (setf *SharedX* *IamThreadT1*)



)

(defun on-entry-THREAD_1-T1CriticalSection ()

  nil
)

(defun on-entry-THREAD_1-T1LetGo ()




  (setf *SharedX* +NotAThread+)



)


(defun on-entry-THREAD_2-T2NonCriticalSection ()



  (format t "T2 in non-critical section~%")




  (setf *IamThreadT2* 2)



)

(defun on-entry-THREAD_2-T2Wait ()

  nil
)

(defun on-entry-THREAD_2-T2Assign ()




  (setf *SharedX* *IamThreadT2*)



)

(defun on-entry-THREAD_2-T2CriticalSection ()

  nil
)

(defun on-entry-THREAD_2-T2LetGo ()




  (setf *SharedX* +NotAThread+)



)



;;; ========================================================================
;;; Step functions
;;; ========================================================================

(defun step-STARTER ()
  (let ((old-pc *pc-STARTER*))
    ;; Pseudo-initial transition
    (when (= *pc-STARTER* +STARTER-DINIT+)
      (setf *pc-STARTER* +STARTER-START+)
      (on-entry-STARTER-START)
      (format t "  [STARTER] ~A -> ~A~%" (aref *STARTER-state-names* old-pc) (aref *STARTER-state-names* *pc-STARTER*))
      (return-from step-STARTER))
    ;; Transitions with priority ordering

    ;; Default: no transition taken
    ))

(defun step-THREAD_1 ()
  (let ((old-pc *pc-THREAD_1*))
    ;; Pseudo-initial transition
    (when (= *pc-THREAD_1* +THREAD_1-DINIT+)
      (setf *pc-THREAD_1* +THREAD_1-T1NonCriticalSection+)
      (on-entry-THREAD_1-T1NonCriticalSection)
      (format t "  [THREAD_1] ~A -> ~A~%" (aref *THREAD_1-state-names* old-pc) (aref *THREAD_1-state-names* *pc-THREAD_1*))
      (return-from step-THREAD_1))
    ;; Transitions with priority ordering

    ;; Transition: T1NonCriticalSection -> T1Wait
    (when (and (= *pc-THREAD_1* +THREAD_1-T1NonCriticalSection+)
               *T1NonCriticalSectionDelay*)
      (setf *pc-THREAD_1* +THREAD_1-T1Wait+)
      (on-entry-THREAD_1-T1Wait)
      (format t "  [THREAD_1] ~A -> ~A~%" (aref *THREAD_1-state-names* old-pc) (aref *THREAD_1-state-names* *pc-THREAD_1*))
      (return-from step-THREAD_1))

    ;; Transition: T1Wait -> T1Assign
    (when (and (= *pc-THREAD_1* +THREAD_1-T1Wait+)
               (= +NotAThread+ *SharedX*))
      (setf *pc-THREAD_1* +THREAD_1-T1Assign+)
      (on-entry-THREAD_1-T1Assign)
      (format t "  [THREAD_1] ~A -> ~A~%" (aref *THREAD_1-state-names* old-pc) (aref *THREAD_1-state-names* *pc-THREAD_1*))
      (return-from step-THREAD_1))

    ;; Transition: T1Assign -> T1Wait
    (when (and (= *pc-THREAD_1* +THREAD_1-T1Assign+)
               (not (= *IamThreadT1* *SharedX*)))
      (setf *pc-THREAD_1* +THREAD_1-T1Wait+)
      (on-entry-THREAD_1-T1Wait)
      (format t "  [THREAD_1] ~A -> ~A~%" (aref *THREAD_1-state-names* old-pc) (aref *THREAD_1-state-names* *pc-THREAD_1*))
      (return-from step-THREAD_1))

    ;; Transition: T1Assign -> T1CriticalSection
    (when (and (= *pc-THREAD_1* +THREAD_1-T1Assign+)
               t)
      (setf *pc-THREAD_1* +THREAD_1-T1CriticalSection+)
      (on-entry-THREAD_1-T1CriticalSection)
      (format t "  [THREAD_1] ~A -> ~A~%" (aref *THREAD_1-state-names* old-pc) (aref *THREAD_1-state-names* *pc-THREAD_1*))
      (return-from step-THREAD_1))

    ;; Transition: T1CriticalSection -> T1LetGo
    (when (and (= *pc-THREAD_1* +THREAD_1-T1CriticalSection+)
               *T1CriticalSectionDelay*)
      (setf *pc-THREAD_1* +THREAD_1-T1LetGo+)
      (on-entry-THREAD_1-T1LetGo)
      (format t "  [THREAD_1] ~A -> ~A~%" (aref *THREAD_1-state-names* old-pc) (aref *THREAD_1-state-names* *pc-THREAD_1*))
      (return-from step-THREAD_1))

    ;; Transition: T1LetGo -> T1NonCriticalSection
    (when (and (= *pc-THREAD_1* +THREAD_1-T1LetGo+)
               t)
      (setf *pc-THREAD_1* +THREAD_1-T1NonCriticalSection+)
      (on-entry-THREAD_1-T1NonCriticalSection)
      (format t "  [THREAD_1] ~A -> ~A~%" (aref *THREAD_1-state-names* old-pc) (aref *THREAD_1-state-names* *pc-THREAD_1*))
      (return-from step-THREAD_1))

    ;; Default: no transition taken
    ))

(defun step-THREAD_2 ()
  (let ((old-pc *pc-THREAD_2*))
    ;; Pseudo-initial transition
    (when (= *pc-THREAD_2* +THREAD_2-DINIT+)
      (setf *pc-THREAD_2* +THREAD_2-T2NonCriticalSection+)
      (on-entry-THREAD_2-T2NonCriticalSection)
      (format t "  [THREAD_2] ~A -> ~A~%" (aref *THREAD_2-state-names* old-pc) (aref *THREAD_2-state-names* *pc-THREAD_2*))
      (return-from step-THREAD_2))
    ;; Transitions with priority ordering

    ;; Transition: T2NonCriticalSection -> T2Wait
    (when (and (= *pc-THREAD_2* +THREAD_2-T2NonCriticalSection+)
               *T2NonCriticalSectionDelay*)
      (setf *pc-THREAD_2* +THREAD_2-T2Wait+)
      (on-entry-THREAD_2-T2Wait)
      (format t "  [THREAD_2] ~A -> ~A~%" (aref *THREAD_2-state-names* old-pc) (aref *THREAD_2-state-names* *pc-THREAD_2*))
      (return-from step-THREAD_2))

    ;; Transition: T2Wait -> T2Assign
    (when (and (= *pc-THREAD_2* +THREAD_2-T2Wait+)
               (= +NotAThread+ *SharedX*))
      (setf *pc-THREAD_2* +THREAD_2-T2Assign+)
      (on-entry-THREAD_2-T2Assign)
      (format t "  [THREAD_2] ~A -> ~A~%" (aref *THREAD_2-state-names* old-pc) (aref *THREAD_2-state-names* *pc-THREAD_2*))
      (return-from step-THREAD_2))

    ;; Transition: T2Assign -> T2Wait
    (when (and (= *pc-THREAD_2* +THREAD_2-T2Assign+)
               (not (= *IamThreadT2* *SharedX*)))
      (setf *pc-THREAD_2* +THREAD_2-T2Wait+)
      (on-entry-THREAD_2-T2Wait)
      (format t "  [THREAD_2] ~A -> ~A~%" (aref *THREAD_2-state-names* old-pc) (aref *THREAD_2-state-names* *pc-THREAD_2*))
      (return-from step-THREAD_2))

    ;; Transition: T2Assign -> T2CriticalSection
    (when (and (= *pc-THREAD_2* +THREAD_2-T2Assign+)
               t)
      (setf *pc-THREAD_2* +THREAD_2-T2CriticalSection+)
      (on-entry-THREAD_2-T2CriticalSection)
      (format t "  [THREAD_2] ~A -> ~A~%" (aref *THREAD_2-state-names* old-pc) (aref *THREAD_2-state-names* *pc-THREAD_2*))
      (return-from step-THREAD_2))

    ;; Transition: T2CriticalSection -> T2LetGo
    (when (and (= *pc-THREAD_2* +THREAD_2-T2CriticalSection+)
               *T2CriticalSectionDelay*)
      (setf *pc-THREAD_2* +THREAD_2-T2LetGo+)
      (on-entry-THREAD_2-T2LetGo)
      (format t "  [THREAD_2] ~A -> ~A~%" (aref *THREAD_2-state-names* old-pc) (aref *THREAD_2-state-names* *pc-THREAD_2*))
      (return-from step-THREAD_2))

    ;; Transition: T2LetGo -> T2NonCriticalSection
    (when (and (= *pc-THREAD_2* +THREAD_2-T2LetGo+)
               t)
      (setf *pc-THREAD_2* +THREAD_2-T2NonCriticalSection+)
      (on-entry-THREAD_2-T2NonCriticalSection)
      (format t "  [THREAD_2] ~A -> ~A~%" (aref *THREAD_2-state-names* old-pc) (aref *THREAD_2-state-names* *pc-THREAD_2*))
      (return-from step-THREAD_2))

    ;; Default: no transition taken
    ))


;;; ========================================================================
;;; Main: round-robin scheduler
;;; ========================================================================
(defun run-scheduler ()
  (let ((turn 0))
    (format t "LLFSM Arrangement: FischerDelaysByBooleanSensors~%")
    (format t "Running ~D scheduler steps~%~%" +max-steps+)
    (dotimes (i +max-steps+)
      (format t "Step ~D (turn=~D):~%" i turn)
      (case turn


        (0 (step-STARTER))



        (1 (step-THREAD_1))



        (2 (step-THREAD_2))


        )
      (setf turn (mod (1+ turn) +num-machines+)))
    (format t "~%Simulation complete.~%")))

(run-scheduler)
