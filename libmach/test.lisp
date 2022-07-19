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

;; void* mach_init(void);
(defcfun "mach_init_core" :pointer)
;; for some reason, calling "mach_init" always returns a null pointer, and I have no clue why...
;; So I renamed the API function name to "mach_init_core" instead

;; int mach_update(void*, resize_callback);
(defcfun "mach_update" :int
  (core :pointer) (resize-fn :pointer))

;; void mach_deinit(void*);
(defcfun "mach_deinit" :void
  (core :pointer))

;; void mach_set_should_close(void*);
(defcfun "mach_set_should_close" :void
  (core :pointer))

;; float mach_delta_time(void*);
(defcfun "mach_delta_time" :float
  (core :pointer))

;; bool mach_window_should_close(void*);
(defcfun "mach_window_should_close" :bool
  (core :pointer))

;; main
(defvar *elapsed* 0.0)

(defcallback resize-fn :void ((core :pointer) (width :unsigned-int) (height :unsigned-int))
  (format t "Resize Callback: ~S ~S~%" width height))

(setf core (mach-init-core))

(format t "Core: ~S~%" core)

(when (pointer-eq core (null-pointer))
  (format t "Failed to initialize mach core~%")
  (sb-ext:exit))

(loop while (not (mach-window-should-close core))
      do (progn
           (when (= 0 (mach-update core (callback resize-fn)))
             (format t "Error updating mach~%")
             (sb-ext:exit))
           (when (> (incf *elapsed* (mach-delta-time core)) 5.0)
             (mach-set-should-close core))))

(sb-ext:exit)
