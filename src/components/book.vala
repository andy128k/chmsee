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

public class CsBook : VBox {
    public signal void model_changed(string filename);
    public signal void html_changed();

    public bool sidepane_visible {
        get {
            return control_notebook.visible;
        }
        set {
            if (value)
                control_notebook.show();
            else
                control_notebook.hide();
        }
    }
    public string? book_message { get; set; }

    private HPaned hpaned;
    private HBox findbar;
    private Entry find_entry;
    private ToggleButton find_case;

    private Notebook control_notebook;
    private Notebook html_notebook;

    private CsToc toc_page;
    private CsIndex index_page;
    private CsBookmarks bookmarks_page;

    private Gtk.ActionGroup action_group;
    private UIManager ui_manager;

    private CsChmfile? model;
    private CsHtmlWebkit? active_html;

    private string? context_menu_link;

    public CsBook() throws Error {
        hpaned = new HPaned();
        pack_start(hpaned, true, true, 0);

        control_notebook = new Notebook();
        control_notebook.tab_vborder = 4;
        control_notebook.set_show_border(false);
        hpaned.add1(control_notebook);

        html_notebook = new Notebook();
        html_notebook.switch_page.connect(html_notebook_switch_page_cb);
        html_notebook.tab_vborder = 0;
        html_notebook.set_show_border(false);
        hpaned.add2(html_notebook);

        /* string find bar */
        findbar = new HBox(false, 2);

        Button close_button = new Button();
        close_button.set_relief(ReliefStyle.NONE);
        Image close_image = new Image.from_stock(Stock.CLOSE, IconSize.SMALL_TOOLBAR);
        close_button.add(close_image);

        close_button.clicked.connect(on_findbar_hide);
        findbar.pack_start(close_button, false, false, 0);

        findbar.pack_start(new Label(_("Find:")), false, false, 0);

        find_entry = new Entry();
        findbar.pack_start(find_entry, false, false, 0);
        find_entry.changed.connect(find_entry_changed_cb);
        find_entry.activate.connect(find_entry_activate_cb);

        Button find_back = new Button.with_label(_("Previous"));
        find_back.set_relief(ReliefStyle.NONE);
        find_back.set_image(new Image.from_stock(Stock.GO_BACK, IconSize.SMALL_TOOLBAR));
        find_back.clicked.connect(on_findbar_back);
        findbar.pack_start(find_back, false, false, 0);

        Button find_forward = new Button.with_label(_("Next"));
        find_forward.set_relief(ReliefStyle.NONE);
        find_forward.set_image(new Image.from_stock(Stock.GO_FORWARD, IconSize.SMALL_TOOLBAR));
        find_forward.clicked.connect(on_findbar_forward);
        findbar.pack_start(find_forward, false, false, 0);

        find_case = new CheckButton.with_label(_("Match case"));
        findbar.pack_start(find_case, false, false, 0);

        pack_start(findbar, false, false, 0);

        /* HTML content popup menu */
        action_group = new Gtk.ActionGroup("BookActions");
        action_group.set_translation_domain("");

        Gtk.Action action;
        
        action = new Gtk.Action("Copy", N_("_Copy"), null, Stock.COPY);
        action.activate.connect(copy);
        action_group.add_action_with_accel(action, "<primary>C");

        action = new Gtk.Action("Back", N_("_Back"), null, Stock.GO_BACK);
        action.activate.connect(go_back);
        action_group.add_action_with_accel(action, "<alt>Left");

        action = new Gtk.Action("Forward", N_("_Forward"), null, Stock.GO_FORWARD);
        action.activate.connect(go_forward);
        action_group.add_action_with_accel(action, "<alt>Right");

        action = new Gtk.Action("OpenLinkInNewTab", N_("Open Link in New _Tab"), null, null);
        action.activate.connect(on_context_new_tab);
        action_group.add_action(action);

        action = new Gtk.Action("CopyLinkLocation", N_("_Copy Link Location"), null, null);
        action.activate.connect(on_context_copy_link);
        action_group.add_action(action);

        action = new Gtk.Action("SelectAll", N_("Select _All"), null, null);
        action.activate.connect(on_select_all);
        action_group.add_action(action);

        action = new Gtk.Action("CopyPageLocation", N_("Copy Page _Location"), null, null);
        action.activate.connect(on_copy_page_location);
        action_group.add_action(action);

        action_group.get_action("Back").set_sensitive(false);
        action_group.get_action("Forward").set_sensitive(false);

        ui_manager = new UIManager();
        ui_manager.insert_action_group(action_group, 0);

        string ui_description = """
            <ui>
              <popup name='HtmlContextLink'>
                <menuitem action='OpenLinkInNewTab' name='OpenLinkInNewTab'/>
                <menuitem action='CopyLinkLocation'/>
              </popup>
              <popup name='HtmlContextNormal'>
                <menuitem action='Back'/>
                <menuitem action='Forward'/>
                <menuitem action='SelectAll'/>
                <menuitem action='CopyPageLocation'/>
              </popup>
              <popup name='HtmlContextNormalCopy'>
                <menuitem action='Copy'/>
                <menuitem action='SelectAll'/>
                <menuitem action='CopyPageLocation'/>
              </popup>
            </ui>""";
        ui_manager.add_ui_from_string(ui_description, -1);

        set_homogeneous(false);
        show_all();
    }

