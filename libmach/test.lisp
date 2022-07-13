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

;; typedef void mach_core_callback(void*);
(defctype mach-core-callback :pointer)

;; void mach_core_set_init(mach_core_callback);
(defcfun "mach_core_set_init" :void
  (callback mach-core-callback))

;; void mach_core_set_update(mach_core_callback);
(defcfun "mach_core_set_update" :void
  (callback mach-core-callback))

;; void mach_core_set_deinit(mach_core_callback);
(defcfun "mach_core_set_deinit" :void
  (callback mach-core-callback))

;; void mach_run(void);
(defcfun "mach_run" :void)

;; void core_set_should_close(void*);
(defcfun "core_set_should_close" :void (core :pointer))

;; float core_delta_time(void*);
(defcfun "core_delta_time" :float (core :pointer))

(defcallback my-init :void ((core :pointer))
  (format t "Hello from my-init!~%"))

(defvar *elapsed* 0.0)

(defcallback my-update :void ((core :pointer))
  (format t "Hello from my-update ~a~%" *elapsed*)
  (if (< *elapsed* 1.0)
      (incf *elapsed* (core-delta-time core))
      (core-set-should-close core)))

(defcallback my-deinit :void ((core :pointer))
  (format t "Hello from my-deinit!~%"))

(mach-core-set-init (callback my-init))

(mach-core-set-update (callback my-update))

(mach-core-set-deinit (callback my-deinit))

(mach-run)

(sb-ext:exit)
