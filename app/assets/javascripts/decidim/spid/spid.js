'use strict';

var _popup = function _popup() {
    var container = document.querySelector('.spid-selector-container ')
    var button = container.querySelector('.italia-it-button');
    var popupSelector = container.querySelector('.spid-selector');
    var popupContainer = container.querySelector('.spid-container');
    var questionContainer = container.querySelector('.spid-alert');
    var questionSelector = container.querySelector('.spid-question-mark');

    document.onclick = function(e) {
        popupContainer.classList.remove('opened')
        questionContainer.classList.remove('opened')
    }
    button.onclick = function(e) {
        e.stopPropagation();
        questionContainer.classList.remove('opened')
        var list = popupContainer.querySelectorAll('div'); // All children
        for (var i = list.length; i >= 0; i--) {
            popupContainer.appendChild(list[Math.random() * i | 0]);
        }
        popupContainer.classList.toggle('opened')
    };

    questionContainer.onclick = function(e) {
        e.stopPropagation();
    }
    questionSelector.onclick = function(e) {
        e.stopPropagation();
        popupContainer.classList.remove('opened')
        questionContainer.classList.toggle('opened')
    };

    popupContainer.querySelectorAll( "[data-idp]").forEach(function (button) {
        button.addEventListener('click', function (e) {
            e.stopPropagation();
            button.querySelector( "form").submit();
        });
    });

};

document.addEventListener("DOMContentLoaded", function (event) {
    _popup();
});

document.addEventListener('turbolinks:load', function () {
    _popup();
});