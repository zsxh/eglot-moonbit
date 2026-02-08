;;; eglot-moonbit.el --- Moonbit-lsp integration with Eglot  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  zsxh

;; Author: zsxh <bnbvbchen@gmail.com>
;; Maintainer: zsxh <bnbvbchen@gmail.com>
;; URL: https://github.com/zsxh/eglot-moonbit
;; Version: 0.0.1
;; Package-Requires: ((emacs "30.1") (compat "30.1.0.0") (eglot "1.17.30"))
;; Keywords: eglot tools

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package provides Eglot integration for Moonbit, enabling LSP
;; features such as code actions, formatting, and test execution.
;;
;; To use, add the following to your configuration:
;;
;;   (push '(moonbit-mode . (eglot-moonbit-server . ("moonbit" "lsp")))
;;         eglot-server-programs)
;;
;; Then enable `eglot' in moonbit buffers with `M-x eglot'.
;;
;; The following LSP commands are handled:
;;   - moonbit-lsp/format-nth-toplevel: Format Nth toplevel definition
;;   - moonbit-lsp/run-test: Run tests
;;   - moonbit-lsp/update-test: Update tests
;;   - moonbit-lsp/run-all-tests: Run all tests
;;   - moonbit-lsp/update-all-tests: Update all tests
;;   - moonbit-lsp/run-main: Run main program
;;

;;; Code:

(require 'cl-lib)
(require 'compat)
(require 'eglot)


(defgroup eglot-moonbit nil
  "Settings for moonbit-lsp integration with eglot."
  :group 'eglot
  :prefix "eglot-moonbit-"
  :link '(url-link :tag "GitHub" "https://github.com/zsxh/eglot-moonbit"))

(defclass eglot-moonbit-server (eglot-lsp-server)
  ()
  :documentation "moonbit langserver."
  :group 'eglot-moonbit)


(defvar eglot-moonbit-compilation-error-regexp-alist '(moonbit-box moonbit-test)
  "List of error regexp symbols for Moonbit compilation.")

(defvar eglot-moonbit-compilation-error-regexp-alist-alist
  '((moonbit-box
     "^\\s-*╭─\\[\\s-*\\([^]\n]+?\\):\\([0-9]+\\):\\([0-9]+\\)\\s-*\\]"
     1 2 3)
    (moonbit-test
     "failed:\\s-+\\([^\n]+?\\):\\([0-9]+\\):\\([0-9]+\\)"
     1 2 3))
  "Alist of error regexps for Moonbit compilation output.
See `compilation-error-regexp-alist-alist'.")

(define-derived-mode eglot-moonbit-compilation-mode compilation-mode
  "Moonbit-Compilation"
  "Major mode for Moonbit compilation output."
  (setq-local compilation-error-regexp-alist-alist
              eglot-moonbit-compilation-error-regexp-alist-alist)
  (setq-local compilation-error-regexp-alist
              eglot-moonbit-compilation-error-regexp-alist))

(defun eglot-moonbit--format (server arguments)
  "Format the Nth toplevel definition using moonbit-lsp.
SERVER is the Eglot server instance.
ARGUMENTS is a vector containing an alist with :n key specifying the
toplevel definition index to format."
  (when-let* ((arg (and arguments (vectorp arguments) (aref arguments 0)))
              (n (plist-get arg :n))
              (result (eglot--request
                       server
                       :moonbit-lsp/format-nth
                       (list
                        :content (buffer-substring-no-properties
                                  (point-min) (point-max))
                        :n n)))
              (range (plist-get result :range))
              (region (eglot-range-region range))
              (beg (car region))
              (end (cdr region))
              (newtext (plist-get result :newText)))
    (save-excursion
      (goto-char beg)
      (delete-region beg end)
      (insert (substring newtext 0 (length newtext))))))

(defun eglot-moonbit--moon-test (arguments &optional action)
  "Run moon test.
ARGUMENTS is a vector containing an alist with test specification.
ACTION can be \\='update to update tests, \\='debug for debug mode,
or nil for normal run."
  (when-let* ((arg (and arguments (vectorp arguments) (aref arguments 0)))
              (default-directory (project-root (project-current))))
    (pcase-let* (((map :pkgPath :fileName :backend :index) arg))
      (compile
       (concat "moon test"
               (when pkgPath (format " -p %s" pkgPath))
               (when fileName (format " --file %s" fileName))
               (when index (format " -i %d" index))
               (cond
                ((eq action 'update) " -u")
                ((eq action 'debug) " -g")
                (t nil))
               (when backend (format " --target %s" backend)))
       'eglot-moonbit-compilation-mode))))

(defun eglot-moonbit--moon-run (arguments)
  "Run the main program for the given package.
ARGUMENTS is a vector containing an alist with :modUri and :pkgUri keys
specifying the module and package URIs."
  (let ((arg (and arguments (vectorp arguments) (aref arguments 0)))
        (default-directory (project-root (project-current))))
    (pcase-let* (((map :modUri :pkgUri) arg))
      (compile
       (concat "moon run "
               (substring pkgUri (1+ (length modUri))))
       'eglot-moonbit-compilation-mode))))

(cl-defmethod eglot-execute :around ((server eglot-moonbit-server) action)
  "Execute Moonbit LSP commands.
SERVER is the Eglot server instance.
ACTION is a plist containing :command, :arguments, and :title."
  (pcase-let* (((map (:title _) :command :arguments) action))
    (pcase command
      ("moonbit-lsp/format-nth-toplevel" (eglot-moonbit--format server arguments))
      ("moonbit-lsp/run-test" (eglot-moonbit--moon-test arguments))
      ("moonbit-lsp/debug-test" (message "Unhandled method %s" command))
      ("moonbit-lsp/update-test" (eglot-moonbit--moon-test arguments 'update))
      ("moonbit-lsp/trace-test" (message "Unhandled method %s" command))
      ("moonbit-lsp/run-all-tests" (eglot-moonbit--moon-test arguments))
      ("moonbit-lsp/update-all-tests" (eglot-moonbit--moon-test arguments 'update))
      ("moonbit-lsp/run-main" (eglot-moonbit--moon-run arguments))
      ("moonbit-lsp/debug-main" (message "Unhandled method %s" command))
      ("moonbit-lsp/trace-main" (message "Unhandled method %s" command))
      ("moonbit-ai/generate" (message "Unhandled method %s" command))
      ("moonbit-ai/generate-batched" (message "Unhandled method %s" command))
      (_ (cl-call-next-method)))))


(provide 'eglot-moonbit)
;;; eglot-moonbit.el ends here
