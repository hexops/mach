;; Tests the behavior of `libmach` using Common Lisp's CFFI
;; This Lisp script is basically a one-to-one translation of `test.c`

(ql:quickload :cffi)

(defpackage :cffi-user
  (:use :cl :cffi))

(in-package :cffi-user)

(define-foreign-library libmach
  (t (:default "./build/libmach")))
   
(use-foreign-library libmach)

;; Note: CFFI automatically translates C_style names into lispier kebab-case ones

(defcfun "mach_core_init" :pointer)

(defcfun "mach_core_update" :int
  (core :pointer) (resize-fn :pointer))

(defcfun "mach_core_deinit" :void
  (core :pointer))

;; void mach_set_should_close(void*);
(defcfun "mach_core_set_should_close" :void
  (core :pointer))

;; float mach_delta_time(void*);
(defcfun "mach_core_delta_time" :float
  (core :pointer))

;; bool mach_window_should_close(void*);
(defcfun "mach_core_window_should_close" :bool
  (core :pointer))

;; main
(defvar *elapsed* 0.0)

(defcallback resize-fn :void ((core :pointer) (width :unsigned-int) (height :unsigned-int))
  (format t "Resize Callback: ~S ~S~%" width height))

(setf core (mach-core-init))

(when (pointer-eq core (null-pointer))
  (format t "Failed to initialize mach core~%")
  (sb-ext:exit))

(loop while (not (mach-core-window-should-close core))
      do (progn
           (when (= 0 (mach-core-update core (callback resize-fn)))
             (format t "Error updating mach~%")
             (sb-ext:exit))
           (when (> (incf *elapsed* (mach-core-delta-time core)) 5.0)
             (mach-core-set-should-close core))))

(sb-ext:exit)
