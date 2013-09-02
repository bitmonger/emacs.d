;;; Packaging via ELPA
(after-load 'package
  ;; Store installed packages alongside this code
  (setq package-user-dir
        (bw/join-dirs dotfiles-dir ".elpa"))

  ;; Only use 3 specific directories
  (setq package-archives
        '(("gnu"       . "http://elpa.gnu.org/packages/")
          ("marmalade" . "http://marmalade-repo.org/packages/")
          ("melpa"     . "http://melpa.milkbox.net/packages/")))

  ;; initialise package.el
  (package-initialize)

  ;; Clean up after ELPA installs:
  ;; https://github.com/purcell/emacs.d/blob/master/init-elpa.el
  (defadvice package-generate-autoloads
    (after close-autoloads (name pkg-dir) activate)
    "Stop package.el from leaving open autoload files lying around."
    (let ((path (expand-file-name (concat name "-autoloads.el") pkg-dir)))
      (with-current-buffer (find-file-existing path)
        (kill-buffer nil))))

  ;; Auto-install the Melpa package, since it's used to filter
  ;; packages.
  (when (not (package-installed-p 'melpa))
    (progn
      (switch-to-buffer
       (url-retrieve-synchronously
        "https://raw.github.com/milkypostman/melpa/master/melpa.el"))
      (package-install-from-buffer (package-buffer-info) 'single))))

;; Blacklist some non-melpa packages
(after-load 'melpa
  (setq package-archive-exclude-alist
         '(("melpa"
            melpa               ;; This will always update due to Melpa versioning
            diminish            ;; not updated in forever
            evil                ;; want stable version
            evil-nerd-commenter ;; want stable version
            flymake-cursor      ;; Melpa version is on wiki
            idomenu             ;; not updated in ages
            json-mode           ;; not on Melpa
            ))))

(require 'package nil t)


;; OSX packages and PATH mangling
(when (eq system-type 'darwin)
  ;;; exec-path-from-shell - Copy shell environment variables to Emacs
  (require-package 'exec-path-from-shell)

  (setq exec-path-from-shell-variables '("PATH"  "MANPATH" "SHELL"))
  (exec-path-from-shell-initialize)

  (when (display-graphic-p)
    ;;; solarized-theme - Emacs version of Solarized
    (require-package 'solarized-theme)
    (setq solarized-high-contrast-mode-line t)
    (load-theme 'solarized-dark t)))


(require 'setup-magit)

;;; ido-ubiquitous - because ido-everywhere isn't enough
(require-package 'ido-ubiquitous)
(ido-ubiquitous-mode 1)

;;; ido-vertical - display ido candidates vertically
(require-package 'ido-vertical-mode)
(ido-vertical-mode 1)
;; only show 5 candidates because it's vertical
(setq ido-max-prospects 5)

;;; smex - IDO completion for M-x
(require-package 'smex)
(global-set-key (kbd "C-x m") 'smex)
(global-set-key (kbd "C-x C-m") 'smex)
(global-set-key (kbd "C-c C-m") 'smex)

;;; ag.el - Emacs frontend to ag search
(require-package 'ag)
;; auto-loaded
(global-set-key (kbd "C-c f") 'ag-project)
(when (eq system-type 'darwin)
  (global-set-key (kbd "s-F") 'ag-project))
;; reuse ag buffers
(setq ag-reuse-buffers t)

;;; magit-find-file - Completing read frontend to git ls-files
(require-package 'magit-find-file)
;; this function is auto-loaded
(global-set-key (kbd "C-c t") 'magit-find-file-completing-read)
(global-set-key (kbd "M-p") 'magit-find-file-completing-read)
(when (eq system-type 'darwin)
  (global-set-key (kbd "s-p") 'magit-find-file-completing-read))


;;; flx-ido - advanced flex matching for ido
(require-package 'flx-ido)
;; use more RAM to cache more candidate lists
(setq gc-cons-threshold 20000000)
(flx-ido-mode 1)


;;; diminish.el - hide minor-mode lighters in modeline
(require-package 'diminish)
(after-load 'eldoc
  (diminish 'eldoc-mode))

(require 'setup-javascript)
(require 'setup-eproject)

;;; paredit - tools for editing sexps

(require-package 'paredit)
;; autoloaded
(add-hook 'emacs-lisp-mode-hook 'enable-paredit-mode)
;; Enable `paredit-mode' in the minibuffer, during `eval-expression'.
(defun conditionally-enable-paredit-mode ()
  (if (eq this-command 'eval-expression)
      (paredit-mode 1)))

(add-hook 'minibuffer-setup-hook 'conditionally-enable-paredit-mode)

;;; idomenu - navigate code in current buffer using ido

(require-package 'idomenu)
;; autoloaded
(global-set-key (kbd "C-c i") 'idomenu)
(setq imenu-auto-rescan t)

(require 'setup-ruby)
(require 'setup-evil)

;;; markdown-mode - for editing markdown
(require-package 'markdown-mode)
(after-load 'markdown-mode
  (setq markdown-imenu-generic-expression
        '(("title"  "^\\(.*\\)[\n]=+$" 1)
          ("h2-"    "^\\(.*\\)[\n]-+$" 1)
          ("h1"   "^# \\(.*\\)$" 1)
          ("h2"   "^## \\(.*\\)$" 1)
          ("h3"   "^### \\(.*\\)$" 1)
          ("h4"   "^#### \\(.*\\)$" 1)
          ("h5"   "^##### \\(.*\\)$" 1)
          ("h6"   "^###### \\(.*\\)$" 1)
          ("fn"   "^\\[\\^\\(.*\\)\\]" 1)))

  (add-hook 'markdown-mode-hook
            (lambda ()
              (setq imenu-generic-expression markdown-imenu-generic-expression))))

(add-to-list 'auto-mode-alist '("\\.md$" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.markdown$" . markdown-mode))

;;; puppet-mode - syntax highlighting for Puppet
(require-package 'puppet-mode)
(add-to-list 'auto-mode-alist '("\\.pp$" . puppet-mode))

;;; undo-tree-mode - visualise undo history
(after-load 'undo-tree-mode
  (diminish 'undo-tree-mode))


;;; multiple-cursors.el - like the Sublime Text 2 thing
;;; https://github.com/magnars/multiple-cursors.el
(require-package 'multiple-cursors)
;; mc/* requires this `require` form as the autoload doesn't cleanly
;; work - the selected regions are always off in the first instance.
(after-load 'multiple-cursors
  (global-set-key (kbd "C-c .") 'mc/mark-next-like-this)
  (global-set-key (kbd "C->") 'mc/mark-next-like-this)
  (global-set-key (kbd "C-c ,") 'mc/mark-previous-like-this)
  (global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
  (global-set-key (kbd "C-c C-l") 'mc/mark-all-like-this))
(require 'multiple-cursors)


;;; expand-region - Increase selected region by semantic units
;;; https://github.com/magnars/expand-region.el
(require-package 'expand-region)
(global-set-key (kbd "C-c =") 'er/expand-region)

(provide 'setup-elpa)
