(in-package :cl-user)
(defpackage cl-test-more.report.list
  (:use :cl
        :cl-test-more.report)
  (:import-from :cl-test-more.color
                :with-color))
(in-package :cl-test-more.report.list)

(defmethod format-report (stream (report report) (style (eql :list)) &rest args)
  (declare (ignore args))
  (format/indent stream "~&# ~A~2%"
                 (slot-value report 'description)))

(defun possible-report-description (report)
  (cond
    ((slot-value report 'description)
     (format nil "~A~:[~; (Skipped)~]"
             (slot-value report 'description)
             (skipped-report-p report)))
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
  (with-color ((if (skipped-report-p report)
                   :cyan
                   :green) :stream stream)
    (format stream "✓"))
  (format stream " ")
  (let ((description (possible-report-description report)))
    (when description
      (with-color (:gray :stream stream)
        (write-string description stream))))
  (terpri stream))

(defmethod format-report (stream (report failed-test-report) (style (eql :list)) &rest args)
  (declare (ignore args))
  (format/indent stream "~&  ")
  (with-color (:red :stream stream)
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
      (with-color (:red :stream stream)
        (format stream "×")
        (format stream " ~:[(no description)~;~:*~A~]" (slot-value report 'description)))
      (progn
        (with-color ((if (skipped-report-p report)
                         :cyan
                         :green) :stream stream)
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
       (with-color (:yellow :stream stream)
         (format/indent stream
                        "△ Tests were run but no plan was declared.~%")))
      ((and plan
            (not (= count plan)))
       (with-color (:yellow :stream stream)
         (format/indent stream
                        "△ Looks like you planned ~D test~:*~P but ran ~A.~%"
                        plan count))))
    (if (< 0 failed-count)
        (with-color (:red :stream stream)
          (format/indent stream
                         "× ~D of ~D test~:*~P failed"
                         failed-count count))
        (with-color (:green :stream stream)
          (format/indent stream
                         "✓ ~D test~:*~P completed" count)))
    (terpri stream)
    (unless (zerop skipped-count)
      (with-color (:cyan :stream stream)
        (format/indent stream "● ~D test~:*~P skipped" skipped-count))
      (terpri stream))))
