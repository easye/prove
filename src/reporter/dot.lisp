(in-package :cl-user)
(defpackage prove.reporter.dot
  (:use :cl
        :prove.report
        :prove.reporter
        :prove.reporter.list
        :prove.color))
(in-package :prove.reporter.dot)

(defclass dot-reporter (list-reporter) ())

(defmethod format-report (stream (reporter dot-reporter) (report comment-report) &rest args)
  (declare (ignore args))
  ;; Do nothing. This reporter doesn't support 'diag'.
  )

(defmethod format-report (stream (reporter dot-reporter) (report test-report) &rest args)
  (declare (ignore args))
  (when (zerop *indent-level*)
    (if *enable-colors*
        (with-color ((cond
                       ((failed-report-p report) :red)
                       ((skipped-report-p report) :cyan)
                       (T :gray)) :stream stream)
          (format stream "."))
        (write-char (if (failed-report-p report) #\f #\.) stream))))

(defmethod print-finalize-report :before ((reporter dot-reporter) plan reports stream)
  (declare (ignore plan reports))
  (fresh-line stream))