'use strict';

var _popup = function _popup() {
    var buttons = document.querySelectorAll('.italia-it-button');
    var popupSelector = document.querySelector('.spid-selector');
    var popupContainer = document.querySelector('.spid-container');

    if (buttons.length > 0) {
        (function () {

            var showPopup = function showPopup() {
                popupSelector.style.display = 'flex';
                popupSelector.style.visibility = 'visible';
                // popupContainer.style.display = 'flex';
                // popupContainer.style.visibility = 'visible';
                setTimeout(function () {
                    popupSelector.style.opacity = 1;
                    popupContainer.style.opacity = 1;
                    popupContainer.style.transform = 'translateY(0px)';
                }, 1);
            };

            var hidePopup = function hidePopup() {
                popupSelector.style.opacity = 0;
                popupContainer.style.opacity = 0;
                popupContainer.style.transform = 'translateY(60px)';
                setTimeout(function () {
                    popupSelector.style.display = 'none';
                    popupSelector.style.visibility = 'hidden';
                    // popupContainer.style.display = 'none';
                    // popupContainer.style.visibility = 'hidden';
                }, 250);
            };

            buttons.forEach(function (button) {
                button.addEventListener('click', function (e) {
                    e.preventDefault();
                    showPopup();
                });
            });

            popupSelector.addEventListener('click', hidePopup);
            popupContainer.addEventListener('click', function (e) {
                return e.stopPropagation();
            });

            popupContainer.querySelectorAll( "[data-idp]").forEach(function (button) {
                button.addEventListener('click', function (e) {
                    e.stopPropagation();
                    button.querySelector( "form").submit();
                });
            });

            window.addEventListener('keydown', function (event) {
                event.key === 'Escape' && hidePopup();
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