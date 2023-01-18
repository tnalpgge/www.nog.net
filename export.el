;; Inspired by https://stackoverflow.com/questions/22072773/batch-export-of-org-mode-files-from-the-command-line
;; Donated to https://stackoverflow.com/questions/74704891/ox-hugo-github-actions-debugger-entered-lisp-error-void-function-org-hugo-e/74755446#74755446

(defvar my/package-archives
  (list
   (cons "melpa-stable" "https://stable.melpa.org/packages/")
   (cons "melpa" "https://melpa.org/packages/")
   (cons "gnu" "https://elpa.gnu.org/packages/")))

(defvar my/packages-to-install '(ox-hugo))

(defun my/designate-package-site (site)
  (message "Designating package site %s => %s" (car site) (cdr site))
  (add-to-list 'package-archives site t))

(defun my/designate-package-sites ()
  (message "Designating package sites")
  (mapcar #'my/designate-package-site my/package-archives))

(defun my/install-package (pkg)
  (message "Installing package %s" pkg)
  (ignore-errors (package-install pkg)))

(when (locate-library "package")
  (require 'package)
  (my/designate-package-sites)
  (package-initialize)
  (unless package-archive-contents (package-refresh-contents))
  (mapcar #'my/install-package my/packages-to-install))

;; Inspiration from https://stackoverflow.com/questions/22072773/batch-export-of-org-mode-files-from-the-command-line

(defun my/batch-ox-hugo-file (file)
  (message "Exporting org subtrees to hugo from %s" file)
  (let ((all-subtrees t)
	(any-visibility nil))
    (with-current-buffer (find-file-noselect file)
      (org-hugo-export-wim-to-md all-subtrees any-visibility))))
  
(defun my/batch-ox-hugo-directory (directory)
  (message "Exporting all org subtrees in all files in %s" directory
  (let ((default-directory (expand-file-name directory)))
    (mapcar #'my/batch-ox-hugo-file
	    (file-expand-wildcards "*.org")))))

;; https://stackoverflow.com/questions/25823055/faster-emacs-directory-walker
(defun my/batch-ox-hugo-directory-recursively (directory)
  (message "Looking for org files under %s" directory)
  (let ((files (file-name-all-completions "" (expand-file-name directory))))
    (dolist (thing files)
      (let ((absthing
	     (concat directory
		     (if (string-suffix-p "/" directory) "" "/") thing)))
	(cond
	 ((member thing '("./" "../"))
	  nil)
	 ((string-suffix-p ".org" thing)
	  (my/batch-ox-hugo-file absthing))
	 ((string-suffix-p "/" thing)
	  (my/batch-ox-hugo-directory-recursively absthing))
	 (t nil))))))

(let ((static (concat default-directory "/static")))
  (if (not (file-exists-p static)) (make-directory static)))

(my/batch-ox-hugo-directory-recursively (concat default-directory "org"))
