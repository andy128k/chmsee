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

static void purge_bookshelf(Chmsee chmsee) {
    string? bookshelf = chmsee.get_bookshelf();

    if (bookshelf != null && FileUtils.test(bookshelf, FileTest.EXISTS)) {
        chmsee.close_book();

        try {
            Process.spawn_async(
                Environment.get_tmp_dir(),
                new string[]{
                    "rm",
                    "-rf",
                    bookshelf
                },
                null,
                SpawnFlags.SEARCH_PATH,
                null,
                null);
        } catch (SpawnError e) {
            // ignore
        }
    }
}

static TreeIter PARENT(TreeStore store, string title) {
    TreeIter iter;
    store.append(out iter, null);
    store.set(iter,
              0, "",
              1, title);
    return iter;
}

static void ITEM(TreeStore store, TreeIter? parent, string code, string title) {
    TreeIter iter;
    store.append(out iter, parent);
    store.set(iter,
              0, code,
              1, title);
}

static TreeModel create_lang_model() {
    TreeStore store = new TreeStore(2, typeof(string), typeof(string));
    TreeIter parent;

    parent = PARENT(store, _("Auto"));
    parent = PARENT(store, _("West European"));
        ITEM(store, parent, "ISO-8859-1", _("Western (ISO-8859-1)"));
        ITEM(store, parent, "ISO-8859-15", _("Western (ISO-8859-15)"));
        ITEM(store, parent, "IBM850", _("Western (IBM-850)"));
        ITEM(store, parent, "x-mac-roman", _("Western (MacRoman)"));
        ITEM(store, parent, "windows-1252", _("Western (Windows-1252)"));
        ITEM(store, parent, "ISO-8859-14", _("Celtic (ISO-8859-14)"));
        ITEM(store, parent, "ISO-8859-7", _("Greek (ISO-8859-7)"));
        ITEM(store, parent, "x-mac-greek", _("Greek (MacGreek)"));
        ITEM(store, parent, "windows-1253", _("Greek (Windows-1253)"));
        ITEM(store, parent, "x-mac-icelandic", _("Icelandic (MacIcelandic)"));
        ITEM(store, parent, "ISO-8859-10", _("Nordic (ISO-8859-10)"));
        ITEM(store, parent, "ISO-8859-3", _("South European (ISO-8859-3)"));
    parent = PARENT(store, _("East European"));
        ITEM(store, parent, "ISO-8859-4", _("Baltic (ISO-8859-4)"));
        ITEM(store, parent, "ISO-8859-13", _("Baltic (ISO-8859-13)"));
        ITEM(store, parent, "windows-1257", _("Baltic (Windows-1257)"));
        ITEM(store, parent, "IBM852", _("Central European (IBM-852)"));
        ITEM(store, parent, "ISO-8859-2", _("Central European (ISO-8859-2)"));
        ITEM(store, parent, "x-mac-ce", _("Central European (MacCE)"));
        ITEM(store, parent, "windows-1250", _("Central European (Windows-1250)"));
        ITEM(store, parent, "x-mac-croatian", _("Croatian (MacCroatian)"));
        ITEM(store, parent, "IBM855", _("Cyrillic (IBM-855)"));
        ITEM(store, parent, "ISO-8859-5", _("Cyrillic (ISO-8895-5)"));
        ITEM(store, parent, "ISO-IR-111", _("Cyrillic (ISO-IR-111)"));
        ITEM(store, parent, "KOI8-R", _("Cyrillic (KOI8-R)"));
        ITEM(store, parent, "x-mac-cyrillic", _("Cyrillic (MacCyrillic)"));
        ITEM(store, parent, "windows-1251", _("Cyrillic (Windows-1251)"));
        ITEM(store, parent, "IBM866", _("Cyrillic/Russian (CP-866)"));
        ITEM(store, parent, "KOI8-U", _("Cyrillic/Ukrainian (KOI8-U)"));
        ITEM(store, parent, "ISO-8859-16", _("Romanian (ISO-8859-16)"));
        ITEM(store, parent, "x-mac-romanian", _("Romanian (MacRomanian)"));
    parent = PARENT(store, _("East Asian"));
        ITEM(store, parent, "GB2312", _("Chinese Simplified (GB2312)"));
        ITEM(store, parent, "x-gbk", _("Chinese Simplified (GBK)"));
        ITEM(store, parent, "gb18030", _("Chinese Simplified (GB18030)"));
        ITEM(store, parent, "HZ-GB-2312", _("Chinese Simplified (HZ)"));
        ITEM(store, parent, "ISO-2022-CN", _("Chinese Simplified (ISO-2022-CN)"));
        ITEM(store, parent, "Big5", _("Chinese Traditional (Big5)"));
        ITEM(store, parent, "Big5-HKSCS", _("Chinese Traditional (Big5-HKSCS)"));
        ITEM(store, parent, "x-euc-tw", _("Chinese Traditional (EUC-TW)"));
        ITEM(store, parent, "EUC-JP", _("Japanese (EUC-JP)"));
        ITEM(store, parent, "ISO-2022-JP", _("Japanese (ISO-2022-JP)"));
        ITEM(store, parent, "Shift_JIS", _("Japanese (Shift_JIS)"));
        ITEM(store, parent, "EUC-KR", _("Korean (EUC-KR)"));
        ITEM(store, parent, "x-windows-949", _("Korean (UHC)"));
        ITEM(store, parent, "x-johab", _("Korean (JOHAB)"));
        ITEM(store, parent, "ISO-2022-KR", _("Korean (ISO-2022-KR)"));
    parent = PARENT(store, _("SE & SW Asian"));
        ITEM(store, parent, "armscii-8", _("Armenian (ARMSCII-8)"));
        ITEM(store, parent, "GEOSTD8", _("Georgian (GEOSTD8)"));
        ITEM(store, parent, "TIS-620", _("Thai (TIS-620)"));
        ITEM(store, parent, "ISO-8859-11", _("Thai (ISO-8859-11)"));
        ITEM(store, parent, "windows-874", _("Thai (Windows-874)"));
        ITEM(store, parent, "IBM874", _("Thai (IBM-874)"));
        ITEM(store, parent, "IBM857", _("Turkish (IBM-857)"));
        ITEM(store, parent, "ISO-8859-9", _("Turkish (ISO-8859-9)"));
        ITEM(store, parent, "x-mac-turkish", _("Turkish (MacTurkish)"));
        ITEM(store, parent, "windows-1254", _("Turkish (Windows-1254)"));
        ITEM(store, parent, "x-viet-tcvn5712", _("Vietnamese (TCVN)"));
        ITEM(store, parent, "VISCII", _("Vietnamese (VISCII)"));
        ITEM(store, parent, "x-viet-vps", _("Vietnamese (VPS)"));
        ITEM(store, parent, "windows-1258", _("Vietnamese (Windows-1258)"));
        ITEM(store, parent, "x-mac-devanagari", _("Hindi (MacDevanagari)"));
        ITEM(store, parent, "x-mac-gujarati", _("Gujarati (MacGujarati)"));
        ITEM(store, parent, "x-mac-gurmukh", _("Gurmukhi (MacGurmukhi)"));
    parent = PARENT(store, _("Middle Eastern"));
        ITEM(store, parent, "ISO-8859-6", _("Arabic (ISO-8859-6)"));
        ITEM(store, parent, "windows-1256", _("Arabic (Windows-1256)"));
        ITEM(store, parent, "IBM864", _("Arabic (IBM-864)"));
        ITEM(store, parent, "x-mac-arabic", _("Arabic (MacArabic)"));
        ITEM(store, parent, "x-mac-farsi", _("Farsi (MacFarsi)"));
        ITEM(store, parent, "ISO-8859-8-I", _("Hebrew (ISO-8859-8-I)"));
        ITEM(store, parent, "windows-1255", _("Hebrew (Windows-1255)"));
        ITEM(store, parent, "ISO-8859-8", _("Hebrew Visual (ISO-8859-8)"));
        ITEM(store, parent, "IBM862", _("Hebrew (IBM-862)"));
        ITEM(store, parent, "x-mac-hebrew", _("Hebrew (MacHebrew)"));
    parent = PARENT(store, _("Unicode"));
        ITEM(store, parent, "UTF-8", _("Unicode (UTF-8)"));
        ITEM(store, parent, "UTF-16LE", _("Unicode (UTF-16LE)"));
        ITEM(store, parent, "UTF-16BE", _("Unicode (UTF-16BE)"));
        ITEM(store, parent, "UTF-32", _("Unicode (UTF-32)"));
        ITEM(store, parent, "UTF-32LE", _("Unicode (UTF-32LE)"));
        ITEM(store, parent, "UTF-32BE", _("Unicode (UTF-32BE)"));

    return store;
}

