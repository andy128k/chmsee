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

enum TocColumns {
    COL_OPEN_PIXBUF,
    COL_CLOSED_PIXBUF,
    COL_TITLE,
    COL_LINK,
}

public class CsToc : VBox {
    public signal void link_selected(Link link);

    private Gdk.Pixbuf pixbuf_opened;
    private Gdk.Pixbuf pixbuf_closed;
    private Gdk.Pixbuf pixbuf_doc;

    private TreeView treeview;
    private TreeStore store;

    public CsToc() throws Error {
        ScrolledWindow sw = new ScrolledWindow(null, null);
        sw.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
        sw.set_shadow_type(ShadowType.NONE);

        treeview = new TreeView();
        store = new TreeStore(4, typeof(Gdk.Pixbuf), typeof(Gdk.Pixbuf), typeof(string), typeof(string));

        treeview.set_model(store);

        treeview.set_headers_visible(false);
        treeview.set_enable_search(false);

        pixbuf_closed = new Gdk.Pixbuf.from_file(RESOURCE_FILE("book-closed.png"));
        pixbuf_opened = new Gdk.Pixbuf.from_file(RESOURCE_FILE("book-open.png"));
        pixbuf_doc    = new Gdk.Pixbuf.from_file(RESOURCE_FILE("helpdoc.png"));

        TreeViewColumn column = new TreeViewColumn();
        CellRenderer cell = new CellRendererPixbuf();

        column.pack_start(cell, false);
        column.set_attributes(cell,
                              "pixbuf", TocColumns.COL_OPEN_PIXBUF,
                              "pixbuf-expander-open", TocColumns.COL_OPEN_PIXBUF,
                              "pixbuf-expander-closed", TocColumns.COL_CLOSED_PIXBUF);

        CellRendererText textcell = new CellRendererText();
        textcell.ellipsize = Pango.EllipsizeMode.END;

        column.pack_start(textcell, true);
        column.set_attributes(textcell,
                              "text", TocColumns.COL_TITLE);

        treeview.append_column(column);

        treeview.get_selection().set_mode(SelectionMode.BROWSE);

        treeview.row_activated.connect(row_activated_cb);
        treeview.cursor_changed.connect(cursor_changed_cb);

        sw.add(treeview);
        pack_start(sw, true, true, 0);

        show_all();
    }

    private void row_activated_cb(TreePath path, TreeViewColumn column) {
        if (treeview.is_row_expanded(path))
            treeview.collapse_row(path);
        else
            treeview.expand_row(path, false);
    }

    private void cursor_changed_cb() {
        TreeSelection selection = treeview.get_selection();

        TreeIter iter;
        if (selection.get_selected(null, out iter)) {
            string name, uri;
            store.get(iter,
                      TocColumns.COL_TITLE, out name,
                      TocColumns.COL_LINK, out uri);
            Link link = new Link(name, uri);
            link_selected(link);
        }
    }

    private void insert_node(Link link, TreeIter? parent_iter) {
        TreeIter iter;
        store.append(out iter, parent_iter);

        if (link.type() == LinkType.BOOK) {
            store.set(iter,
                      TocColumns.COL_OPEN_PIXBUF, pixbuf_opened,
                      TocColumns.COL_CLOSED_PIXBUF, pixbuf_closed,
                      TocColumns.COL_TITLE, link.name,
                      TocColumns.COL_LINK, link.uri);

            foreach (Link child in link.children) {
                insert_node(child, iter);
            }
        } else {
            store.set(iter,
                      TocColumns.COL_OPEN_PIXBUF, pixbuf_doc,
                      TocColumns.COL_CLOSED_PIXBUF, pixbuf_doc,
                      TocColumns.COL_TITLE, link.name,
                      TocColumns.COL_LINK, link.uri);
        }
    }

    class FindURI {
        public string uri;
        public bool found;
        public TreeIter iter;
        public TreePath path;

        public FindURI(string anUri) {
            found = false;
            if (anUri[0] == '/')
                uri = anUri.substring(1);
            else
                uri = anUri;
        }

        public bool find_uri_foreach(TreeModel model, TreePath path, TreeIter iter) {
            string link_uri;
            model.get(iter, TocColumns.COL_LINK, out link_uri);

            if (0 == ncase_compare_utf8_string(uri, link_uri)) {
                found = true;
                this.iter = iter;
                this.path = path;
            }

            return found;
        }
    }

    public void set_model(Link link) {
        store.clear();
        foreach (Link child in link.children) {
            insert_node(child, null);
        }
    }

    public void sync(string uri) {
        FindURI data = new FindURI(uri);
        store.foreach(data.find_uri_foreach);
        if (!data.found) {
            data.uri = get_real_uri(uri);
            store.foreach(data.find_uri_foreach);
        }

        if (!data.found) {
            return;
        }

        SignalHandler.block_by_func(treeview, (void*)cursor_changed_cb, this);

        treeview.expand_to_path(data.path);
        treeview.set_cursor(data.path, null, false);

        SignalHandler.unblock_by_func(treeview, (void*)cursor_changed_cb, this);
    }
}

