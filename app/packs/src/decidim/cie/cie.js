'use strict';

var _popupCie = function _popup() {
    var buttons = document.querySelectorAll('.cie-italia-it-button');
    var popupContainer = document.querySelector('.cie-container');

    if (buttons.length > 0) {
        (function () {

            popupContainer.querySelectorAll( "[data-idp] img").forEach(function (button) {
                button.addEventListener('click', function (e) {
                    e.stopPropagation();
                    button.closest( "form").submit();
                });
            });
        })();
    }
};

document.addEventListener("DOMContentLoaded", function (event) {
    _popupCie();
});

document.addEventListener('turbolinks:load', function () {
    _popupCie();
});