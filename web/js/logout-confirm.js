(function () {
    var pendingLogoutUrl = null;
    var lastFocusedElement = null;

    function ensureDialog() {
        var existing = document.getElementById('logoutConfirmModal');
        if (existing) {
            return existing;
        }

        var overlay = document.createElement('div');
        overlay.id = 'logoutConfirmModal';
        overlay.className = 'logout-modal-overlay';
        overlay.setAttribute('role', 'dialog');
        overlay.setAttribute('aria-modal', 'true');
        overlay.setAttribute('aria-labelledby', 'logoutConfirmTitle');
        overlay.setAttribute('aria-describedby', 'logoutConfirmMessage');
        overlay.hidden = true;

        overlay.innerHTML =
            '<div class="logout-modal-card">' +
                '<div class="logout-modal-icon" aria-hidden="true">!</div>' +
                '<h2 id="logoutConfirmTitle">Logout Confirmation</h2>' +
                '<p id="logoutConfirmMessage">Are you sure you want to log out?</p>' +
                '<p class="logout-modal-subtext">You will need to sign in again to access your ShareHub account.</p>' +
                '<div class="logout-modal-actions">' +
                    '<button type="button" class="logout-modal-cancel">Cancel</button>' +
                    '<button type="button" class="logout-modal-confirm">Logout</button>' +
                '</div>' +
            '</div>';

        document.body.appendChild(overlay);

        overlay.querySelector('.logout-modal-cancel').addEventListener('click', closeDialog);
        overlay.querySelector('.logout-modal-confirm').addEventListener('click', function () {
            if (pendingLogoutUrl) {
                window.location.href = pendingLogoutUrl;
            }
        });

        overlay.addEventListener('click', function (event) {
            if (event.target === overlay) {
                closeDialog();
            }
        });

        document.addEventListener('keydown', function (event) {
            if (!overlay.hidden && event.key === 'Escape') {
                closeDialog();
            }
        });

        return overlay;
    }

    function openDialog(url) {
        pendingLogoutUrl = url;
        lastFocusedElement = document.activeElement;

        var dialog = ensureDialog();
        dialog.hidden = false;
        document.body.classList.add('logout-modal-open');

        var cancelButton = dialog.querySelector('.logout-modal-cancel');
        if (cancelButton) {
            cancelButton.focus();
        }
    }

    function closeDialog() {
        var dialog = document.getElementById('logoutConfirmModal');
        if (!dialog) {
            return;
        }

        dialog.hidden = true;
        pendingLogoutUrl = null;
        document.body.classList.remove('logout-modal-open');

        if (lastFocusedElement && typeof lastFocusedElement.focus === 'function') {
            lastFocusedElement.focus();
        }
    }

    document.addEventListener('click', function (event) {
        var link = event.target.closest ? event.target.closest('a[href]') : null;
        if (!link) {
            return;
        }

        var href = link.getAttribute('href') || '';
        if (href.indexOf('LogoutServlet') === -1) {
            return;
        }

        event.preventDefault();
        openDialog(link.href);
    });
}());
