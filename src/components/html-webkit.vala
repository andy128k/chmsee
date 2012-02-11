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
using WebKit;

class CsHtmlWebkit : Frame {
    public signal void title_changed    (CsHtmlWebkit html, string title);
    public signal void location_changed (string location);
    public signal bool open_uri         (string uri);
    public signal void context_normal   ();
    public signal void context_link     (string link);
    public signal void open_new_tab     (string uri);
    public signal void link_message     (string link);

    public WebView view;
    private string? current_url;

    public CsHtmlWebkit() {
        ScrolledWindow sw = new ScrolledWindow(null, null);
        sw.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        sw.set_flags(WidgetFlags.CAN_FOCUS);

        view = new WebView();
        sw.add(view);

        sw.show_all();
        view.show_all();
        current_url = null;

        set_shadow_type(ShadowType.NONE);
        add(sw);

        view.button_press_event.connect(webkit_web_view_mouse_click_cb);
        view.hovering_over_link.connect(webkit_web_view_hovering_over_link_cb);
        view.notify["load-status"].connect(notify_load_status);
        view.title_changed.connect(webkit_title_cb);
    }

    private void webkit_title_cb(WebFrame frame, string title) {
        string uri = frame.get_uri();
        title_changed(this, title);
        location_changed(uri);
    }

    private void notify_load_status() {
        if (view.load_status != LoadStatus.COMMITTED)
            return;

        string uri = view.get_main_frame().get_uri();
        if (uri != null && current_url != null) {
            view.freeze_notify();
            current_url = null;
            link_message(uri);
            location_changed(uri);
            view.thaw_notify();
        }
    }

    private bool webkit_web_view_mouse_click_cb(Gdk.EventButton event) {
        if (event.button == 2 || (event.button == 1 && (event.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
            if (current_url != null) {
                open_new_tab(current_url);
                return true;
            }
        } else if (event.button == 3) {
            if (current_url != null)
                context_link(current_url);
            else
                context_normal();

            return true;
        }

        return false;
    }

    private void webkit_web_view_hovering_over_link_cb(string? tooltip, string? link_uri) {
        current_url = link_uri;
        if (current_url != null)
            link_message(current_url);
    }

    public string get_location() {
        return view.get_main_frame().get_uri();
    }

    public void copy_selection() {
        view.copy_clipboard();
    }

    public void select_all() {
        view.select_all();
    }

    public bool find(string sstr, bool backward, bool match_case) {
        return view.search_text(sstr, match_case, backward, true);
    }

    public void increase_size() {
        float zoom = view.get_zoom_level();
        zoom *= 1.2f;
        view.set_zoom_level(zoom);
    }

    public void reset_size() {
        view.set_zoom_level(1.0f);
    }

    public void decrease_size() {
        float zoom = view.get_zoom_level();
        zoom /= 1.2f;
        view.set_zoom_level(zoom);
    }

    private bool split_font_string(string? font_name, out string name, out int size) {
        name = null;
        size = 0;

        if (font_name == null)
            return false;

        Pango.FontDescription desc = Pango.FontDescription.from_string(font_name);
        Pango.FontMask mask = Pango.FontMask.FAMILY | Pango.FontMask.SIZE;
        if ((desc.get_set_fields() & mask) != mask)
            return false;

        size = (desc.get_size() + Pango.SCALE / 2) / Pango.SCALE;
        name = desc.get_family();
        return true;
    }

    public void set_variable_font(string font_name) {
        string name;
        int size;
        if (split_font_string(font_name, out name, out size)) {
            WebSettings settings = view.get_settings();
            settings.default_font_family = name;
            settings.default_font_size = size;
        }
    }

    public void set_fixed_font(string font_name) {
        string name;
        int size;
        if (split_font_string(font_name, out name, out size)) {
            WebSettings settings = view.get_settings();
            settings.monospace_font_family = name;
            settings.default_monospace_font_size = size;
        }
    }

    public void set_charset(string charset) {
        if (charset == "Auto")
            view.custom_encoding = null;
        else
            view.custom_encoding = charset;
    }
}