    private void find_entry_changed_cb() {
        find_text();
    }

    private void find_entry_activate_cb() {
        find_text();
    }

    private void link_selected_cb(Link link) {
        if (0 == link.uri.ascii_casecmp(Configuration.NO_LINK) || link.uri.length == 0)
            return;

        string scheme = Uri.parse_scheme(link.uri);
        if (scheme != null && scheme != "file") {
            book_message = "URI %s with unsupported protocol: %s".printf(link.uri, scheme);
        } else {
            load_url(link.uri, false);
        }
    }

    private void html_notebook_switch_page_cb(NotebookPage page, uint new_page_num) {
        Widget new_page = html_notebook.get_nth_page((int)new_page_num);
        if (new_page != null) {
            active_html = (CsHtmlWebkit)new_page;
            reload_current_page();
        }
        html_changed();
    }

    private void html_location_changed_cb(string location) {
        html_changed();

        string scheme = Uri.parse_scheme(location);

        if (scheme == "file" && toc_page != null) {
            string real_uri = get_real_uri(location);
            string filename;
            try {
                filename = Filename.from_uri(real_uri);
            } catch (ConvertError e) {
                return;
            }

            string uri = get_short_uri(model, filename);
            string toc_uri = "%s%s".printf(uri, location.substring(real_uri.length));

            toc_page.sync(toc_uri);
        }
    }

    private bool html_open_uri_cb(string? full_uri) {
        if (full_uri == null || full_uri.length == 0)
            return true;

        string scheme = Uri.parse_scheme(full_uri);
        string bookfolder = model.bookfolder;

        if (scheme == "file") {
            /* DND chmfile check */
            if (full_uri.has_suffix(".chm") || full_uri.has_suffix(".CHM")) {
                model_changed(full_uri);
            } else if (full_uri.index_of(bookfolder) >= 0) {
                string uri = get_short_uri(model, full_uri);
                load_url(uri, true);
            }
        } else if (scheme == "about" || scheme == "jar") {
            return false;
        }

        return true;
    }

    private void html_title_changed_cb(CsHtmlWebkit html, string? title) {
        string label_text = _("No Title");
        if (title != null && title.length != 0)
            label_text = title;

        update_tab_title(active_html, label_text);

        /* update bookmarks title entry */
        string location = html.get_location();

        if (location != null && location.length != 0) {
            if (!location.has_prefix("about:")) {
                Link link = new Link(label_text, get_short_uri(model, location));
                bookmarks_page.set_current_link(link);
            }
        }
    }

