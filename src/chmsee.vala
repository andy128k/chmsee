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
using Gtk;

[Compact]
public class CsConfig {
    public string home;
    public string bookshelf;
    public string last_file;
    public string charset;
    public string variable_font;
    public string fixed_font;

    public int pos_x;
    public int pos_y;
    public int height;
    public int width;
    public int hpaned_pos;
    public bool fullscreen;
    public bool startup_lastfile;
}

enum CsState {
    INIT,    /* init state, no book is loaded */
    LOADING, /* loading state, don't pop up an error window when open homepage failed */
    NORMAL   /* normal state, one book is loaded */
}

class Chmsee : Window {
    private HandleBox menubar;
    private HandleBox toolbar;
    private CsBook book;
    private Statusbar statusbar;

    private CsChmfile chmfile;
    private unowned CsConfig config;

    private Gtk.ActionGroup action_group;
    private UIManager ui_manager;
    private uint scid_default;
    private new CsState state;

    public bool startup_lastfile {
        get {
            return config.startup_lastfile;
        }
        set {
            config.startup_lastfile = value;
        }
    }

    public string variable_font {
        get {
            if (chmfile != null)
                return chmfile.settings.variable_font;
            else
                return config.variable_font;
        }
        set {
            if (chmfile != null)
                chmfile.settings.variable_font = value;
            else
                config.variable_font = value;
        }
    }

    public string fixed_font {
        get {
            if (chmfile != null)
                return chmfile.settings.fixed_font;
            else
                return config.fixed_font;
        }
        set {
            if (chmfile != null)
                chmfile.settings.fixed_font = value;
            else
                config.fixed_font = value;
        }
    }

    public string charset {
        get {
            if (chmfile != null)
                return chmfile.settings.charset;
            else
                return config.charset;
        }
        set {
            if (chmfile != null) {
                chmfile.settings.charset = value;
                book.reload_current_page();
            } else {
                config.charset = value;
            }
        }
    }

    public Chmsee(CsConfig aConfig) throws Error {
        chmfile = null;
        state = CsState.INIT;

        add_events(Gdk.EventMask.STRUCTURE_MASK | Gdk.EventMask.BUTTON_PRESS_MASK);
        window_state_event.connect(window_state_event_cb);

        drag_dest_set(this,
            DestDefaults.ALL,
            new TargetEntry[] { TargetEntry() { target = "text/uri-list", flags = 0, info = 0 } },
            Gdk.DragAction.COPY);

        delete_event.connect(delete_cb);

        populate_windows();

        config = aConfig;

        if (config.pos_x >= 0 && config.pos_y >= 0)
            move(config.pos_x, config.pos_y);

        if (config.width <= 0 || config.height <= 0) {
            config.width = Configuration.DEFAULT_WIDTH;
            config.height = Configuration.DEFAULT_HEIGHT;
        }
        resize(config.width, config.height);

        set_title("ChmSee");
        set_icon_from_file(RESOURCE_FILE("chmsee-icon.png"));

        book.set_hpaned_position(config.hpaned_pos);
        set_sidepane_state(false);

        configure_event.connect(configure_event_cb);
    }

    private bool delete_cb(Gdk.Event event) {
        on_quit();
        return true;
    }

    private bool window_state_event_cb(Gdk.EventWindowState event) {
        if ((event.changed_mask & Gdk.WindowState.FULLSCREEN) != 0) {
            if ((event.new_window_state & Gdk.WindowState.FULLSCREEN) != 0) {
                if (config.fullscreen) {
                    config.fullscreen = true;
                    menubar.hide();
                    toolbar.hide();
                    statusbar.hide();
                } else {
                    set_fullscreen(false);
                    return true;
                }
            } else {
                if (!config.fullscreen) {
                    config.fullscreen = false;
                    menubar.show();
                    toolbar.show();
                    statusbar.show();
                } else {
                    set_fullscreen(true);
                    return true;
                }
            }
        }

        return false;
    }

    private bool configure_event_cb(Gdk.EventConfigure event) {
        if (!config.fullscreen) {
            config.width  = event.width;
            config.height = event.height;
            config.pos_x  = event.x;
            config.pos_y  = event.y;
        }
        return false;
    }

