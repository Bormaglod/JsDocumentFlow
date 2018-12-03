(function($)
{
	let pictures;

	const saveGridState = (selector, name, dataset) => {
		let states = [];
		for (let value of dataset.columns) {
			let column = $(selector).jqxGrid('getcolumn', value.datafield);
			let c = {
				datafield: column.datafield,
				hidden: column.hidden,
				width: column.width
			}

			states.push(c);
		}

		localStorage[name] = JSON.stringify(states);
	}

	const loadGridState = (name, dataset) => {
		let state = localStorage[name];
		if (state)
		{
			let jsonState = JSON.parse(state);
			for (const [index, value] of dataset.columns.entries()) {
				let column = jsonState.find(data => data.datafield == value.datafield);
				if (typeof column === 'undefined') continue;
				
				dataset.columns[index].hidden = column.hidden;
				dataset.columns[index].width = column.width;
			}
		}
	}

	const createErrorWindow = () => {
		$('#error-window').jqxWindow({
			isModal: true,
			autoOpen: false, 
			resizable: false,
			position: 'center',
			showCollapseButton: false,
			height: 135,
			width: 300,
			theme: localStorage.global_theme,
			okButton: $('#button-error-ok'),
			initContent: function () {
				$('#button-error-ok').jqxButton({ width: '80px', theme: localStorage.global_theme });
			}
		});
	}

	const showErrorWindow = data => {
		let msg = data.message;
		if (data.code == 23505) {

			let constraint = msg.match('"(.+?)"');
			if (constraint != null) {
				if (constraint[1].includes('code')) {
					msg = 'Такой код уже используется!';
				} else if (constraint[1].includes('name')) {
					msg = 'Такое наименование уже используется!';
				}
			}
		}

		$('#error-message').html(msg);
		$('#error-window').jqxWindow('open');
	}

	const createGroupWindow = () => {
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
				$('#button-ok').jqxButton({ width: '80px', theme: localStorage.global_theme });					
				$('#button-cancel').jqxButton({ width: '80px', theme: localStorage.global_theme });
				$('#group-window').jqxWindow('focus');
				$('#group-form').jqxValidator({
					rules: [
						{ input: '#text-group-code', message: 'Код папки обязательно должен быть установлен!', action: 'keyup, blur', rule: 'required' },
						{ input: '#text-group-name', message: 'Наименование папки не может быть пустым!', action: 'keyup, blur', rule: 'required' }
					],
					theme: localStorage.global_theme
				});
				$('#button-ok').click(function () { 
					$('#group-form').jqxValidator('validate') 
				});
			}
		});
	}

	const createColumnsWindow = () => {
		$('#columns-window').jqxWindow({ 
			resizable: true, 
			autoOpen: false, 
			width: 210, 
			height: 200,
			title: 'Колонки',
			theme: localStorage.global_theme
		});
	}

	const createGridAdapter = (dataset, params) => {
		source = {
			datatype: 'json',
			url: 'lib/select.php',
			data: { 'select_sql': dataset.select },
			type: 'POST',
			addrow: function (rowid, rowdata, position, commit) {
				commit(true);
			},
			updaterow: function (rowid, rowdata, commit) {
        commit(true);
    	}
		}

		if (typeof params !== 'undefined') {
			$.extend(source.data, params);
		}
		
		return new $.jqx.dataAdapter(source);
	}

	const readPictures = () => {
		params = { 
			select_sql: "select * from picture_select() where parent_id = get_constant('picture.status')::uuid" 
		}

		$.post('lib/select.php', params)
			.done(data => pictures = data);
	}

	const createGridView = (selector, cmd_id) => {
		$(selector).off();
		$('#group-window').off();

		let master_dataset;
		let detail_dataset;
		let grid_name;

		const settingVariables = data => {
			master_dataset = $.grep(data.schema_data.viewer.datasets, e => e.name == data.schema_data.viewer.master)[0];
			if ('detail' in data.schema_data.viewer) {
				detail_dataset = $.grep(data.schema_data.viewer.datasets, e => e.name == data.schema_data.viewer.detail)[0];
			}

			grid_name = selector.substring(4) + '-' + master_dataset.name;
		}

		const renderRecord = (datafield, value) => {
			if (datafield == 'status_picture_id') {
				let picture = pictures.rows.find(function (elem) {
					return elem.id == value;
				});

				let rowsheight = $(selector).jqxGrid('rowsheight');
				let column = master_dataset.columns.find(data => data.datafield == datafield);
				let left = (column.width - 16) / 2;
				let top = (rowsheight - 16) / 2;
				return `<img style="margin-left: ${left}px; margin-top: ${top}px" height="16" width="16" src="img/${picture.img_name}"/>`;
			} else {
				return '';
			}
		}

		const renderToolbar = statusbar => {
			statusbar.html('');
	
			let container = $('<div/>').attr('id', 'grid-toolbar').css({'overflow': 'hidden', 'position': 'relative', 'margin': '3px'});
			let buttons = $('<div/>').addClass('toolbar');
	
			const addButton = (name, title) => {
				return $(`<div class="btn-text btn-left"><i class="fas fa-${name}"></i>${title}</div>`)
					.appendTo(buttons)
					.jqxButton({ 
						height: 16, 
						theme: localStorage.global_theme 
					});
			}

			const createGroupControls = () => {
				$('#text-group-id').val('');
				$('#text-group-code').val('');
				$('#text-group-name').val('');
				$("#group-window").jqxWindow('open');
			}

			const editGroupControls = () => {
				let selected = $(selector).jqxGrid('selectedrowindex');
				if (selected != -1) {
					let data = $(selector).jqxGrid('getrowdata', selected);
					if (data.status_id == 500) {
						$('#text-group-id').val(data.id);
						$('#text-group-code').val(data.code);
						$('#text-group-name').val(data.name);
						$("#group-window").jqxWindow('open');
					}
				}
			}
	
			addButton('plus-square', 'Создать');
			addButton('pen-square', 'Изменить').click(editGroupControls);
			addButton('minus-square', 'Удалить');
	
			if (master_dataset.info.has_group) {
				$('<div/>').addClass('section-separator').appendTo(buttons);
				addButton('folder-plus', 'Создать группу').click(createGroupControls);
			}

			let buttonColumns = $('<div class="btn-right"><i class="fas fa-columns"></i></div>');
			buttons.append(buttonColumns);

			buttonColumns.jqxButton({  width: 16, height: 16, theme: localStorage.global_theme });

			container.append(buttons);
						
			if (master_dataset.info.has_group) {
				let bread = $('<div/>').attr('id', 'breadcrumbs').css({ 'float': 'left', 'width': '100%' });
				container.append(bread);
				bread.breadcrumbs({
					onSelect: function(parent_id) {
						let source = parent_id == 'null' ? createGridAdapter(master_dataset) : createGridAdapter(master_dataset, { parent: parent_id });
						$(selector).jqxGrid('source', source);
					}
				});
			}
						
			statusbar.append(container);

			buttonColumns.click(function (event) {
				let offset = buttonColumns.offset();
				$("#columns-window").jqxWindow('open');
				$("#columns-window").jqxWindow('move', offset.left - ($("#columns-window").width() - 26), offset.top + 29);
			});
	
			let table = $('<table/>');
	
			for (value of master_dataset.columns) {
				if (!value.hideable) continue;

				let row = $('<tr/>');
	
				let checkedField = !value.hidden;
	
				let td = $('<td/>').attr('datafield', value.datafield).jqxCheckBox({ 
					width: 16,
					height: 16,
					checked: checkedField,
					locked: !value.hideable,
					theme: localStorage.global_theme
				});
	
				td.appendTo(row);
	
				td.on('change', function (event) { 
					let checked = event.args.checked; 
	
					let action = checked ? 'showcolumn' : 'hidecolumn';
					$(selector).jqxGrid(action, $(this).attr('datafield'));
	
					saveGridState(selector, grid_name, master_dataset);
				});
	
				$('<td/>').css('height', '24px').html(value.text).appendTo(row);
	
				row.appendTo(table);
			}

			$('#columns-window').jqxWindow({ content: table });
		}

		const updateColumns = () => {
			for (let col of master_dataset.columns) {
				if (col.type == 'image') {
					col.cellsrenderer = (row, datafield, value) => { return renderRecord(datafield, value); }
				}
			}
		}

		const createGroup = params => {
			$.extend(params, {
				kind: master_dataset.info.id,
				parent: $('#breadcrumbs').breadcrumbs('current')
			});

			$.post('lib/add_group.php', params)
					.done(data => {
						if (data.code == 0) {
							$(selector).jqxGrid('addrow', null, data.result);
							$('#group-window').jqxWindow('close');
						} else {
							showErrorWindow(data);
						}
					});
		}

		const updateGroup = params => {
			$.extend(params, {
				id: $('#text-group-id').val()
			});

			$.post('lib/update_group.php', params)
					.done(data => {
						if (data.code == 0) {
							let selectedrowindex = $(selector).jqxGrid('getselectedrowindex');
							let rowscount = $(selector).jqxGrid('getdatainformation').rowscount;
							if (selectedrowindex >= 0 && selectedrowindex < rowscount) {
								let id = $(selector).jqxGrid('getrowid', selectedrowindex);
								$(selector).jqxGrid('updaterow', id, data.result);
								$(selector).jqxGrid('ensurerowvisible', selectedrowindex);
							}

							$('#group-window').jqxWindow('close');
						}	else {
							showErrorWindow(data);
						}
					});
		}

		const executeActionGroup = () => {
			let params = {
				code : $('#text-group-code').val(), 
				name: $('#text-group-name').val()
			}

			if ($('#text-group-id').val() == '') {
				createGroup(params);
			} else {
				updateGroup(params);
			}
		}

		const createGrid = () => {
			let toolbar_height = master_dataset.info.has_group ? 66 : 35;

			loadGridState(grid_name, master_dataset);

			$(selector).jqxGrid({
				source: createGridAdapter(master_dataset),
				columns: master_dataset.columns,
				width: '100%',
				pageable: true,
				autoheight: true,
				sortable: true,
				columnsresize: true,
				showtoolbar: true,
				pagesize: detail_dataset == null ? 20 : 10,
				theme: localStorage.global_theme,
				toolbarheight: toolbar_height,
				rendertoolbar: renderToolbar
			});
		}
		
		let params = { id: cmd_id };

		$.post('lib/get_command.php', params)
			.done(data => settingVariables(data))
			.done(updateColumns)
			.then(createGrid);

		$('#group-form').jqxValidator({ onSuccess: executeActionGroup });
		
		$(selector).on('rowdoubleclick', function (event) {
			let data = event.args.row.bounddata;
			if (data.status_id == 500) {
				let record = { 
					id: data.id, 
					parent: data.parent_id, 
					name: data.name 
				};

				$(selector).jqxGrid('source', createGridAdapter(master_dataset, { parent: data.id }));
			
				$('#breadcrumbs').breadcrumbs('push', record);
			}
		});

		$(selector).on('columnresized', function (event) {
			saveGridState(selector, grid_name, master_dataset);
		});
	}

	const createMenu = data => {
		for (item of data) {
			let menu_item = $('<li/>');
			if (item.command_id != null) {
				menu_item
					.attr('command', item.command_id)
					.attr('cmd_type', item.command_type);
			} else {
				menu_item
					.addClass('collapsed')
					.attr('data-toggle', 'collapse')
					.attr('data-target', `#${item.code}`)
			}

			let menu_ref = $('<a/>').attr('href', '#');
			let menu_image = $('<i/>').addClass(`fas fa-${item.fa_name} fa-lg fa-fw`);

			menu_ref.append(menu_image).append(item.name);
			if (item.command_id == null) {
				$('<span class="arrow"/>').appendTo(menu_ref);
			}

			menu_item.append(menu_ref);
			$('#exit-item').before(menu_item);

			if (('nodes' in item) && (item.nodes.length > 0)) {
				let sub_menu = $('<ul/>').addClass('sub-menu collapse').attr('id', item.code);
				for (subitem of item.nodes) {
					let li = $('<li/>');
					if (subitem.command_id != null) {
						li.attr('command', subitem.command_id).attr('type', subitem.command_type);
					}

					li.append($('<a/>').attr('href', '#').html(subitem.name));
					sub_menu.append(li);
				}

				$('#exit-item').before(sub_menu);
			}
		}

		$('#menu-content li[command]').click(function(event) {
			if ($(this).attr('type') == 'view_table') {
				$('#bd-master-table').empty();
				$('<div/>').attr('id', 'bd-master-grid').appendTo($('#bd-master-table'));

				createGridView('#bd-master-grid', $(this).attr('command'));
			}
		});
	}

	if (!localStorage.global_theme) {
		localStorage.global_theme = 'web';
	}

	$.getJSON('lib/get_submenu.php')
		.done(data => createMenu(data))
		.then(createColumnsWindow)
		.then(createGroupWindow)
		.then(createErrorWindow)
		.then(readPictures);
})(jQuery);