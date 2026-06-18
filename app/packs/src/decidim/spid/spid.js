// Copyright (C) 2022 Formez PA
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
// You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

'use strict';

var _popup = function _popup() {
    var container = document.querySelector('.spid-selector-container');
    // Se il container principale non esiste, esci subito dalla funzione
    if (!container) return;

    var button = container.querySelector('.italia-it-button');
    var popupContainer = container.querySelector('.spid-container');
    var questionContainer = container.querySelector('.spid-alert');
    var questionSelector = container.querySelector('.spid-question-mark');

    // Funzione di chiusura globale sicura
    document.onclick = function(e) {
        if (popupContainer) popupContainer.classList.remove('opened');
        if (questionContainer) questionContainer.classList.remove('opened');
    };

    // Gestione bottone SPID
    if (button && popupContainer && questionContainer) {
        button.onclick = function(e) {
            e.stopPropagation();
            questionContainer.classList.remove('opened');
            var list = popupContainer.querySelectorAll('div[data-idp]');
            for (var i = list.length; i >= 0; i--) {
                popupContainer.prepend(list[Math.random() * i | 0]);
            }
            popupContainer.classList.toggle('opened');
        };
    }

    // Gestione alert info
    if (questionContainer) {
        questionContainer.onclick = function(e) { e.stopPropagation(); };
    }
    
    if (questionSelector && popupContainer && questionContainer) {
        questionSelector.onclick = function(e) {
            e.stopPropagation();
            popupContainer.classList.remove('opened');
            questionContainer.classList.toggle('opened');
        };
    }

    // Gestione click sugli IDP
    if (popupContainer) {
        popupContainer.querySelectorAll("[data-idp]").forEach(function (btn) {
            btn.addEventListener('click', function (e) {
                e.stopPropagation();
                var form = btn.querySelector("form");
                if (form) form.submit();
            });
        });
    }
};

document.addEventListener("DOMContentLoaded", _popup);
document.addEventListener('turbolinks:load', _popup);