
;;;; Common Lisp simulation generated from LLFSM arrangement: FischerConcurrencyAlgorithm

;;; ========================================================================
;;; Constants
;;; ========================================================================


(defconstant +NotAThread+ 0)

(defconstant +GlobalWCET+ 0)


(defconstant +max-steps+ 20)
(defconstant +num-machines+ 3)

;;; ========================================================================
;;; State encoding
;;; ========================================================================

;; States for Starter
(defconstant +Starter-DINIT+ 0)
(defconstant +Starter-INITIAL+ 1)

(defparameter *Starter-state-names*
  (vector "dInitStarter" "INITIAL"))

;; States for Thread1
(defconstant +Thread1-DINIT+ 0)
(defconstant +Thread1-T1NonCriticalSection+ 1)

(defconstant +Thread1-T1WAIT+ 2)

(defconstant +Thread1-T1ASSIGN+ 3)

(defconstant +Thread1-T1CriticalSection+ 4)

(defconstant +Thread1-T1LetGo+ 5)

(defparameter *Thread1-state-names*
  (vector "dInitThread1" "T1NonCriticalSection" "T1WAIT" "T1ASSIGN" "T1CriticalSection" "T1LetGo"))

;; States for Thread2
(defconstant +Thread2-DINIT+ 0)
(defconstant +Thread2-T2NonCriticalSection+ 1)

(defconstant +Thread2-T2WAIT+ 2)

(defconstant +Thread2-T2ASSIGN+ 3)

(defconstant +Thread2-T2CriticalSection+ 4)

(defconstant +Thread2-T2LetGo+ 5)

(defparameter *Thread2-state-names*
  (vector "dInitThread2" "T2NonCriticalSection" "T2WAIT" "T2ASSIGN" "T2CriticalSection" "T2LetGo"))


;;; ========================================================================
;;; Variables
;;; ========================================================================

;; Whiteboard variables

(defparameter *SharedX* 0)





;; Program counter for Starter
(defparameter *pc-Starter* 0)



;; Program counter for Thread1
(defparameter *pc-Thread1* 0)

;; Local variables for Thread1

(defparameter *IamThreadT1* 0)




;; Program counter for Thread2
(defparameter *pc-Thread2* 0)

;; Local variables for Thread2

(defparameter *IamThreadT2* 0)





;;; ========================================================================
;;; OnEntry actions
;;; ========================================================================

(defun on-entry-Starter-INITIAL ()



  (format t "Initialise shared varianle~%")




  (setf *SharedX* +NotAThread+)



)


(defun on-entry-Thread1-T1NonCriticalSection ()



  (format t "In T1 non critical section~%")




  (setf *IamThreadT1* 1)



)

(defun on-entry-Thread1-T1WAIT ()

  nil
)

(defun on-entry-Thread1-T1ASSIGN ()




  (setf *SharedX* *IamThreadT1*)



)

(defun on-entry-Thread1-T1CriticalSection ()



  (format t "In T1 critical section~%")


)

(defun on-entry-Thread1-T1LetGo ()




  (setf *SharedX* +NotAThread+)



)


(defun on-entry-Thread2-T2NonCriticalSection ()



  (format t "In T2 non critical section~%")




  (setf *IamThreadT2* 2)



)

(defun on-entry-Thread2-T2WAIT ()

  nil
)

(defun on-entry-Thread2-T2ASSIGN ()




  (setf *SharedX* *IamThreadT2*)



)

(defun on-entry-Thread2-T2CriticalSection ()



  (format t "In T2 critical section~%")


)

(defun on-entry-Thread2-T2LetGo ()




  (setf *SharedX* +NotAThread+)



)



;;; ========================================================================
;;; Step functions
;;; ========================================================================

(defun step-Starter ()
  (let ((old-pc *pc-Starter*))
    ;; Pseudo-initial transition
    (when (= *pc-Starter* +Starter-DINIT+)
      (setf *pc-Starter* +Starter-INITIAL+)
      (on-entry-Starter-INITIAL)
      (format t "  [Starter] ~A -> ~A~%" (aref *Starter-state-names* old-pc) (aref *Starter-state-names* *pc-Starter*))
      (return-from step-Starter))
    ;; Transitions with priority ordering

    ;; Default: no transition taken
    ))