    private void html_context_normal_cb() {
        bool can_copy = active_html.view.can_copy_clipboard();
        action_group.get_action("Copy").set_sensitive(can_copy);
        action_group.get_action("Back").set_sensitive(can_go_back());
        action_group.get_action("Forward").set_sensitive(can_go_forward());

        string pop_menu = can_copy ? "/HtmlContextNormalCopy" : "/HtmlContextNormal";
        Menu menu = (Menu)ui_manager.get_widget(pop_menu);
        menu.popup(null, null, null, 0, Gdk.CURRENT_TIME);
    }

    private void html_context_link_cb(string link) {
        set_context_menu_link(link);
        action_group.get_action("OpenLinkInNewTab").set_sensitive(context_menu_link.has_prefix("file://"));

        Menu menu = (Menu)ui_manager.get_widget("/HtmlContextLink");
        menu.popup(null, null, null, 0, Gdk.CURRENT_TIME);
    }

    private void html_open_new_tab_cb(string location) {
        new_tab_with_fulluri(location);
    }

    private void html_link_message_cb(string url) {
        book_message = url;
    }

    private void on_tab_close(CsHtmlWebkit html) {
        if (html_notebook.get_n_pages() >= 1) {
            int num = html_notebook.page_num(html);
            if (num >= 0)
                html_notebook.remove_page(num);
            update_tab_label_state();
        }
    }

    private void on_copy_page_location(Gtk.Action action) {
        string? location = active_html.get_location();
        Gdk.Atom selection = location != null ? Gdk.SELECTION_PRIMARY : Gdk.SELECTION_CLIPBOARD;
        Clipboard.get(selection).set_text(location, -1);
    }

    private void on_select_all(Gtk.Action action) {
        select_all();
    }

    private void on_context_new_tab(Gtk.Action action) {
        if (context_menu_link != null)
            new_tab_with_fulluri(context_menu_link);
    }

    private void on_context_copy_link(Gtk.Action action) {
        Gdk.Atom selection = context_menu_link != null ? Gdk.SELECTION_PRIMARY : Gdk.SELECTION_CLIPBOARD;
        Clipboard.get(selection).set_text(context_menu_link, -1);
    }

    private void on_findbar_hide() {
        findbar.hide();
    }

    private void on_findbar_back() {
        find_text(true);
    }

    private void on_findbar_forward() {
        find_text();
    }

    private int new_html_tab() {
        CsHtmlWebkit html = new CsHtmlWebkit();
        html.show();

        html.title_changed.connect(html_title_changed_cb);
        html.open_uri.connect(html_open_uri_cb);
        html.location_changed.connect(html_location_changed_cb);
        html.context_normal.connect(html_context_normal_cb);
        html.context_link.connect(html_context_link_cb);
        html.open_new_tab.connect(html_open_new_tab_cb);
        html.link_message.connect(html_link_message_cb);

        /* customized label, add a close button rightmost */
        Widget tab_label = new_tab_label(_("No Title"), html);

        int page_num = html_notebook.append_page(html, tab_label);
        html_notebook.set_tab_label_packing(html, true, true, PackType.START);

        return page_num;
    }

    private Widget new_tab_label(string str, CsHtmlWebkit html) {
        HBox hbox = new HBox(false, 2);

        Label label = new Label(str);
        label.set_ellipsize(Pango.EllipsizeMode.END);
        label.set_single_line_mode(true);
        label.set_alignment(0.0f, 0.5f);
        label.set_padding(0, 0);
        hbox.pack_start(label, true, true, 0);
        hbox.set_data("label", label);

        Button close_button = new Button();
        close_button.set_relief(ReliefStyle.NONE);
        close_button.set_border_width(0);

        Image close_image = new Image.from_stock(Stock.CLOSE, IconSize.MENU);
        close_image.set_padding(0, 0);
        close_button.set_image(close_image);

        close_button.clicked.connect(() => { on_tab_close(html); });

        hbox.pack_start(close_button, false, false, 0);

        hbox.show_all();

        return hbox;
    }

    private void update_tab_title(CsHtmlWebkit html, string title) {
        Label label = html_notebook.get_tab_label(html).get_data("label");
        label.set_text(title);
    }

