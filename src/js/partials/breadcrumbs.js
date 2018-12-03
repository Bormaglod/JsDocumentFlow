(function( $ ) {
    var methods = {
        init : function(options) { 
            options = $.extend({
                current: 'top',
                onSelect: parent => { }
            }, options);

            let crumbs = $('<ul class="crumbs"><li><i style="line-height: inherit" class="fas fa-home fa-fw"></i></li></ul>');
            $(this).append(crumbs);
            $(this).data('breadcrumbs', options);
            return this;
        },
        push : function(record) {
            let last = $('.crumbs').children().last();
            last.wrapInner('<a href="#" parent="' + record['parent'] + '"></a>');
            $('.crumbs').append('<li><span>' + record['name'] + '</span></li>');

            $(this).data('breadcrumbs').current = record.id;

            let self = this;
            last.on('click', function(event) {
                let ref = $(this).find('a');
                return methods.select.call(self, ref.attr('parent'));
            });
        },
        select : function(record_id) {
            if (!record_id)
                return;

            while (true) {
                let last = $('.crumbs').children().last();
                let ref = last.find('a');
                if (ref.length) {
                    let ref_parent = ref.attr('parent');
                    if (ref_parent && ref_parent == record_id) {
                        last.append(ref.detach().html());
                        break;
                    }
                }

                last.remove();
            }

            let options = $(this).data('breadcrumbs');
            options.current = record_id == 'null' ? 'top' : record_id;
            options.onSelect(record_id);
        },
        current : function() {
            return $(this).data('breadcrumbs').current;
        }
    }

    $.fn.breadcrumbs = function(method) {
        if (methods[method]) {
            return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
        }
        else 
            if (typeof method === 'object' || ! method) {
                return methods.init.apply(this, arguments);
            } else {
                $.error(`Метод с именем ${method} не существует для jQuery.breadcrumbs`);
            } 
    };
  })(jQuery);