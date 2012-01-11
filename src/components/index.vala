/*
 *  Copyright (C) 2012 Andrey Kutejko <andy128k@gmail.com>
 *
 *  ChmSee is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2, or (at your option)
 *  any later version.

 *  ChmSee is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with ChmSee; see the file COPYING.  If not, write to
 *  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 */

using GLib;
using Gee;
using Gtk;

class CsIndex : VBox {
    public signal void link_selected(Link link);

    private CsTreeView treeview;
    private Entry filter_entry;

    public CsIndex() {
        filter_entry = new Entry();
        filter_entry.set_max_length(Configuration.ENTRY_MAX_LENGTH);
        filter_entry.changed.connect(filter_changed_cb);

        pack_start(filter_entry, false, false, 0);

        ScrolledWindow sw = new ScrolledWindow(null, null);
        sw.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
        sw.set_shadow_type(ShadowType.NONE);

        treeview = new CsTreeView(true);
        treeview.link_selected.connect(link_selected_cb);

        sw.add(treeview);
        pack_start(sw, true, true, 0);

        show_all();
    }

    private void link_selected_cb(Link link) {
        link_selected(link);
    }

    private void filter_changed_cb() {
        treeview.set_filter_string(filter_entry.get_text());
    }

    public void set_model(ArrayList<Link> model) {
        filter_entry.set_text("");
        treeview.set_links(model);
    }
}