    private void set_context_menu_link(string link) {
        context_menu_link = link;
    }

    private void find_text(bool backward=false) {
        bool mcase = find_case.get_active();
        string text = find_entry.get_text();
        if (backward && mcase && text.has_prefix("webkit:about:"))
            active_html.view.open(text.substring(6));
        else
            active_html.find(text, backward, mcase);
    }

    private void update_tab_label_state() {
        bool show = html_notebook.get_n_pages() > 1;
        html_notebook.set_show_tabs(show);
    }

    private string get_short_uri(CsChmfile chmfile, string uri) {
        string bookfolder = chmfile.bookfolder;

        int p = uri.last_index_of(bookfolder);
        string short_uri;
        if (p == -1)
            short_uri = uri;
        else
            short_uri = uri.substring(p + bookfolder.length);

        if (short_uri[0] == '/')
            short_uri = short_uri.substring(1);

        return short_uri;
    }

    private int get_toc_current() {
        ArrayList<Link> toc_list = model.toc_list;
        string location = active_html.get_location();
        string short_uri = get_short_uri(model, location);
        int result = -1;
        for (int i = 0; i < toc_list.size; ++i) {
            if (0 == ncase_compare_utf8_string(toc_list[i].uri, short_uri)) {
                result = i;
                break;
            }
        }
        return result;
    }

    public void set_model(CsChmfile model) throws Error {
        /* close opened book */
        if (this.model != null) {
            ArrayList<Link> old_list = bookmarks_page.get_model();
            model.update_bookmarks_list(old_list);

            /* remove all notebook page tab */
            int num = control_notebook.get_n_pages();
            for (int i = 0; i < num; i++)
                control_notebook.remove_page(-1);

            num = html_notebook.get_n_pages();
            for (int i = 0; i < num; i++)
                html_notebook.remove_page(-1);
        }

        this.model = model;

        if (active_html != null) {
            active_html.set_variable_font(model.variable_font);
            active_html.set_fixed_font(model.fixed_font);
        }

        int cur_page = 0;

        /* TOC */
        Link toc_tree = model.toc_tree;
        if (toc_tree != null) {
            toc_page = new CsToc();
            toc_page.set_model(toc_tree);
            cur_page = control_notebook.append_page(toc_page, new Label(_("Topics")));
            toc_page.link_selected.connect(link_selected_cb);
        }

        /* index */
        ArrayList<Link> index_list = model.index_list;
        if (index_list != null) {
            index_page = new CsIndex();
            index_page.set_model(index_list);
            cur_page = control_notebook.append_page(index_page, new Label(_("Index")));
            index_page.link_selected.connect(link_selected_cb);
        }

        /* bookmarks */
        ArrayList<Link> bookmarks_list = model.bookmarks_list;
        bookmarks_page = new CsBookmarks();
        bookmarks_page.set_model(bookmarks_list);
        cur_page = control_notebook.append_page(bookmarks_page, new Label(_("Bookmarks")));
        bookmarks_page.link_selected.connect(link_selected_cb);
        bookmarks_page.bookmarks_updated.connect(bookmarks_updated_cb);

        if (bookmarks_list.size == 0)
            cur_page = 0;

        control_notebook.set_current_page(cur_page);
        control_notebook.show_all();

        cur_page = new_html_tab();
        update_tab_label_state();

        html_notebook.set_current_page(cur_page);
        html_notebook.show_all();

        string page = model.page;
        if (page != "")
            load_url(page, true);
        else
            homepage();

        model_changed("");
    }