(defun step-Thread1 ()
  (let ((old-pc *pc-Thread1*))
    ;; Pseudo-initial transition
    (when (= *pc-Thread1* +Thread1-DINIT+)
      (setf *pc-Thread1* +Thread1-T1NonCriticalSection+)
      (on-entry-Thread1-T1NonCriticalSection)
      (format t "  [Thread1] ~A -> ~A~%" (aref *Thread1-state-names* old-pc) (aref *Thread1-state-names* *pc-Thread1*))
      (return-from step-Thread1))
    ;; Transitions with priority ordering

    ;; Transition: T1NonCriticalSection -> T1WAIT
    (when (and (= *pc-Thread1* +Thread1-T1NonCriticalSection+)
               t)
      (setf *pc-Thread1* +Thread1-T1WAIT+)
      (on-entry-Thread1-T1WAIT)
      (format t "  [Thread1] ~A -> ~A~%" (aref *Thread1-state-names* old-pc) (aref *Thread1-state-names* *pc-Thread1*))
      (return-from step-Thread1))

    ;; Transition: T1WAIT -> T1ASSIGN
    (when (and (= *pc-Thread1* +Thread1-T1WAIT+)
               (= +NotAThread+ *SharedX*))
      (setf *pc-Thread1* +Thread1-T1ASSIGN+)
      (on-entry-Thread1-T1ASSIGN)
      (format t "  [Thread1] ~A -> ~A~%" (aref *Thread1-state-names* old-pc) (aref *Thread1-state-names* *pc-Thread1*))
      (return-from step-Thread1))

    ;; Transition: T1ASSIGN -> T1WAIT
    (when (and (= *pc-Thread1* +Thread1-T1ASSIGN+)
               (not (= *IamThreadT1* *SharedX*)))
      (setf *pc-Thread1* +Thread1-T1WAIT+)
      (on-entry-Thread1-T1WAIT)
      (format t "  [Thread1] ~A -> ~A~%" (aref *Thread1-state-names* old-pc) (aref *Thread1-state-names* *pc-Thread1*))
      (return-from step-Thread1))

    ;; Transition: T1ASSIGN -> T1CriticalSection
    (when (and (= *pc-Thread1* +Thread1-T1ASSIGN+)
               t)
      (setf *pc-Thread1* +Thread1-T1CriticalSection+)
      (on-entry-Thread1-T1CriticalSection)
      (format t "  [Thread1] ~A -> ~A~%" (aref *Thread1-state-names* old-pc) (aref *Thread1-state-names* *pc-Thread1*))
      (return-from step-Thread1))

    ;; Transition: T1CriticalSection -> T1LetGo
    (when (and (= *pc-Thread1* +Thread1-T1CriticalSection+)
               t)
      (setf *pc-Thread1* +Thread1-T1LetGo+)
      (on-entry-Thread1-T1LetGo)
      (format t "  [Thread1] ~A -> ~A~%" (aref *Thread1-state-names* old-pc) (aref *Thread1-state-names* *pc-Thread1*))
      (return-from step-Thread1))

    ;; Transition: T1LetGo -> T1NonCriticalSection
    (when (and (= *pc-Thread1* +Thread1-T1LetGo+)
               t)
      (setf *pc-Thread1* +Thread1-T1NonCriticalSection+)
      (on-entry-Thread1-T1NonCriticalSection)
      (format t "  [Thread1] ~A -> ~A~%" (aref *Thread1-state-names* old-pc) (aref *Thread1-state-names* *pc-Thread1*))
      (return-from step-Thread1))

    ;; Default: no transition taken
    ))

