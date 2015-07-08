;;; Visit (open if necessary) a frame called "MH-E" for mh-rmail,
;;; rescan folder and show current message.  On mh-quit from +inbox
;;; in MH-E frame, delete that frame, and if there's a pid argument
;;; argument, kill the proc with that pid.
;;; markcrim@umich.edu 12/22/95

;; Fri Dec 22 13:58:59 1995  Eric Ding  <ericding@mit.edu>
;;  added using-xemacs variable
;;  added (require 'mh-e)
;;  changed naming from mh-* to frame-mh-e-*
;;  conditionalized the frame-title-format change in frame-mh-e
;;  added confirmation for mh-quit
;;  added explicit defuns for hooks
;;  changed (add-to-list features...) to (provide 'frame-mh-e)

;; Fri Dec 22 15:17:12 1995  Eric Ding  <ericding@mit.edu>
;;  changed string-match/eq to equal where appropriate

;; Jan 2 1995 Mark Crimmins
;;  ask for quit confirmation only if buffer name is "+inbox".
;;  globally bind "control-X m" to frame-mh-e

(require 'mh-e)

(if (string-match "XEmacs\\|Lucid" emacs-version)
    (setq using-xemacs t)
  (setq using-xemacs nil))

(if (not using-xemacs)
    (defun frame-name (&optional FRAME)
      (let ((params (frame-parameters FRAME))
            frame-name)
        (while (consp params)
          (let ((elt (car params)))
            (if (eq (car elt) 'name)
                (setq frame-name (cdr elt))))
          (setq params (cdr params)))
        frame-name)))

(defun frame-mh-e (&optional pid) "Run mh-e in a dedicated frame."
  (interactive)
  (defun get-mh-e-frame ()
    (let (a (l (frame-list)))
      (while l
        (if (equal "MH-E" (frame-name (car l)))
            (setq a (car l)))
        (setq l (cdr l)))
      a))
    (let (f (old-ftf frame-title-format))
      (cond ((setq f (get-mh-e-frame))
             (raise-frame f))
            (t
	     (if using-xemacs
		 (setq frame-title-format "%S"))
	     (setq f (new-frame '((name . "MH-E"))))
	     (if using-xemacs
		 (setq frame-title-format old-ftf))))
      (select-frame f))
    (mh-rmail)
    (mh-rescan-folder)
    (mh-show)
    (setq frame-mh-e-sh-pid pid))

(global-set-key "\C-xm" 'frame-mh-e)

(if (not (fboundp 'frame-mh-e/original-mh-quit))
    (fset 'frame-mh-e/original-mh-quit
          (symbol-function 'mh-quit)))

(defun mh-quit ()
  (interactive)
  (if (equal (buffer-name (current-buffer)) "+inbox")
      (cond ( (y-or-n-p "Quit MH-E? ")
	      (setq frame-mh-e-delete-frame-now t)
	      (frame-mh-e/original-mh-quit)))
    (frame-mh-e/original-mh-quit))
  (message nil))

(defun frame-mh-e-mh-quit-hook ()
  (cond (frame-mh-e-delete-frame-now
	 (delete-frame)
	 (if frame-mh-e-sh-pid
	     (shell-command (concat "kill -9 " frame-mh-e-sh-pid)))
	 (setq frame-mh-e-sh-pid nil)
	 (setq frame-mh-e-delete-frame-now nil))))

(add-hook 'mh-quit-hook 'frame-mh-e-mh-quit-hook)

(defun frame-mh-e-kill-emacs-hook ()
  (if frame-mh-e-sh-pid
      (shell-command (concat "kill -9 " frame-mh-e-sh-pid))))

(add-hook 'kill-emacs-hook 'frame-mh-e-kill-emacs-hook)

(setq frame-mh-e-delete-frame-now nil)
(setq frame-mh-e-sh-pid nil)

(provide 'frame-mh-e)

;;; frame-mh-e.el ends