    public void load_url(string? uri, bool force_reload) {
        if (uri == null || uri.length == 0)
            return;

        /* Concatenate bookfolder and short uri */
        string pattern;
        if (uri[0] == '/')
            pattern = "file://%s%s";
        else
            pattern = "file://%s/%s";

        string full_uri = pattern.printf(model.bookfolder, uri);

        /* Check file exist */
        bool file_exist;
        string filename = "";
        try {
            string real_uri = get_real_uri(full_uri);
            filename = Filename.from_uri(real_uri);
            file_exist = FileUtils.test(filename, FileTest.EXISTS);

            if (!file_exist) {
                /* search again with case insensitive name */
                string found = file_exist_ncase(filename);
                if (found != "") {
                    full_uri = "file://%s%s".printf(found, full_uri.substring(real_uri.length));
                    file_exist = true;
                }
            }
        } catch (ConvertError e) {
            file_exist = false;
        }

        if (file_exist) {
            string location = active_html.get_location();
            if (force_reload || full_uri != location) {
                /* set user specified charset */
                string? charset = model.charset;
                if (charset != null && charset.length != 0)
                    active_html.set_charset(charset);

                SignalHandler.block_by_func(active_html, (void*)html_open_uri_cb, this);
                active_html.view.open(full_uri);
                SignalHandler.unblock_by_func(active_html, (void*)html_open_uri_cb, this);
            }
        } else {
            Dialog msg_dialog = new MessageDialog(null,
                                                  DialogFlags.MODAL,
                                                  MessageType.ERROR,
                                                  ButtonsType.CLOSE,
                                                  _("Can not find link target file at \"%s\""),
                                                  filename);
            msg_dialog.run();
        }
    }

    public void new_tab_with_fulluri(string? full_uri) {
        if (full_uri == null || full_uri.length == 0)
            return;

        string scheme = Uri.parse_scheme(full_uri);
        if (scheme != "file") {
            book_message = "URI %s with unsupported protocol: %s".printf(full_uri, scheme);
        } else {
            html_notebook.set_current_page(new_html_tab());
            update_tab_label_state();
            load_url(get_short_uri(model, full_uri), true);
        }
    }

    public void bookmarks_updated_cb(ArrayList<Link> links) {
        model.update_bookmarks_list(links);
    }

    public bool can_close_tab() {
        return html_notebook.get_n_pages() > 1;
    }

    public void close_current_tab() {
        if (html_notebook.get_n_pages() == 1)
            return;

        int page_num = html_notebook.get_current_page();
        if (page_num >= 0)
            html_notebook.remove_page(page_num);

        update_tab_label_state();
    }

    public void reload_current_page() {
        if (model != null) {
            string? charset = model.charset;
            if (charset != null && charset.length != 0)
                active_html.set_charset(charset);
            active_html.view.reload();
        }
    }

    public void homepage() {
        string? homepage = model.homepage;
        if (homepage != null)
            load_url(homepage, false);
    }

    public bool has_homepage() {
        return model.homepage != null;
    }

    public bool can_go_back() {
        return active_html.view.can_go_back();
    }

    public bool can_go_forward() {
        return active_html.view.can_go_forward();
    }

    public void go_back() {
        active_html.view.go_back();
    }

    public void go_forward() {
        active_html.view.go_forward();
    }

    public void go_prev() {
        int current = get_toc_current();
        ArrayList<Link> toc_list = model.toc_list;
        if (current > 0)
            load_url(toc_list[current - 1].uri, false);
    }

    public void go_next() {
        int current = get_toc_current();

        ArrayList<Link> toc_list = model.toc_list;
        if (current > 0 && current + 1 < toc_list.size)
            load_url(toc_list[current + 1].uri, false);
    }

    public void zoom_in() {
        active_html.increase_size();
    }

    public void zoom_out() {
        active_html.decrease_size();
    }

    public void zoom_reset() {
        active_html.reset_size();
    }

    public bool can_copy() {
        if (active_html != null)
            return active_html.view.can_copy_clipboard();
        else
            return false;
    }

    public void copy() {
        active_html.copy_selection();
    }

    public void select_all() {
        active_html.select_all();
    }

    public string get_location() {
        if (active_html != null)
            return active_html.get_location();
        else
            return "";
    }

    public int get_hpaned_position() {
        return hpaned.get_position();
    }

    public void set_hpaned_position(int position) {
        hpaned.set_position(position);
    }

    public void findbar_show() {
        findbar.show();
        find_entry.grab_focus();
    }

    public void findbar_hide() {
        findbar.hide();
    }
}

