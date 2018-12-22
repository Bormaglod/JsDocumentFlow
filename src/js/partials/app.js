/*(function($)
{
	let createColumnsWindow = () => {
		$('#columns-window').jqxWindow({ 
			resizable: true, 
			autoOpen: false, 
			width: 210, 
			height: 200,
			title: 'Колонки',
			theme: localStorage.global_theme
		});
	}

	let createGridView = (selector, cmd_id) => {
		$(selector).off();
		$('#group-window').off();

		let renderToolbar = statusbar => {

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

		let createGrid = () => {

			var addfilter = function () {
				var filtergroup = new $.jqx.filter();
				var filter_or_operator = 1;
				var filtervalue = 'Beate';
				var filtercondition = 'contains';
				var filter1 = filtergroup.createfilter('stringfilter', filtervalue, filtercondition);
				filtervalue = 'Andrew';
				filtercondition = 'starts_with';
				var filter2 = filtergroup.createfilter('stringfilter', filtervalue, filtercondition);

				filtergroup.addfilter(filter_or_operator, filter1);
				filtergroup.addfilter(filter_or_operator, filter2);
				// add the filters.
				$(selector).jqxGrid('addfilter', 'firstname', filtergroup);
				// apply the filters.
				$(selector).jqxGrid('applyfilters');
			}
		}
	}
})(jQuery);*/
(function($)
{
	let pictures;

	let saveGridState = (selector, name, dataset) => {
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

	let loadGridState = (name, dataset) => {
		let state = localStorage[name];
		if (state)
		{
			let jsonState = JSON.parse(state);
			for (let [index, value] of dataset.columns.entries()) {
				let column = jsonState.find(data => data.datafield == value.datafield);
				if (typeof column === 'undefined') continue;
				
				dataset.columns[index].hidden = column.hidden;
				dataset.columns[index].width = column.width;
			}
		}
	}

	let showErrorWindow = data => {
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

		dialogs.error(msg);
	}

	let createGridAdapter = (dataset, params) => {
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
			},
			deleterow: function (rowid, commit) {
        commit(true);
    	}
		}

		if (typeof params !== 'undefined') {
			$.extend(source.data, params);
		}
		
		return new $.jqx.dataAdapter(source);
	}

	let createGridView = (selector, cmd_id) => {
		let master_dataset;
		let detail_dataset;
		let grid_name;

		$(selector).off('rowdoubleclick');
		$(selector).off('columnresized');

		let settingVariables = data => {
			master_dataset = $.grep(data.schema_data.viewer.datasets, e => e.name == data.schema_data.viewer.master)[0];
			if ('detail' in data.schema_data.viewer) {
				detail_dataset = $.grep(data.schema_data.viewer.datasets, e => e.name == data.schema_data.viewer.detail)[0];
			}

			grid_name = selector.substring(4) + '-' + master_dataset.name;
		}

		let renderRecord = (datafield, value) => {
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

		let updateColumns = () => {
			for (let col of master_dataset.columns) {
				if (col.type == 'image') {
					col.cellsrenderer = (row, datafield, value) => { return renderRecord(datafield, value); }
				}
			}
		}

		let getCurrentRowInfo = () => {
			let selectedrowindex = $(selector).jqxGrid('getselectedrowindex');
			let rowscount = $(selector).jqxGrid('getdatainformation').rowscount;
			if (selectedrowindex >= 0 && selectedrowindex < rowscount) {
				return {
					data: $(selector).jqxGrid('getrowdata', selectedrowindex),
					rowid: $(selector).jqxGrid('getrowid', selectedrowindex),
					selected: selectedrowindex
				}
			}

			return null;
		}

		let createGroup = params => {
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

		let updateGroup = params => {
			$.post('lib/update_group.php', params)
				.done(data => {
					if (data.code == 0) {
						let info = getCurrentRowInfo();
						if (info != null && info.rowid >= 0)
						{
							$(selector).jqxGrid('updaterow', info.rowid, data.result);
							$(selector).jqxGrid('ensurerowvisible', info.selected);
						}

						$('#group-window').jqxWindow('close');
					}	else {
						showErrorWindow(data);
					}
				});
		}

		let deleteGroup = (rowid, data_id) => {
			$.post('lib/delete_group.php', { id: data_id })
				.done(data => {
				if (data.code == 0) {
					$(selector).jqxGrid('deleterow', rowid);
				} else {
					showErrorWindow(data);
				}
			});
		}

		let editRow = () => {
			let info = getCurrentRowInfo();
			if (info != null)
			{
				if (info.data.status_id == 500)
				{
					groupDialog.edit(info.data, updateGroup);
				}
			}
		}

		let deleteRow = () => {
			let info = getCurrentRowInfo();
			if (info != null) {
				if (info.data.status_id == 500) {
					dialogs.confirm('Удаление группы повлечет удаление всех вложенных групп. Продолжить?', result => {
						if (result) {
							deleteGroup(info.rowid, info.data.id);
						}
					});
				}
			}
		}

		let renderToolbar = statusbar => {
			statusbar.html('');
	
			let container = $('<div/>').attr('id', 'grid-toolbar').css({'overflow': 'hidden', 'position': 'relative', 'margin': '3px'});
			let buttons = $('<div/>').addClass('toolbar');

			let addButton = (name, title) => {
				let btn = $('<div/>').addClass('btn-left');
				btn.append($('<i/>').addClass('fas').addClass(`fa-${name}`));
				if (typeof title !== 'undefined') {
					btn.addClass('btn-text').append(title);
				}

				btn.appendTo(buttons).jqxButton({ height: 16, theme: localStorage.global_theme });
				
				return btn;
			}

			let addSeparator = () => {
				return $('<div/>').addClass('section-separator').appendTo(buttons);
			}

			addButton('redo-alt');
			addButton('columns');
			addSeparator();
			addButton('plus-square', 'Создать');
			addButton('pen-square', 'Изменить').click(editRow);
			addButton('minus-square', 'Удалить').click(deleteRow);
	
			if (master_dataset.info.has_group) {
				addSeparator();
				addButton('folder-plus', 'Создать группу').click(() => { groupDialog.create(createGroup) });
			}

			/*let buttonColumns = $('<div class="btn-right"><i class="fas fa-columns"></i></div>');
			buttons.append(buttonColumns);

			buttonColumns.jqxButton({  width: 16, height: 16, theme: localStorage.global_theme });*/

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

			/*buttonColumns.click(function (event) {
				let offset = buttonColumns.offset();
				$("#columns-window").jqxWindow('open');
				$("#columns-window").jqxWindow('move', offset.left - ($("#columns-window").width() - 26), offset.top + 29);
			});*/
	
			/*let table = $('<table/>');
	
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
	
				row.appendTo(table);*/
		}

		let createGrid = () => {
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
				filterable: true,
				autoshowfiltericon: true,
				pagesize: detail_dataset == null ? 20 : 10,
				theme: localStorage.global_theme,
				toolbarheight: toolbar_height,
				rendertoolbar: renderToolbar,
				/*ready: function () {
					addfilter();
				}*/
			});
		}

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

		let params = { id: cmd_id };

		$.post('lib/get_command.php', params)
			.done(data => settingVariables(data))
			.done(updateColumns)
			.then(createGrid);
	}

	let createMenu = data => {
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

	let readPictures = () => {
		params = { 
			select_sql: "select * from picture_select() where parent_id = get_constant('picture.status')::uuid" 
		}

		$.post('lib/select.php', params)
			.done(data => pictures = data);
	}

	if (!localStorage.global_theme) {
		localStorage.global_theme = 'web';
	}

	$.getJSON('lib/get_submenu.php')
	.done(data => createMenu(data))
	.then(readPictures);
})(jQuery);