(function (global, undefined) {
	"use strict"

  let Dialogs = function() {
		let message_info = {
			'error': { 
				header: 'Ошибка',
				image: 'img/icons8-error-40.png',
				buttons: [
					{
						id: 'button-message-close',
						text: 'Закрыть',
						default: true
					}
				]
			},
			'warning': {
				header: 'Предупреждение',
				image: 'img/icons8-warning-40.png',
				buttons: [
					{
						id: 'button-message-close',
						text: 'Закрыть',
						default: true
					}
				]
			},
			'question': {
				header: 'Подтверждение',
				image: 'img/icons8-question-40.png',
				buttons: [
					{
						id: 'button-message-yes',
						text: 'Да',
						default: true,
						result_value: true
					},
					{
						id: 'button-message-no',
						text: 'Нет',
						default: true,
						canceled: true,
						result_value: false
					}
				]
			}
		}

		let fn_dialogs = {
			init: function (message_class) {
				if ($('#message-window').length == 0) {
					$('body').append($('<div/>').attr('id', 'message-window').css('display', 'none'));
					$('#message-window').append($('<div/>').attr('id', 'message-window-header'));
					$('#message-window-header').append($('<span/>').css('float', 'left').html(message_info[message_class].header));
					$('#message-window').append($('<div/>').attr('id', 'message-window-content'));
				} else {
					$('#message-window-content').empty();
					$('#message-window-header span').html(message_info[message_class].header);
				}

				$('#message-window-content').append($('<form/>').attr('id', 'message-form'));
				$('#message-form').append($('<div/>').attr('id', 'message-content').css({ 'display': 'inline-block', 'padding': '8px' }));
				$('#message-content').append($('<img/>').attr('src', message_info[message_class].image).css({ 'float': 'left', 'margin-right': '16px' }));
				$('#message-content').append($('<span/>').attr('id', 'message-text'));
				
				$('#message-form').append($('<div/>').attr('id', 'message-buttons').css({ 'text-align': 'center', 'padding': '5px;' }));
				for (let i = 0; i < message_info[message_class].buttons.length; i++)
				{
					let button = message_info[message_class].buttons[i];
					let btn = $('<input/>').attr({ 'id': button.id, 'type': 'button', 'value': button.text });
					if (i > 0) {
						btn.css('margin-left', '10px');
					}

					$('#message-buttons').append(btn);
				}
			},

			show: function (message_class, message, fn) {
				this.init(message_class);

				let default_btn = message_info[message_class].buttons.find(button => 'default' in button && button.default);
				let canceled_btn = message_info[message_class].buttons.find(button => 'canceled' in button && button.canceled);

				$('#message-window').jqxWindow({
					isModal: true,
					autoOpen: false, 
					resizable: false,
					position: 'center',
					showCollapseButton: false,
					height: 135,
					width: 300,
					theme: localStorage.global_theme,
					okButton: typeof default_btn === 'undefined' ? null : $(`#${default_btn.id}`),
					cancelButton: typeof canceled_btn === 'undefined' ? null : $(`#${canceled_btn.id}`)
				});

				$('#message-text').html(message);
				message_info[message_class].buttons.forEach(button => {
					let btn = $(`#${button.id}`);
					btn.jqxButton({ width: '80px', theme: localStorage.global_theme });
					btn.click(() => {
						if (typeof fn == 'function')
						{
							fn(button.result_value);
						}
					});
				});

				$('#message-window').jqxWindow('open');

				return this;
			}
		}

		return {
			confirm : function (message, fn) { fn_dialogs.show('question', message, fn); return this; },
			error   : function (message) { fn_dialogs.show('error', message); return this; }
		};
  }

  if (typeof define === 'function') {
		define([], function () { 
			return new Dialogs(); 
		});
	} else if (typeof global.alertify === 'undefined') {
		global.dialogs = new Dialogs();
	}
}(this));
