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

public class CsBookmarks : VBox {
    public signal void link_selected(Link link);
    public signal void bookmarks_updated(ArrayList<Link> links);

    private CsTreeView treeview;
    private Entry entry;
    private Button add_button;
    private Button remove_button;

    private ArrayList<Link> links;
    private string? current_uri;

    public CsBookmarks() {
        current_uri = null;
        links = null;

        /* bookmarks list */
        Frame frame = new Frame(null);
        frame.set_shadow_type(ShadowType.NONE);

        ScrolledWindow sw = new ScrolledWindow(null, null);
        sw.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
        sw.set_shadow_type(ShadowType.NONE);

        treeview = new CsTreeView(false);
        treeview.link_selected.connect(link_selected_cb);

        sw.add(treeview);
        frame.add(sw);
        pack_start(frame, true, true, 0);

        /* bookmark title */
        entry = new Entry();
        entry.set_max_length(Configuration.ENTRY_MAX_LENGTH);
        entry.changed.connect(entry_changed_cb);

        pack_start(entry, false, false, 2);

        /* add and remove button */
        HBox hbox = new HBox(false, 0);

        add_button = new Button.from_stock(Stock.ADD);
        add_button.clicked.connect(on_bookmarks_add);

        remove_button = new Button.from_stock(Stock.REMOVE);
        remove_button.clicked.connect(on_bookmarks_remove);

        hbox.pack_end(add_button, true, true, 0);
        hbox.pack_end(remove_button, true, true, 0);

        pack_start(hbox, false, false, 2);

        set_spacing(2);

        show_all();
    }

    private void link_selected_cb(Link? link) {
        if (link != null)
            link_selected(link);
    }

    private void entry_changed_cb() {
        bool sensitive = entry.get_text().length > 2;
        add_button.set_sensitive(sensitive);
    }

    private void on_bookmarks_add() {
        if (current_uri == null)
            return;

        string name = entry.get_text();
        int index = find_link_by_uri(current_uri);

        if (index >= 0) {
            /* update exist bookmark name */
            Link link = links[index];
            if (ncase_compare_utf8_string(link.name, name) != 0) {
                treeview.remove_link(link);

                link.name = name;
                treeview.add_link(link);
            }
        } else {
            /* new bookmark */
            Link link = new Link(name, current_uri);
            links.add(link);

            treeview.add_link(link);
        }
        bookmarks_updated(links);
    }

    private void on_bookmarks_remove() {
        Link link = treeview.get_selected_link();
        if (link != null) {
            treeview.remove_link(link);

            int index = find_link_by_uri(link.uri);
            if (index >= 0) {
                links.remove_at(index);
                bookmarks_updated(links);
            }
        }
    }

    private int find_link_by_uri(string uri) {
        for (var i = 0; i < links.size; ++i) {
            if (0 == ncase_compare_utf8_string(links[i].uri, uri)) {
                return i;
            }
        }
        return -1;
    }

    public void set_model(ArrayList<Link> model) {
        links = model;
        treeview.set_links(model);
        entry.set_text("");
    }

    public ArrayList<Link> get_model() {
        return links;
    }

    public void set_current_link(Link link) {
        entry.set_text(link.name);
        entry.set_position(-1);
        entry.select_region(-1, -1);

        current_uri = link.uri;
    }

    public new void grab_focus() {
        entry.grab_focus();
    }
}

