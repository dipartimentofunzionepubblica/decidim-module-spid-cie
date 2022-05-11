'use strict';

var _popup = function _popup() {
    var buttons = document.querySelectorAll('.cie-italia-it-button');
    var popupContainer = document.querySelector('.cie-container');

    if (buttons.length > 0) {
        (function () {

            popupContainer.querySelectorAll( "[data-idp]").forEach(function (button) {
                button.addEventListener('click', function (e) {
                    e.stopPropagation();
                    button.querySelector( "form").submit();
                });
            });
        })();
    }
};

document.addEventListener("DOMContentLoaded", function (event) {
    _popup();
});

document.addEventListener('turbolinks:load', function () {
    _popup();
});