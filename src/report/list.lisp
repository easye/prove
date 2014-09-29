(in-package :cl-user)
(defpackage cl-test-more.report.list
  (:use :cl)
  (:import-from :cl-test-more.report
                :format-report
                :report
                :test-report
                :passed-test-report
                :failed-test-report
                :normal-test-report
                :composed-test-report
                :format/indent
                :got
                :got-form
                :notp
                :report-expected-label
                :expected
                :description
                :failed-report-p
                :skipped-report-p
                :test-report-p
                :print-plan-report
                :print-finalize-report)
  (:import-from :cl-test-more.color
                :with-color-if-available))
(in-package :cl-test-more.report.list)

(defmethod format-report (stream (report report) (style (eql :list)) &rest args)
  (declare (ignore args))
  (format/indent stream "~&# ~A~2%"
                 (slot-value report 'description)))

(defun possible-report-description (report)
  (cond
    ((slot-value report 'description)
     (format nil "~A" (slot-value report 'description)))
    ((and (typep report 'normal-test-report)
          (slot-value report 'got-form))
     (with-slots (got got-form notp report-expected-label expected) report
       (format nil "~S is ~:[~;not ~]expected to ~:[be~;~:*~A~] ~S~:[ (got ~S)~;~*~]"
               got-form
               notp
               report-expected-label
               expected
               (eq got got-form)
               got)))))

(defmethod format-report (stream (report normal-test-report) (style (eql :list)) &rest args)
  (declare (ignore args))
  (format/indent stream "~&  ")
  (with-color-if-available (cl-colors:+green+ :stream stream)
    (format stream "✓"))
  (format stream " ")
  (let ((description (possible-report-description report)))
    (when description
      (with-color-if-available (cl-colors:+gray+ :stream stream)
        (write-string description stream))))
  (terpri stream))

(defmethod format-report (stream (report failed-test-report) (style (eql :list)) &rest args)
  (declare (ignore args))
  (format/indent stream "~&  ")
  (with-color-if-available (cl-colors:+red+ :stream stream)
    (format stream "×")
    (format stream " ")
    (let ((description (possible-report-description report)))
      (when description
        (write-string description stream))))
  (terpri stream))

(defmethod format-report (stream (report composed-test-report) (style (eql :list)) &rest args)
  (declare (ignore args))
  (format/indent stream "~&  ")
  (if (failed-report-p report)
      (with-color-if-available (cl-colors:+red+ :stream stream)
        (format stream "×")
        (format stream " ~:[(no description)~;~:*~A~]" (slot-value report 'description)))
      (progn
        (with-color-if-available (cl-colors:+green+ :stream stream)
          (format stream "✓"))
        (format stream " ~:[(no description)~;~:*~A~]" (slot-value report 'description))))
  (terpri stream))

(defmethod print-plan-report (stream num (style (eql :list)))
  (when num
    (format-report stream
                   (make-instance 'report
                                  :description (format nil "1..~A" num))
                   :list)))

(defmethod print-finalize-report (stream plan reports (style (eql :list)))
  (let ((failed-count (count-if #'failed-report-p reports))
        (skipped-count (count-if #'skipped-report-p reports))
        (count (count-if #'test-report-p reports)))
    (format/indent stream "~2&")
    (cond
      ((eq plan :unspecified)
       (with-color-if-available (cl-colors:+yellow+ :stream stream)
         (format/indent stream
                        "△ Tests were run but no plan was declared.~%")))
      ((and plan
            (not (= count plan)))
       (with-color-if-available (cl-colors:+yellow+ :stream stream)
         (format/indent stream
                        "△ Looks like you planned ~D test~:*~P but ran ~A.~%"
                        plan count))))
    (if (< 0 failed-count)
        (with-color-if-available (cl-colors:+red+ :stream stream)
          (format/indent stream
                         "× ~D of ~D test~:*~P failed"
                         failed-count count))
        (with-color-if-available (cl-colors:+green+ :stream stream)
          (format/indent stream
                         "✓ ~D test~:*~P completed" count)))
    (terpri stream)
    (unless (zerop skipped-count)
      (with-color-if-available (cl-colors:+cyan+ :stream stream)
        (format/indent stream "● ~D test~:*~P skipped" skipped-count))
      (terpri stream))))