(defun step-Thread2 ()
  (let ((old-pc *pc-Thread2*))
    ;; Pseudo-initial transition
    (when (= *pc-Thread2* +Thread2-DINIT+)
      (setf *pc-Thread2* +Thread2-T2NonCriticalSection+)
      (on-entry-Thread2-T2NonCriticalSection)
      (format t "  [Thread2] ~A -> ~A~%" (aref *Thread2-state-names* old-pc) (aref *Thread2-state-names* *pc-Thread2*))
      (return-from step-Thread2))
    ;; Transitions with priority ordering

    ;; Transition: T2NonCriticalSection -> T2WAIT
    (when (and (= *pc-Thread2* +Thread2-T2NonCriticalSection+)
               t)
      (setf *pc-Thread2* +Thread2-T2WAIT+)
      (on-entry-Thread2-T2WAIT)
      (format t "  [Thread2] ~A -> ~A~%" (aref *Thread2-state-names* old-pc) (aref *Thread2-state-names* *pc-Thread2*))
      (return-from step-Thread2))

    ;; Transition: T2WAIT -> T2ASSIGN
    (when (and (= *pc-Thread2* +Thread2-T2WAIT+)
               (= +NotAThread+ *SharedX*))
      (setf *pc-Thread2* +Thread2-T2ASSIGN+)
      (on-entry-Thread2-T2ASSIGN)
      (format t "  [Thread2] ~A -> ~A~%" (aref *Thread2-state-names* old-pc) (aref *Thread2-state-names* *pc-Thread2*))
      (return-from step-Thread2))

    ;; Transition: T2ASSIGN -> T2WAIT
    (when (and (= *pc-Thread2* +Thread2-T2ASSIGN+)
               (not (= *IamThreadT2* *SharedX*)))
      (setf *pc-Thread2* +Thread2-T2WAIT+)
      (on-entry-Thread2-T2WAIT)
      (format t "  [Thread2] ~A -> ~A~%" (aref *Thread2-state-names* old-pc) (aref *Thread2-state-names* *pc-Thread2*))
      (return-from step-Thread2))

    ;; Transition: T2ASSIGN -> T2CriticalSection
    (when (and (= *pc-Thread2* +Thread2-T2ASSIGN+)
               t)
      (setf *pc-Thread2* +Thread2-T2CriticalSection+)
      (on-entry-Thread2-T2CriticalSection)
      (format t "  [Thread2] ~A -> ~A~%" (aref *Thread2-state-names* old-pc) (aref *Thread2-state-names* *pc-Thread2*))
      (return-from step-Thread2))

    ;; Transition: T2CriticalSection -> T2LetGo
    (when (and (= *pc-Thread2* +Thread2-T2CriticalSection+)
               t)
      (setf *pc-Thread2* +Thread2-T2LetGo+)
      (on-entry-Thread2-T2LetGo)
      (format t "  [Thread2] ~A -> ~A~%" (aref *Thread2-state-names* old-pc) (aref *Thread2-state-names* *pc-Thread2*))
      (return-from step-Thread2))

    ;; Transition: T2LetGo -> T2NonCriticalSection
    (when (and (= *pc-Thread2* +Thread2-T2LetGo+)
               t)
      (setf *pc-Thread2* +Thread2-T2NonCriticalSection+)
      (on-entry-Thread2-T2NonCriticalSection)
      (format t "  [Thread2] ~A -> ~A~%" (aref *Thread2-state-names* old-pc) (aref *Thread2-state-names* *pc-Thread2*))
      (return-from step-Thread2))

    ;; Default: no transition taken
    ))


;;; ========================================================================
;;; Main: round-robin scheduler
;;; ========================================================================
(defun run-scheduler ()
  (let ((turn 0))
    (format t "LLFSM Arrangement: FischerConcurrencyAlgorithm~%")
    (format t "Running ~D scheduler steps~%~%" +max-steps+)
    (dotimes (i +max-steps+)
      (format t "Step ~D (turn=~D):~%" i turn)
      (case turn


        (0 (step-Starter))



        (1 (step-Thread1))



        (2 (step-Thread2))


        )
      (setf turn (mod (1+ turn) +num-machines+)))
    (format t "~%Simulation complete.~%")))

(run-scheduler)
