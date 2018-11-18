(function($)
{
	var saveGridState = function(selector, prefix, dataset) {
		var states = [];
		$.each(dataset.columns, function(key, value) {
			var column = $(selector).jqxGrid('getcolumn', value.datafield);
			var c = new Object();
			c.datafield = column.datafield;
			c.hidden = column.hidden;
			if (value.width == 'auto')
				c.width = 'auto';
			else
				c.width = column.width;
			states.push(c);
		});

		localStorage[prefix + dataset.name] = JSON.stringify(states);
	}

	var loadGridState = function(prefix, dataset)
	{
		function getColumnByName(name) {
			return jsonState.filter(
				function(data) { return data.datafield == name }
			);
		}

		var state = localStorage[prefix + dataset.name];
		if (state)
		{
			var jsonState = JSON.parse(state);
			$.each(dataset.columns, function(key, value) {
				var column = getColumnByName(value.datafield);
				dataset.columns[key].hidden = column[0].hidden;
				dataset.columns[key].width = column[0].width;
			});
		}
	}

	if (!localStorage.global_theme)
		localStorage.global_theme = 'web';

	var createGridView = function(selector, source)
	{
		new $.jqx.dataAdapter(source, {
			autoBind: true,
			downloadComplete: function (data) {
				var cur_dataset = $.grep(data.schema_data.viewer.datasets, function (e) { 
					return e.name == data.schema_data.viewer.master;
				})[0];

				var gridAdapter = new $.jqx.dataAdapter({
					id: 'id',
					localdata: data.rows
				});

				var pagerrenderer = function () {
					var paginginfo = $(selector).jqxGrid('getpaginginformation');

					var element = $('<div class="bd-paginator-container"></div>');
					var paginator = $('<div id="bd-master-paginator"></div>');
					var pageservice = $('<div class="page-service"></div>');

					paginator.appendTo(element);
					pageservice.appendTo(element);
		
					paginator.pagination({
						items: data.total_rows,
						itemsOnPage: paginginfo.pagesize,
						cssStyle: 'light-theme',
						onPageClick: function (pageNumber) {
							$(selector).jqxGrid('gotopage', pageNumber - 1);
						}
					});

					var rowsPerPage = $('<div class="rows-per-page"></div>');
					pageservice.append(rowsPerPage);
					pageservice.append('<div style="float: right">Show rows:</div>');

					var div_input = $('<div style="float: right; margin: 0 5px"></div>');
					var pg_input = $('<input type="text" id="page-input" />');
					div_input.append(pg_input);
					pageservice.append(div_input);

					pageservice.append('<div style="float: right">Go to page:</div>');
					pg_input.jqxInput({ width: 40, height: 26, minLength: 1, theme: localStorage.global_theme });
				
					rowsPerPage.jqxDropDownList({ source: [ "5", "10", "20" ], width: 60, height: 26, autoDropDownHeight: true, theme: localStorage.global_theme });
					rowsPerPage.jqxDropDownList('selectItem', $(selector).jqxGrid('pagesize'));

					rowsPerPage.on('select', function (event)
					{     
						var args = event.args;
						   if (args) {
							$(selector).jqxGrid({ pagesize: parseInt(args.item.value) });
							$(selector + ' #bd-master-paginator').pagination('updateItemsOnPage', args.item.value);
						}
					});
		
					return element;
				}

				var prefix = selector.substring(4) + '-';
				loadGridState(prefix, cur_dataset);

				$(selector).jqxGrid('hideloadelement');
				$(selector).jqxGrid('beginupdate', true);
				$(selector).jqxGrid({
					source: gridAdapter,
					columns: cur_dataset.columns,
					width: '100%',
					pageable: true,
					autoheight: true,
					pagerrenderer: pagerrenderer,
					sortable: true,
					columnsresize: true,
					showtoolbar: true,
					theme: localStorage.global_theme,
					rendertoolbar: function (statusbar) {
						statusbar.html('');
						var container = $('<div id="gridToolbar" style="overflow: hidden; position: relative; margin: 3px;"></div>');
						var button = $('<div id="columnsButton" style="float: right;"><i class="fas fa-columns"></i></div>');

						container.append(button);
						statusbar.append(container);
						button.jqxButton({  width: 16, height: 16, theme: localStorage.global_theme });

						button.click(function (event) {
							var offset = button.offset();
							$("#columnsWindow").jqxWindow('open');
							$("#columnsWindow").jqxWindow('move', offset.left - ($("#columnsWindow").width() - 26), offset.top + 29);
						});

						var table = $('<table></table>');

						$.each(cur_dataset.columns, function(key, value) {
							var row = $('<tr></tr>');

							var checkedField = !value.hidden;

							var td = $('<td datafield="' + value.datafield + '"></td>').jqxCheckBox({ 
								width: 16,
								height: 16,
								checked: checkedField,
								locked: !value.hideable
							});
							td.appendTo(row);

							td.on('change', function (event) { 
								var checked = event.args.checked; 

								if (checked)
								{
									$(selector).jqxGrid('showcolumn', $(this).attr('datafield'));
								}
								else
								{
									$(selector).jqxGrid('hidecolumn', $(this).attr('datafield'));
								}

								saveGridState(selector, prefix, cur_dataset);
							});

							$('<td style="height: 24px">' + value.text + '</td>').appendTo(row);

							row.appendTo(table);
						});

						$('#columnsWindow').jqxWindow({ 
							resizable: true, 
							autoOpen: false, 
							width: 210, 
							height: 200,
							title: 'Колонки',
							content: table,
							theme: localStorage.global_theme
						});
					}
				});

				$(selector).jqxGrid('endupdate');

				$(selector).on("pagechanged", function (event) 
				{
					$(selector + ' #bd-master-paginator').pagination('drawPage', event.args.pagenum  + 1);
				});
			}
		});
	}

	$.getJSON('lib/get_submenu.php', function(data)
	{
		var items = [];
		$.each(data, function(i, item)
		{
			var li_top = '';
			if (item.command_id != null)
			{
				li_top = 'command="' + item.command_id + '" cmd_type="' + item.command_type + '"';
			}
			else
			{
				li_top = 'data-toggle="collapse" data-target="#' + item.code + '" class="collapsed"';
			}

			items.push('<li ' + li_top + '>');

			var img = '<i class="fas fa-' + item.fa_name + ' fa-lg fa-fw"></i>';
			var arrow = item.command_id != null ? '' : '<span class="arrow"></span>';

			items.push('<a href="#">' + img + item.name + arrow + '</a>');

			items.push('</li>');
			if (('nodes' in item) && (item.nodes.length > 0))
			{
				items.push('<ul class="sub-menu collapse" id="' + item.code + '">');
				$.each(item.nodes, function(i, subitem)
				{
					var cmd = subitem.command_id != null ? ' command="' + subitem.command_id + '" cmd_type="' + subitem.command_type + '"' : '';
					items.push('<li' + cmd + '><a href="#">' + subitem.name + '</a></li>');
				});

				items.push('</ul>');
			}
		});

		$('#dashboard-item').after(items.join(''));

		$('#menu-content li[command]').click(function()
		{
			if ($(this).attr('cmd_type') == 'view_table')
			{
				var cmd_id = '?id=' + $(this).attr('command');

				var source =
            	{
                	datatype: 'json',
                	url: 'lib/select.php' + cmd_id
				};

				createGridView('#bd-master-grid', source);
			}
		});
	});
})(jQuery);