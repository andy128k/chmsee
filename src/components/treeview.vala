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

using Gee;
using Gtk;

enum TreeColumns {
    COL_TITLE,
    COL_URI,
    N_COLUMNS
}

public class CsTreeView : TreeView {
    public signal void link_selected(Link link);

    private ListStore store;
    private TreeModel filter_model;
    private string filter_string;

    public CsTreeView(bool with_filter) {
        CellRendererText cell = new CellRendererText();
        cell.ellipsize = Pango.EllipsizeMode.END;

        insert_column_with_attributes(-1,
                                      "", cell,
                                      "text", 0,
                                      null);

        set_headers_visible(false);
        set_enable_search(false);
        set_search_column(0);

        TreeSelection selection = get_selection();
        selection.set_mode(SelectionMode.BROWSE);
        row_activated.connect(row_activated_cb);

        show_all();

        store = new ListStore(2, typeof(string), typeof(string));
        if (with_filter)
            apply_filter_model();
        else
            set_model(store);
    }

    private void row_activated_cb(TreePath path, TreeViewColumn column) {
        TreeModel model;
        TreeIter iter;

        if (filter_model != null)
            model = filter_model;
        else
            model = store;

        model.get_iter(out iter, path);
        string title, uri;
        model.get(iter,
                  TreeColumns.COL_TITLE, out title,
                  TreeColumns.COL_URI, out uri);

        Link link = new Link(title, uri);

        link_selected(link);
    }

    private bool visible_func(TreeModel model, TreeIter iter) {
        if (filter_string == null || filter_string.length == 0)
            return true;

        string text;
        bool visible = false;

        model.get(iter, TreeColumns.COL_TITLE, out text);

        if (text != null) {
            string case_normalized_string = text.normalize(-1, NormalizeMode.ALL).casefold();
            if (0 == filter_string.ascii_ncasecmp(case_normalized_string, filter_string.length))
                visible = true;
        }

        return visible;
    }

    private void apply_filter_model() {
        filter_model = new TreeModelFilter(store, null);
        ((TreeModelFilter)filter_model).set_visible_func(visible_func);
        set_model(filter_model);
    }

    public void set_links(ArrayList<Link> model) {
        if (store != null)
            store.clear();

        TreeIter iter = TreeIter();
        foreach (Link link in model) {
            store.append(out iter);
            store.set(iter,
                      TreeColumns.COL_TITLE, link.name,
                      TreeColumns.COL_URI, link.uri);
        }
    }

    public void add_link(Link link) {
        TreeIter iter;
        store.append(out iter);
        store.set(iter,
                  TreeColumns.COL_TITLE, link.name,
                  TreeColumns.COL_URI, link.uri);
    }

    public void remove_link(Link link) {
        TreeIter iter;
        string uri;

        store.get_iter_from_string(out iter, "0");
        do {
            store.get(iter, TreeColumns.COL_URI, out uri);

            if (ncase_compare_utf8_string(link.uri, uri) == 0) {
                store.remove(iter);
                break;
            }
        } while (store.iter_next(ref iter));
    }

    public Link? get_selected_link() {
        TreeSelection selection = get_selection();

        TreeIter iter;
        if (selection.get_selected(null, out iter)) {
            string title, uri;
            store.get(iter,
                      TreeColumns.COL_TITLE, out title,
                      TreeColumns.COL_URI, out uri);

            return new Link(title, uri);
        } else {
            return null;
        }
    }

    public void select_link(Link link) {
        TreeSelection selection = get_selection();

        TreeIter iter;
        string uri;

        store.get_iter_from_string(out iter, "0");
        do {
            store.get(iter, TreeColumns.COL_URI, out uri);

            if (ncase_compare_utf8_string(link.uri, uri) == 0) {
                selection.select_iter(iter);
                break;
            }
        } while (store.iter_next(ref iter));
    }

    public void set_filter_string(string str) {
        if (filter_model == null)
              return;

        filter_string = str;
        ((TreeModelFilter)filter_model).refilter();
    }
}