    private string[] active_actions() {
        return new string[] {
            "NewTab", "CloseTab", "SelectAll", "Home", "Find", "SidePane",
            "ZoomIn", "ZoomOut", "ZoomReset", "Back", "Forward", "Prev", "Next"
        };
    }

    private void book_model_changed_cb(string filename) {
        bool has_model = chmfile != null;

        foreach (string action in active_actions()) {
            action_group.get_action(action).set_sensitive(has_model);
        }

        book.set_sensitive(has_model);

        if (filename.has_prefix("file://") && (filename.has_suffix(".chm") || filename.has_suffix(".CHM"))) {
            open_draged_file(filename);
        }
    }

    private void book_html_changed_cb() {
        action_group.get_action("Home").set_sensitive(book.has_homepage());
        action_group.get_action("Back").set_sensitive(book.can_go_back());
        action_group.get_action("Forward").set_sensitive(book.can_go_forward());
    }

    private void on_open_file() {
        try {
            /* create open file dialog */
            Builder builder = new Builder();
            builder.add_from_file(RESOURCE_FILE("openfile-dialog.ui"));

            FileChooserDialog dialog = (FileChooserDialog)builder.get_object("openfile_dialog");

            dialog.response.connect(
                (response_id) => {
                    string? filename = null;
                    if (response_id == ResponseType.OK)
                        filename = dialog.get_filename();

                    dialog.destroy();

                    if (filename != null) {
                        open_file(filename);
                    }
                });

            /* file list fiter */
            FileFilter filter;
            filter = new FileFilter();
            filter.set_name(_("CHM Files"));
            filter.add_pattern("*.[cC][hH][mM]");
            dialog.add_filter(filter);

            filter = new FileFilter();
            filter.set_name(_("All Files"));
            filter.add_pattern("*");
            dialog.add_filter(filter);

            /* previous opened file folder */
            string last_dir;
            if (config.last_file != "")
                last_dir = Path.get_dirname(config.last_file);
            else
                last_dir = Environment.get_home_dir();

            dialog.set_current_folder(last_dir);
        } catch (Error e) {
            // TODO: show error
        }
    }

    private void on_recent_files(RecentChooser chooser) {
        string? uri = chooser.get_current_uri();
        if (uri != null) {
            try {
                string filename = Filename.from_uri(uri);
                open_file(filename);
            } catch (ConvertError e) {
                // TODO: show error
            }
        }
    }

    private void on_copy() {
        book.copy();
    }

    private void on_select_all() {
        book.select_all();
    }

    private void on_setup() {
        try {
            setup_window_new(this);
        } catch (Error e) {
            // TODO: show error
        }
    }

    private void on_back() {
        book.go_back();
    }

    private void on_forward() {
        book.go_forward();
    }

    private void on_prev() {
        book.go_prev();
    }

    private void on_next() {
        book.go_next();
    }

    private void on_menu_file() {
        action_group.get_action("CloseTab").set_sensitive(book.can_close_tab());
    }

    private void on_menu_edit() {
        action_group.get_action("Copy").set_sensitive(book.can_copy());
    }

    private void on_home() {
        book.homepage();
    }

    private void on_zoom_in() {
        book.zoom_in();
    }

    private void on_zoom_out() {
        book.zoom_out();
    }

    private void on_zoom_reset() {
        book.zoom_reset();
    }

    private void on_about() {
        try {
            Builder builder = new Builder();
            builder.add_from_file(RESOURCE_FILE("about-dialog.ui"));

            AboutDialog dialog = (AboutDialog)builder.get_object("about_dialog");

            dialog.response.connect(
                (response_id) => {
                    if (response_id == ResponseType.CANCEL)
                        dialog.destroy();
                });

            dialog.set_version(Configuration.PACKAGE_VERSION);
        } catch (Error e) {
            // TODO show error
        }
    }

    private void on_open_new_tab() {
        string location = book.get_location();
        book.new_tab_with_fulluri(location);
    }

    private void on_close_current_tab(Gtk.Action action) {
        book.close_current_tab();
    }

    private void on_keyboard_escape(Gtk.Action action) {
        book.findbar_hide();
    }

    private void on_fullscreen_toggled(Gtk.Action action) {
        set_fullscreen(((ToggleAction)action).active);
    }

    private void on_sidepane_toggled(Gtk.Action action) {
        set_sidepane_state(((ToggleAction)action).active);
    }

