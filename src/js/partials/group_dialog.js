(function (global, undefined) {
  "use strict"

  let editabled_id;

  let fn_dialogs = {
    init: function (fn) {

      let appendEditLine = (title, id) => {
        let line = $('<div/>').css({'display': 'flex', 'padding': 5}).appendTo($('#group-form'));
      
        $('<div/>').css('width', 300)
          .append($('<span/>').html(title))
          .appendTo(line);
        $('<div/>').css('width', '100%')
          .append($('<input/>').attr({'type': 'text', 'id': `text-group-${id}`}))
          .appendTo(line);

        return line;
      }

      let createGroupWindow = (fn) => {
        $('#group-window').jqxWindow({
          isModal: true,
          autoOpen: false, 
          resizable: false,
          position: 'center',
          showCollapseButton: false,
          height: 147,
          width: 400,
          theme: localStorage.global_theme,
          cancelButton: $('#button-cancel'),
          initContent: function () {
            $('#text-group-code').jqxInput({ width: '100%', theme: localStorage.global_theme });
            $('#text-group-name').jqxInput({ width: '100%', theme: localStorage.global_theme });
            $('#button-ok').jqxButton({ width: 80, theme: localStorage.global_theme });					
            $('#button-cancel').jqxButton({ width: 80, theme: localStorage.global_theme });
            $('#group-form').jqxValidator({
              rules: [
                { input: '#text-group-code', message: 'Код папки обязательно должен быть установлен!', action: 'keyup', rule: 'required' },
                { input: '#text-group-name', message: 'Наименование папки не может быть пустым!', action: 'keyup', rule: 'required' }
              ],
              theme: localStorage.global_theme
            });
            $('#button-ok').click(function () { 
              $('#group-form').jqxValidator('validate') 
            });
          }
        });

        $('#group-window').on('open', function (event) { $('#text-group-code').jqxInput('focus') }); 
      }

      if ($('#group-window').length == 0) {
        $('body').append($('<div/>').attr('id', 'group-window').css('display', 'none'));
        $('<div/>')
          .append($('<span/>').css('float', 'left').html('Группа'))
          .appendTo($('#group-window'))
        $('<div/>')
          .append($('<form/>').attr('id', 'group-form'))
          .appendTo($('#group-window'));
      
        appendEditLine('Код группы', 'code');
        appendEditLine('Наименование группы', 'name');

        let buttons = $('<div/>').css({'float': 'right', 'padding': 5}).appendTo($('#group-form'));
        buttons.append($('<input/>').attr({'id': 'button-ok', 'type': 'button', 'value': 'Ok'}).css('margin-right', 10));
        buttons.append($('<input/>').attr({'id': 'button-cancel', 'type': 'button', 'value': 'Отмена'}));

        createGroupWindow();

        $('#group-form').jqxValidator({ onSuccess: function () {
          let params = {
            id: editabled_id,
            code : $('#text-group-code').val(), 
            name: $('#text-group-name').val()
          }

          fn(params);
        } });
      } else {
				$('#text-group-code').val('');
        $('#text-group-name').val('');
        $('#text-group-code').jqxInput('focus');
      }

      editabled_id = undefined;
    },

    create: function (fn) {
      this.init(fn);
      $("#group-window").jqxWindow('open');
    },

    edit: function (data, fn) {
      this.init(fn);
      if (data != null) {
        $('#text-group-code').val(data.code);
        $('#text-group-name').val(data.name);
        editabled_id = data.id;
      }

      $("#group-window").jqxWindow('open');
    }
  }

  let GroupDialog = function() {
    return {
			create : function (fn) { fn_dialogs.create(fn); return this; },
			edit   : function (data, fn) { fn_dialogs.edit(data, fn); return this; }
		};
  }

  if (typeof define === 'function') {
		define([], function () { 
			return new GroupDialog(); 
		});
	} else if (typeof global.alertify === 'undefined') {
		global.groupDialog = new GroupDialog();
	}
}(this));