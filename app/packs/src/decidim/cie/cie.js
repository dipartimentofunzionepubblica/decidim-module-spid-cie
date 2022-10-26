// Copyright (C) 2022 Formez PA
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
// You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

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