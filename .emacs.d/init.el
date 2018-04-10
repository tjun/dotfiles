(set-language-environment 'Japanese)
(prefer-coding-system 'utf-8)

; -*- Mode: Emacs-Lisp ; Coding: utf-8 -*-
;; ------------------------------------------------------------------------
;; @ load-path
(defun add-to-load-path (&rest paths)
  (let (path)
    (dolist (path paths paths)
      (let ((default-directory (expand-file-name (concat user-emacs-directory path))))
        (add-to-list 'load-path default-directory)
        (if (fboundp 'normal-top-level-add-subdirs-to-load-path)
            (normal-top-level-add-subdirs-to-load-path))))))

;; directories add to  load-path
;; (add-to-load-path "elisp" "xxx" "xxx")
(add-to-load-path "elisp" "elpa")

;;
;; package.el
;;_______________________________________________________________________
(require 'package)
(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/") t)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))
(package-initialize)

;; line number format
(setq linum-format "%d ")

;; skip startup message
(setq inhibit-startup-message t)

;; hide initial scratch message
(setq initial-scratch-message "")

;; use "y or n" instead of "yes or no"
(fset 'yes-or-no-p 'y-or-n-p)

;; add file path to menu bar
(setq frame-title-format
      (format "%%f - Emacs@%s" (system-name)))

;; coloring
;;; font coloring
(global-font-lock-mode t)

(load-theme 'manoj-dark t)

(add-to-list 'default-frame-alist '(background-color . "#222222"))
;(set-background-color                                   "snow")       ; background
(set-face-background 'mode-line                         "orange")    ; background of mode line
(set-face-foreground 'mode-line                         "black")    ; background of mode line
(set-face-background 'mode-line-buffer-id               "orange")    ; background of mode line
(set-face-foreground 'mode-line-buffer-id               "black")    ; background of mode line
(set-face-background 'region                           "SlateBlue3") ; region
;(set-cursor-color                                      "#FF0000")    ; cursor
;(set-face-foreground 'font-lock-function-name-face     "IndianRed4") ; function name color
;(set-face-foreground 'font-lock-variable-name-face     "medium blue"); variable color
;(set-face-foreground 'font-lock-type-face              "dark green") ; class color


;;
;; editor setting
;;______________________________________________________________________

;; delete whole line on C-k
(setq kill-whole-line t)

;; show all reslut of eval
(setq eval-expression-print-length nil)

;; highlight pair paren対応する括弧を光らせる。
(show-paren-mode 1)

;; ウィンドウ内に収まらないときだけ括弧内も光らせる。
(setq show-paren-style 'mixed)

;; show space on the end of line
(setq-default show-trailing-whitespace t)


;; adjust line space
(setq-default line-spacing 0)

;; ignore case on completion
(setq completion-ignore-case t)
(setq read-file-name-completion-ignore-case t)

;; use partial completion
;; p-bでprint-bufferとか
;(partial-completion-mode t)

;; always show complete list
;(icomplete-mode 1)

;; print current func
(which-func-mode 1)
(setq which-func-modes t)

;; do not make backup file
(setq backup-inhibited t)

;; delete auto save file on exit
(setq delete-auto-save-files t)

;; recentf menu items
(setq recentf-max-menu-items 20)
(setq recentf-max-saved-items 3000)
(setq recentf-auto-cleanup 'never)
(setq recentf-exclude '("/recentf" "COMMIT_EDITMSG" "/.?TAGS" "^/sudo:" "/\\.emacs\\.d/\\.cask/"))
(setq recentf-auto-save-timer (run-with-idle-timer 30 t 'recentf-save-list))

(global-set-key (kbd "C-x f") 'helm-recentf)
(global-set-key (kbd "C-x C-f") 'helm-recentf)

(recentf-mode 1)

;; Add dired to recentf
(require 'recentf-ext)

(recentf-mode t)

(setq history-length 10000)

;; save minibuffer history
(savehist-mode 1)

;; delete trailing whitespace
(add-hook 'before-save-hook 'delete-trailing-whitespace)


;;
;; key setting
;;______________________________________________________________________

(global-unset-key "\C-z")
;(global-set-key "\C-z" 'undo)
(global-set-key (kbd "C-q")   'recentf-open-files)
(global-set-key (kbd "C-c a")   'align)
(global-set-key (kbd "C-c M-a") 'align-regexp)
(global-set-key (kbd "C-h")     'backward-delete-char)
(global-set-key (kbd "M-g")     'goto-line)
(global-set-key (kbd "C-S-i")   'indent-region)
(global-set-key (kbd "C-j")     'newline-and-indent)
(global-set-key (kbd "C-t")     'next-multiframe-window)
(global-set-key (kbd "C-;")     'comment-dwim)
(global-set-key (kbd "C-;")     'comment-or-uncomment-region)
;(global-set-key (kbd "M-r")     'replace-string)
;(global-set-key (kbd "C-q")     'undo)

;; Backspace > del region
(defadvice backward-delete-char-untabify
  (around ys:backward-delete-region activate)
  (if (and transient-mark-mode mark-active)
      (delete-region (region-beginning) (region-end))
    ad-do-it))

;;
;; Major Mode
;;______________________________________________________________________

;; go-mode
(require 'go-autocomplete)
(require 'auto-complete-config)
(ac-config-default)

;;
;; markdown-mode
;;______________________________________________________________________

;; (autoload 'markdown-mode "markdown-mode.el"
;;   "Major mode for editing Markdown files" t)

(autoload 'markdown-mode "markdown-mode"
   "Major mode for editing Markdown files" t)
(add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))



;;
;; dired-mode
;;______________________________________________________________________
(setq wdired-allow-to-change-permissions t)


;;
;; yaml-mode
;;______________________________________________________________________

(require 'yaml-mode)
(add-to-list 'auto-mode-alist '("\\.yml$" . yaml-mode))
(add-hook 'yaml-mode-hook
          '(lambda ()
             (define-key yaml-mode-map "\C-j" 'newline-and-indent)))


(global-set-key (kbd "C-l") 'auto-complete)
(setq ac-auto-start 4)
(setq ac-auto-show-menu 0.2)
(defvar ac-dir (expand-file-name "~/.emacs.d/elisp/auto-complete"))
(add-to-list 'load-path ac-dir)
(add-to-list 'load-path (concat ac-dir "/lib/ert"))
(add-to-list 'load-path (concat ac-dir "/lib/fuzzy"))
(add-to-list 'load-path (concat ac-dir "/lib/popup"))

;;; ベースとなるソースを指定
(defvar my-ac-sources
              '(ac-source-abbrev
                ac-source-dictionary
                ac-source-words-in-same-mode-buffers))
;;                ac-source-yasnippet))


(global-auto-complete-mode t)

;;; C-n / C-p で選択
(setq ac-use-menu-map t)


;;
;; html, javascripts, css
;;______________________________________________________________________

(setq js-indent-level 2)
(setq css-indent-offset 2)

(require 'web-mode)
(add-to-list 'auto-mode-alist '("\\.html?$"     . web-mode))

(defun web-mode-hook ()
  "Hooks for Web mode."
  (setq web-mode-html-offset   2)
  (setq web-mode-css-offset    2))
;;  (turn-off-smartparens-mode))
(add-hook 'web-mode-hook 'web-mode-hook)
(set-face-attribute 'web-mode-symbol-face nil :foreground "#FF7400")


;;
;; pop-win
;;______________________________________________________________________
(require 'popwin)
(setq display-buffer-function 'popwin:display-buffer)
(push '("*anything*") popwin:special-display-config)


;;
;; hlinum (add background color for current line num)
;;______________________________________________________________________
(require 'hlinum)

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(linum-highlight-face ((t (:foreground "black" :background "snow")))))

(set-face-foreground 'linum-highlight-face "black")
(set-face-background 'linum-highlight-face "snow")

(hlinum-activate)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(global-linum-mode t)
 '(package-selected-packages
   (quote
    (helm-ghq f helm toml-mode terraform-mode yaml-mode web-mode recentf-ext popwin markdown-mode hlinum go-mode git-gutter-fringe direx auto-complete ag))))

;;
;; helm
;;______________________________________________________________________
(require 'helm)
(require 'helm-config)
(helm-mode 1)
(helm-autoresize-mode t)
(global-set-key (kbd "M-x") 'helm-M-x)
(setq helm-M-x-fuzzy-match t) ;; optional fuzzy matching for helm-M-x
(define-key helm-find-files-map (kbd "C-h") 'delete-backward-char)

(global-set-key (kbd "C-x b") 'helm-mini)
(setq helm-buffers-fuzzy-matching t
      helm-recentf-fuzzy-match    t)

(set-face-attribute 'helm-selection nil
		     :background "brightmagenta"
		     :foreground "black");

(global-set-key (kbd "C-x C-f") 'helm-find-files)

(define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action) ; rebind tab to do persistent action
(define-key helm-map (kbd "C-i") 'helm-execute-persistent-action) ; make TAB works in terminal
(define-key helm-map (kbd "C-z")  'helm-select-action) ; list actions using C-z

(setq helm-ff-file-name-history-use-recentf t)

(defadvice helm-ff-kill-or-find-buffer-fname (around execute-only-if-exist activate)
  "Execute command only if CANDIDATE exists"
  (when (file-exists-p candidate)
    ad-do-it))

;; helm-ghq
(define-key global-map (kbd "C-]")     'helm-ghq)

;;
;; ag
;; https://github.com/Wilfred/ag.el
;;______________________________________________________________________
(require 'ag)

;;
;; direx
;;______________________________________________________________________
(require 'direx)
;(require 'direx-project)

(defun my/dired-jump ()
  (interactive)
  (cond (current-prefix-arg
         (dired-jump))
        ((not (one-window-p))
         (or (ignore-errors
               (direx-project:jump-to-project-root) t)
             (direx:jump-to-directory)))
        (t
         (or (ignore-errors
               (direx-project:jump-to-project-root-other-window) t)
             (direx:jump-to-directory-other-window)))))

(push '(direx:direx-mode :position left :width 40 :dedicated t)
      popwin:special-display-config)

(global-set-key (kbd "C-x C-j") 'my/dired-jump)
(global-set-key (kbd "C-x RET") 'my/dired-jump)
; (global-set-key (kbd "C-x C-j") 'direx:jump-to-directory-other-window)