    private void on_find() {
        book.findbar_show();
    }

    private void on_quit() {
        config.hpaned_pos = book.get_hpaned_position();

        if (chmfile != null) {
            /* save last opened page */
            string bookfolder = chmfile.bookfolder;

            string location = book.get_location();
            int p = location.last_index_of(bookfolder);
            if (p >= 0) {
                string page = location.substring(p + bookfolder.length);
                config.last_file = "%s::%s".printf(config.last_file, page);
            }
        }

        destroy();
        main_quit();
    }

    public override void drag_data_received(Gdk.DragContext context, int x, int y,
                   SelectionData selection_data, uint info, uint time) {
        var uris = selection_data.get_uris();
        if (uris == null) {
            drag_finish(context, false, false, time);
            return;
        }

        foreach (string uri in uris) {
            if (uri.has_prefix("file://") && (uri.has_suffix(".chm") || uri.has_suffix(".CHM"))) {
                open_draged_file(uri);
                break;
            }
        }

        drag_finish(context, true, false, time);
    }

    private void open_draged_file(string file) {
        string fname = Uri.unescape_string(file.substring(7)); // +7 remove "file://" prefix
        open_file(fname);
    }

    private void populate_windows() throws Error {
        VBox vbox = new VBox(false, 2);

        action_group = new Gtk.ActionGroup("MenuActions");
        action_group.set_translation_domain("");

        Gtk.Action action;
        
        action = new Gtk.Action("FileMenu", N_("_File"), null, null);
        action.activate.connect(on_menu_file);
        action_group.add_action(action);

        action = new Gtk.Action("EditMenu", N_("_Edit"), null, null);
        action.activate.connect(on_menu_edit);
        action_group.add_action(action);

        action = new Gtk.Action("ViewMenu", N_("_View"), null, null);
        action_group.add_action(action);

        action = new Gtk.Action("HelpMenu", N_("_Help"), null, null);
        action_group.add_action(action);

        action = new Gtk.Action("Open", N_("_Open"), null, Stock.OPEN);
        action.activate.connect(on_open_file);
        action_group.add_action_with_accel(action, "<primary>O");

        action = new Gtk.Action("RecentFiles", N_("_Recent Files"), null, null);
        action_group.add_action(action);

        action = new Gtk.Action("NewTab", N_("New _Tab"), null, null);
        action.activate.connect(on_open_new_tab);
        action_group.add_action_with_accel(action, "<primary>T");

        action = new Gtk.Action("CloseTab", N_("_Close Tab"), null, null);
        action.activate.connect(on_close_current_tab);
        action_group.add_action_with_accel(action, "<primary>W");

        action = new Gtk.Action("Exit", N_("E_xit"), null, Stock.QUIT);
        action.activate.connect(on_quit);
        action_group.add_action_with_accel(action, "<primary>Q");

        action = new Gtk.Action("Copy", N_("_Copy"), null, null);
        action.activate.connect(on_copy);
        action_group.add_action(action);

        action = new Gtk.Action("SelectAll", N_("Select _All"), null, null);
        action.activate.connect(on_select_all);
        action_group.add_action(action);

        action = new Gtk.Action("Find", N_("_Find"), null, Stock.FIND);
        action.activate.connect(on_find);
        action_group.add_action_with_accel(action, "<primary>F");

        action = new Gtk.Action("Preferences", N_("_Preferences"), null, Stock.PREFERENCES);
        action.activate.connect(on_setup);
        action_group.add_action(action);

        action = new Gtk.Action("Home", N_("_Home"), null, Stock.HOME);
        action.activate.connect(on_home);
        action_group.add_action(action);

        action = new Gtk.Action("Back", N_("_Back"), null, Stock.GO_BACK);
        action.activate.connect(on_back);
        action_group.add_action_with_accel(action, "<alt>Left");

        action = new Gtk.Action("Forward", N_("_Forward"), null, Stock.GO_FORWARD);
        action.activate.connect(on_forward);
        action_group.add_action_with_accel(action, "<alt>Right");

        action = new Gtk.Action("Prev", N_("_Prev"), null, Stock.GO_UP);
        action.activate.connect(on_prev);
        action_group.add_action_with_accel(action, "<primary>Up");

        action = new Gtk.Action("Next", N_("_Next"), null, Stock.GO_DOWN);
        action.activate.connect(on_next);
        action_group.add_action_with_accel(action, "<primary>Down");

        action = new Gtk.Action("About", N_("_About"), N_("About ChmSee"), Stock.ABOUT);
        action.activate.connect(on_about);
        action_group.add_action(action);

        action = new Gtk.Action("ZoomIn", N_("Zoom _In"), null, Stock.ZOOM_IN);
        action.activate.connect(on_zoom_in);
        action_group.add_action_with_accel(action, "<primary>plus");

        action = new Gtk.Action("ZoomReset", N_("_Normal Size"), null, Stock.ZOOM_100);
        action.activate.connect(on_zoom_reset);
        action_group.add_action_with_accel(action, "<primary>0");

        action = new Gtk.Action("ZoomOut", N_("Zoom _Out"), null, Stock.ZOOM_OUT);
        action.activate.connect(on_zoom_out);
        action_group.add_action_with_accel(action, "<primary>minus");

        action = new Gtk.Action("OnKeyboardEscape", null, null, null);
        action.activate.connect(on_keyboard_escape);
        action_group.add_action_with_accel(action, "Escape");

        action = new Gtk.Action("OnKeyboardControlEqual", null, null, null);
        action.activate.connect(on_zoom_in);
        action_group.add_action_with_accel(action, "<primary>equal");

        action = new Gtk.ToggleAction("FullScreen", N_("Full _Screen"), "Switch between fullscreen and window mode", null);
        action.activate.connect(on_fullscreen_toggled);
        action_group.add_action_with_accel(action, "F11");

        action = new Gtk.ToggleAction("SidePane", N_("Side _Pane"), null, null);
        action.activate.connect(on_sidepane_toggled);
        action_group.add_action_with_accel(action, "F9");

        foreach (string a in active_actions()) {
            action_group.get_action(a).set_sensitive(false);
        }

        ui_manager = new UIManager();
        ui_manager.insert_action_group(action_group, 0);

        add_accel_group(ui_manager.get_accel_group());

        string ui_description = """
            <ui>
              <menubar name='MainMenu'>
                <menu action='FileMenu'>
                  <menuitem action='Open'/>
                  <menuitem action='RecentFiles'/>
                  <separator/>
                  <menuitem action='NewTab'/>
                  <menuitem action='CloseTab'/>
                  <separator/>
                  <menuitem action='Exit'/>
                </menu>
                <menu action='EditMenu'>
                  <menuitem action='Copy'/>
                  <menuitem action='SelectAll'/>
                  <separator/>
                  <menuitem action='Find'/>
                  <menuitem action='Preferences'/>
                </menu>
                <menu action='ViewMenu'>
                  <menuitem action='FullScreen'/>
                  <menuitem action='SidePane'/>
                  <separator/>
                  <menuitem action='Home'/>
                  <menuitem action='Back'/>
                  <menuitem action='Forward'/>
                  <menuitem action='Prev'/>
                  <menuitem action='Next'/>
                  <separator/>
                  <menuitem action='ZoomIn'/>
                  <menuitem action='ZoomReset'/>
                  <menuitem action='ZoomOut'/>
                </menu>
                <menu action='HelpMenu'>
                  <separator/>
                  <menuitem action='About'/>
                </menu>
              </menubar>
              <toolbar name='toolbar'>
                <toolitem action='Open'/>
                <separator/>
                <toolitem action='SidePane' name='sidepane'/>
                <toolitem action='Back'/>
                <toolitem action='Forward'/>
                <toolitem action='Home'/>
                <toolitem action='Prev'/>
                <toolitem action='Next'/>
                <toolitem action='ZoomIn'/>
                <toolitem action='ZoomReset'/>
                <toolitem action='ZoomOut'/>
                <toolitem action='Preferences'/>
                <toolitem action='About'/>
              </toolbar>
              <accelerator action='OnKeyboardEscape'/>
              <accelerator action='OnKeyboardControlEqual'/>
            </ui>""";

        ui_manager.add_ui_from_string(ui_description, -1);

        menubar = new HandleBox();
        menubar.add(ui_manager.get_widget("/MainMenu"));
        vbox.pack_start(menubar, false, false, 0);

        RecentChooserMenu recent_menu = new RecentChooserMenu.for_manager(RecentManager.get_default());
        recent_menu.set_show_not_found(false);
        recent_menu.set_local_only(true);
        recent_menu.set_limit(10);
        recent_menu.set_show_icons(false);
        recent_menu.set_sort_type(RecentSortType.MRU);
        recent_menu.set_show_numbers(true);

        RecentFilter filter = new RecentFilter();
        filter.add_application(Environment.get_application_name());
        recent_menu.set_filter(filter);

        recent_menu.item_activated.connect(on_recent_files);

        ((MenuItem)ui_manager.get_widget("/MainMenu/FileMenu/RecentFiles")).set_submenu(recent_menu);

        toolbar = new HandleBox();
        toolbar.add(ui_manager.get_widget("/toolbar"));
        vbox.pack_start(toolbar, false, false, 0);

        ((ToolButton)ui_manager.get_widget("/toolbar/sidepane")).set_icon_widget(new Image.from_file(RESOURCE_FILE("show-pane.png")));

        book = new CsBook();
        vbox.pack_start(book, true, true, 0);
        book.model_changed.connect(book_model_changed_cb);

        /* status bar */
        statusbar = new Statusbar();
        vbox.pack_start(statusbar, false, false, 0);

        scid_default = statusbar.get_context_id("default");

        add(vbox);

        update_status_bar(_("Ready!"));
        show_all();
        book.findbar_hide();
    }

