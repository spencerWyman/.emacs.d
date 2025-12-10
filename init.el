;; package management setup
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
			 ("org" . "https://orgmode.org/elpa/")
			 ("elpa" . "https://elpa.gnu.org/packages/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))
 
(require 'use-package)
(setq use-package-always-ensure t)

;; general emacs configuration

;; ;; save backup and autosave files elsewhere
(setq backup-directory-alist
      '((".*" . "~/.emacs.d/.saves")))
(setq auto-save-file-name-transforms
      '((".*" "~/.emacs.d/.saves/" t)))

(setq dired-kill-when-opening-new-dired-buffer t)

;; ;; keymaps
(use-package hydra)

(global-set-key (kbd "C-x C-b") 'ibuffer)
(global-set-key (kbd "M-o") 'other-window)


(defalias 'kmac-three-tiling
  (kmacro "C-x 1 C-x 3 C-x o C-x 2 M-o M-o"))




;; window movement
(winner-mode 1) ;; remember window history
(use-package ace-window) ;; window movement convenience functions

 (defhydra hydra-window ()
   "
Movement^^        ^Split^         ^Switch^	     ^Presets
-----------------------------------------------------------------
_J_ ←       	_v_ertical    	_b_uffer	     _1_ three tiling
_k_ ↓        	_x_ horizontal	_f_ind files	
_i_ ↑        	_z_ undo      	_a_ce 1		
_l_ →        	_Z_ reset      	_s_wap		
		_D_lt Other   	_S_ave		
_SPC_ cancel	_o_nly this   	_d_elete	
"
   ("j" windmove-left )
   ("k" windmove-down )
   ("i" windmove-up )
   ("l" windmove-right )
   ("b" switch-to-buffer)
   ("f" find-file)
   ("a" (lambda ()
          (interactive)
          (ace-window 1)
          (add-hook 'ace-window-end-once-hook
                    'hydra-window/body))
       )
   ("v" (lambda ()
          (interactive)
          (split-window-right)
          (windmove-right))
       )
   ("x" (lambda ()
          (interactive)
          (split-window-below)
          (windmove-down))
       )
   ("s" (lambda ()
          (interactive)
          (ace-window 4)
          (add-hook 'ace-window-end-once-hook
                    'hydra-window/body)))
   ("S" save-buffer)
   ("d" delete-window)
   ("D" (lambda ()
          (interactive)
          (ace-window 16)
          (add-hook 'ace-window-end-once-hook
                    'hydra-window/body))
       )
   ("o" delete-other-windows)
   ("z" (progn
          (winner-undo)
          (setq this-command 'winner-undo))
   )
   ("Z" winner-redo)
   ("SPC" nil)
   ("1" kmac-three-tiling)
   )

(global-set-key (kbd "M-O") 'hydra-window/body)

;; UI configuration
(setq inhibit-startup-message t)
(setq visible-bell t)
(tool-bar-mode -1)
(tooltip-mode -1)
(scroll-bar-mode -1)
(set-fringe-mode 10)
(menu-bar-mode -1)
(set-face-attribute 'default nil :height 120)
(column-number-mode)
(global-display-line-numbers-mode t)
(which-key-mode 1)

;; ;; auto-resize windows
(use-package golden-ratio
  :init
  (golden-ratio-mode 1))

;; ;; disable line numbers for some modes
(dolist (mode '(org-mode-hook
		term-mode-hook
		shell-mode-hook
		eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(use-package nerd-icons)

(use-package doom-modeline
  :init
  (doom-modeline-mode 1))

(use-package doom-themes
  :custom
  (doom-themes-enable-bold t)
  (doom-themes-enable-italics t)
  :config
  (load-theme 'doom-outrun-electric t)
  (doom-themes-org-config))
  
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; magit
(use-package magit)


;; completion framework (choosing vertico for now)
(use-package vertico
  :init
  (vertico-mode))

;; ;; vertico uses command history, so let's preserve it across sessions
(use-package savehist
  :init
  (savehist-mode))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil) ;; Disable defaults, use orderless' settings
  (completion-pcm-leading-wildcard t)) ;; Emacs 31: partial-completion behaves like substring

;; ;; Enable rich annotations using the Marginalia package
(use-package marginalia
  ;; Bind `marginalia-cycle' locally in the minibuffer.  To make the binding
  ;; available in the *Completions* buffer, add it to the
  ;; `completion-list-mode-map'.
  :bind (:map minibuffer-local-map
         ("M-A" . marginalia-cycle))
  :init
  (marginalia-mode))

(use-package corfu
  :init
  (global-corfu-mode))


;; ;; emacs config for completion and mini-buffer
(use-package emacs
  :custom
  ;; Enable context menu. `vertico-multiform-mode' adds a menu in the minibuffer
  ;; to switch display modes.
  (context-menu-mode t)
  ;; Hide commands in M-x which do not work in the current mode.  Vertico
  ;; commands are hidden in normal buffers. This setting is useful beyond
  ;; Vertico.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Do not allow the cursor in the minibuffer prompt
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt))
  ;; Enable indentation+completion using the TAB key.
  ;; `completion-at-point' is often bound to M-TAB.
  (tab-always-indent 'complete)
  ;; Emacs 30 and newer: Disable Ispell completion function.
  ;; Try `cape-dict' as an alternative.
  (text-mode-ispell-word-completion nil))

;; language server (lsp-mode)
(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :hook ((c-mode . lsp-deferred)
	 (c++-mode . lsp-deferred))
  :init
  (setq lsp-keymap-prefix "C-c l")
  :config
  (lsp-enable-which-key-integration t))

;; ;; we only use company for lsp pop-ups, otherwise use vertico
(use-package company
  :after lsp-mode ;; when not in lsp-mode, use vertico
  :hook (lsp-mode . company-mode)
  :custom
  (company-minimum-prefix-length 1)
  (company-idle-delay 0.0))

(use-package lsp-ui
  :hook (lsp-mode . lsp-ui-mode))

;; ;; python 
(use-package lsp-pyright
  :custom (lsp-pyright-langserver-command "pyright")
  :hook (python-mode . (lambda ()
                          (require 'lsp-pyright)
                          (lsp-deferred))))


;; custom scripts
(defun create-cpp-project (project-name)
  "Call the create_cpp_project.sh script to create a new C++ project."
  (interactive "sEnter project path: ")
  (let ((script-path "~/CS_Projects/scripts/cpp_project_gen.sh"))  ; Adjust the path if necessary
    (if (file-exists-p script-path)
        (progn
          (shell-command (concat script-path " " project-name))
          (message "C++ project '%s' created." project-name))
      (message "Error: Script not found! Please check the path."))))



;; auto-config

;; ;; copied from .emacs

;;; -*- lexical-binding: t -*-
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(ace-window company corfu doom-modeline doom-themes golden-ratio
		hydra lsp-mode lsp-pyright lsp-ui magit marginalia
		orderless rainbow-delimiters vertico)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
