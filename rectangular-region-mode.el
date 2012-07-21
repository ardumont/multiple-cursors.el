(require 'multiple-cursors-core)

(defvar rrm/anchor (make-marker)
  "The position in the buffer that anchors the rectangular region.")

(defvar rectangular-region-mode-map (make-sparse-keymap)
  "Keymap for rectangular region is mainly for rebinding C-g")

(define-key rectangular-region-mode-map (kbd "C-g") 'rrm/keyboard-quit)
(define-key rectangular-region-mode-map (kbd "<return>") 'rrm/switch-to-multiple-cursors)

(defun rrm/keyboard-quit ()
  (interactive)
  (rectangular-region-mode 0)
  (rrm/remove-rectangular-region-overlays)
  (deactivate-mark))

;; Bind this to a key (for instance H-SPC) to start rectangular-region-mode
(defun set-rectangular-region-anchor ()
  (interactive)
  (set-marker rrm/anchor (point))
  (push-mark (point))
  (rectangular-region-mode 1))

(defun rrm/remove-rectangular-region-overlays ()
  (mc/remove-fake-cursors)
  (mapc #'(lambda (o)
            (when (eq (overlay-get o 'type) 'additional-region)
              (delete-overlay o)))
        (overlays-in (point-min) (point-max))))

(defun rrm/repaint ()
  (rrm/remove-rectangular-region-overlays)
  (let* ((annoying-arrows-mode nil)
         (point-column (current-column))
         (point-line (line-number-at-pos))
         (anchor-column (save-excursion (goto-char rrm/anchor) (current-column)))
         (anchor-line (save-excursion (goto-char rrm/anchor) (line-number-at-pos)))
         (left-column (if (< point-column anchor-column) point-column anchor-column))
         (right-column (if (> point-column anchor-column) point-column anchor-column))
         (navigation-func (if (< point-line anchor-line) 'next-line 'previous-line)))
    (move-to-column anchor-column)
    (set-mark (point))
    (move-to-column point-column)
    (mc/save-excursion
     (while (not (= anchor-line (line-number-at-pos)))
       (funcall navigation-func)
       (move-to-column anchor-column)
       (when (= anchor-column (current-column))
         (set-mark (point))
         (move-to-column point-column)
         (when (= point-column (current-column))
           (mc/create-fake-cursor-at-point)))))))

(defun rrm/switch-to-multiple-cursors (&rest forms)
  (interactive)
  (rectangular-region-mode 0)
  (multiple-cursors-mode 1))

(define-minor-mode rectangular-region-mode
  "A mode for creating a rectangular region to edit"
  nil " rr" rectangular-region-mode-map
  (if rectangular-region-mode
      (progn
        (add-hook 'after-change-functions 'rrm/switch-to-multiple-cursors t t)
        (add-hook 'post-command-hook 'rrm/repaint t t))
    (remove-hook 'after-change-functions 'rrm/switch-to-multiple-cursors t)
    (remove-hook 'post-command-hook 'rrm/repaint t)
    (set-marker rrm/anchor nil)))

(provide 'rectangular-region-mode)