static void cell_layout_data_func(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
    renderer.set_sensitive(!model.iter_has_child(iter));
}

void setup_window_new(Chmsee chmsee) throws Error {
    /* create setup window */
    Builder builder = new Builder();
    builder.add_from_file(RESOURCE_FILE("setup-window.ui"));

    Window setup_window = (Window)builder.get_object("setup_window");
    setup_window.destroy.connect(() => { setup_window.destroy(); });

    /* bookshelf directory */
    Entry bookshelf_entry = (Entry)builder.get_object("bookshelf_entry");
    bookshelf_entry.set_text(chmsee.get_bookshelf());

    Button clear_button = (Button)builder.get_object("setup_clear");
    clear_button.clicked.connect(
        () => {
            purge_bookshelf(chmsee);
        });

    /* font setting */
    FontButton variable_font_button = (FontButton)builder.get_object("variable_fontbtn");
    variable_font_button.font_set.connect(
        () => {
            chmsee.variable_font = variable_font_button.get_font_name();
        });

    FontButton fixed_font_button = (FontButton)builder.get_object("fixed_fontbtn");
    fixed_font_button.font_set.connect(
        () => {
            chmsee.fixed_font = fixed_font_button.get_font_name();
        });

    /* default lang */
    ComboBox cmb_lang = (ComboBox)builder.get_object("cmb_default_lang");
    TreeModel cmb_model = create_lang_model();
    cmb_lang.set_model(cmb_model);

    CellRenderer renderer = new CellRendererText();
    cmb_lang.pack_start(renderer, false);
    cmb_lang.set_attributes(renderer, "text", 1);
    cmb_lang.set_cell_data_func(renderer, cell_layout_data_func);

    variable_font_button.set_font_name(chmsee.variable_font);
    fixed_font_button.set_font_name(chmsee.fixed_font);

    string? charset = chmsee.charset;
    if (charset != null && charset.length != 0 && charset != "Auto") {
        cmb_model.foreach(
            (model, path, iter) => {
                string? cs;
                model.get(iter, 0, out cs);

                if (charset == cs) {
                    cmb_lang.set_active_iter(iter);
                    return true;
                }
                return false;
            });
    } else {
        cmb_lang.set_active(0);
    }

    cmb_lang.changed.connect(
        () => {
            TreeIter iter;
            cmb_lang.get_active_iter(out iter);
            TreeModel model = cmb_lang.get_model();
            string? cs = null;
            model.get(iter, 0, out cs);

            if (cs != null && cs.length != 0)
                chmsee.charset = cs;
            else
                chmsee.charset = "Auto";
        });

    /* startup load lastfile */
    ToggleButton startup_lastfile_chkbtn = (ToggleButton)builder.get_object("startup_lastfile_chkbtn");
    startup_lastfile_chkbtn.toggled.connect(
        () => {
            chmsee.startup_lastfile = startup_lastfile_chkbtn.get_active();
        });

    startup_lastfile_chkbtn.set_active(chmsee.startup_lastfile);

    Button close_button = (Button)builder.get_object("setup_close");
    close_button.clicked.connect(
        () => {
            setup_window.destroy();
        });
}

