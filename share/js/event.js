t2hui.event_classes = {
    tags_seen:      {},
    facets_seen:    {},
    tags:           [],
    facets:         [],
    tag_watchers:   [],
    facet_watchers: [],
};

t2hui.build_event = function(e, options) {
    var len = e.lines.length;

    if (options === undefined) {
        options = {};
    }

    var eclass = "";

    if (e.is_orphan || options.is_orphan) {
        eclass = eclass + " orphan";
    }
    if (e.nested) {
        eclass = eclass + " nested";
    }

    var st_width = 3 + (2 * e.nested);

    var ebreak  = $('<div class="event_break"></div>');
    var econt   = $('<div class="event_controls"></div>');
    var econt_i = $('<div class="event_controls_inner"></div>');
    var ftoggle = $('<div class="etoggle">F</div>');
    ftoggle.click(function() {
        $('#modal_body').jsonView(e.facets, {collapsed: true});
        $('#free_modal').slideDown();
    });
    econt_i.append(ftoggle);
    econt.append(econt_i);

    var etoggle;
    if (e.is_parent) {
        etoggle = $('<div class="etoggle subtest"></div>');

        etoggle.one('click', function() {
            etoggle.toggleClass('clicked');

            var last = $(me.slice(-1)[0]);
            var uri = base_uri + 'event/' + e.event_id + '/events';
            t2hui.fetch(uri, {done: function() { etoggle.remove() } }, function(e2) {
                var sub_e = t2hui.build_event(e2, {is_orphan: e.is_orphan});
                last.after(sub_e);
                last = $(sub_e.slice(-1)[0]);
            });
        });
    }

    var me = [ebreak[0], econt[0]];

    var toggle_added = false;

    if (len) {
        for (var i = 0; i < len; i++) {
            var line = e.lines[i];
            var facet = line[0];
            var tag = line[1];
            var content = line[2];

            if (content !== null && typeof(content) === 'object') {
                var data = content;
                content = $('<div class="open_event_json">* JSON, click here to open *</div>');

                content.click(function() {
                    $('#modal_body').jsonView(data, {collapsed: true});
                    $('#free_modal').slideDown();
                });
            }

            var et = null;
            if (etoggle && !toggle_added && facet === 'assert') {
                toggle_added = true;
                et = etoggle;
            }

            var cls = 'facet_' + t2hui.sanitize_class(facet) + ' tag_' + t2hui.sanitize_class(tag);
            var row = t2hui.build_event_flesh(facet, tag, content, st_width, et);
            $(row).addClass(cls);

            me = $.merge(me, row);
        }
    }

    var row = t2hui.build_event_flesh('', 'EVENT ID', e.event_id, st_width, (toggle_added ? null : etoggle));
    $(row).addClass('tag_EVENT-ID');
    me = $.merge(me, row);

    if (eclass) { $(me).addClass(eclass) }

    return me;
};

t2hui.build_event_flesh = function(facet, tag, text, st_width, st_toggle) {
    if (!t2hui.event_classes.tags_seen[tag]) {
        t2hui.event_classes.tags_seen[tag] = 1;
        t2hui.event_classes.tags.push(tag);
        t2hui.event_classes.tags.sort;
        $(t2hui.event_classes.tag_watchers).each(function() { this() })
    }
    if (facet && !t2hui.event_classes.facets_seen[facet]) {
        t2hui.event_classes.facets_seen[facet] = 1;
        t2hui.event_classes.facets.push(facet);
        t2hui.event_classes.facets.sort;
        $(t2hui.event_classes.facet_watchers).each(function() { this() })
    }

    var lbrace  = $('<div class="event_lbrace"></div>');
    var etag    = $('<div class="event_tag">' + tag + '</div>');
    var rbrace  = $('<div class="event_rbrace"></div>');
    var cwrap   = $('<div class="event_c_wrap"></div>');
    var stgap   = $('<div class="event_st_gap" style="width: ' + st_width + 'ch;"></div>');
    var content = $('<div class="event_content"></div>');

    content.append(text);
    cwrap.append(stgap, content);
    if (st_toggle) { stgap.append(st_toggle) }

    var me = [lbrace[0], etag[0], rbrace[0], cwrap[0]];

    return me;
}