    private void set_fullscreen(bool f) {
        config.fullscreen = f;
        if (f)
            fullscreen();
        else
            unfullscreen();
    }

    private void update_status_bar(string message) {
        statusbar.pop(scid_default);
        statusbar.push(scid_default, " " + message);
    }

    private void set_sidepane_state(bool state) {
        book.sidepane_visible = state;
        string pane_icon = state ? RESOURCE_FILE("hide-pane.png") : RESOURCE_FILE("show-pane.png");

        Image icon_widget = new Image.from_file(pane_icon);
        icon_widget.show();

        ((ToolButton)ui_manager.get_widget("/toolbar/sidepane")).set_icon_widget(icon_widget);
    }

    public void open_file(string filename) {
        try {
            chmfile = new CsChmfile(filename, config.bookshelf);

            /* set global charset and font to this file */
            if (chmfile.settings.charset == "")
                chmfile.settings.charset = config.charset;

            if (chmfile.settings.variable_font == "")
                chmfile.settings.variable_font = config.variable_font;

            if (chmfile.settings.fixed_font == "")
                chmfile.settings.fixed_font = config.fixed_font;

            state = CsState.LOADING;

            book.set_model(chmfile);

            ((ToggleToolButton)ui_manager.get_widget("/toolbar/sidepane")).set_active(true);
            set_focus_child(book);

            book.html_changed.connect(book_html_changed_cb);
            book.notify["book-message"].connect(
                () => {
                    update_status_bar(book.book_message);
                });

            /* update window title */
            set_title("%s - ChmSee".printf(chmfile.bookinfo.bookname));

            /* record last opened file */
            config.last_file = chmfile.chm;

            /* recent files */
            try {
                uint8[] content;
                FileUtils.get_data(filename, out content);

                RecentData data = RecentData();
                data.mime_type = "application/x-chm";
                data.app_name = Environment.get_application_name();
                data.app_exec = Environment.get_prgname() + " %u";
                data.groups = new string[] { "CHM Viewer" };
                data.is_private = false;

                string uri = Filename.to_uri(filename);

                RecentManager.get_default().add_full(uri, data);
            } catch (FileError e) {
                // ignore
            } catch (ConvertError e) {
                // ignore
            }

            state = CsState.NORMAL;
        } catch (Error e) {
            Dialog msg_dialog = new MessageDialog(this,
                DialogFlags.DESTROY_WITH_PARENT,
                MessageType.ERROR,
                ButtonsType.CLOSE,
                _("Error: Can not open spectified file '%s'"), filename);
            msg_dialog.set_position(WindowPosition.CENTER);
            msg_dialog.run();
            msg_dialog.destroy();
        }
    }

    public void close_book() {
        if (chmfile != null)
            chmfile = null;

        book_model_changed_cb("");
        state = CsState.NORMAL;
    }

    public string get_bookshelf() {
        return config.bookshelf;
    }
}

