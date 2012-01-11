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

static int log_level = 2; /* only show WARNING, CRITICAL, ERROR */

static void dummy_log_handler(string? log_domain, LogLevelFlags log_level, string? message) {
    // do nothing
}

static void init_log(int log_level) {
    LogLevelFlags log_levels = LogLevelFlags.LEVEL_ERROR;
    if (log_level < 1) log_levels |= LogLevelFlags.LEVEL_CRITICAL;
    if (log_level < 2) log_levels |= LogLevelFlags.LEVEL_WARNING;
    if (log_level < 3) log_levels |= LogLevelFlags.LEVEL_MESSAGE;
    if (log_level < 4) log_levels |= LogLevelFlags.LEVEL_INFO;
    if (log_level < 5) log_levels |= LogLevelFlags.LEVEL_DEBUG;

    Log.set_handler(null, log_levels, dummy_log_handler);
}

static bool callback_verbose(string option_name, string? value, void* data) throws Error {
    log_level++;
    return true;
}

static bool callback_quiet(string option_name, string? value, void* data) throws Error {
    log_level--;
    return true;
}

CsConfig load_config() {
    CsConfig config = new CsConfig();

    try {
        /* ChmSee's HOME directory, based on $XDG_CONFIG_HOME, defaultly locate in ~/.config/chmsee */
        config.home = Path.build_filename(Environment.get_user_config_dir(), Configuration.PACKAGE);
        if (!FileUtils.test(config.home, FileTest.IS_DIR))
            DirUtils.create(config.home, 0755);

        /* ChmSee's bookshelf directory, based on $XDG_CACHE_HOME, defaultly locate in ~/.cache/chmsee/bookshelf */
        config.bookshelf = Path.build_filename(Environment.get_user_cache_dir(),
                                               Configuration.PACKAGE,
                                               Configuration.BOOKSHELF_DEFAULT);
        if (!FileUtils.test(config.bookshelf, FileTest.IS_DIR))
            DirUtils.create(config.bookshelf, 0755);

        config.last_file     = null;
        config.charset       = null;
        config.variable_font = null;
        config.fixed_font    = null;
        config.pos_x      = -100;
        config.pos_y      = -100;
        config.width      = 0;
        config.height     = 0;
        config.hpaned_pos = 200;
        config.fullscreen       = false;
        config.startup_lastfile = false;

        string config_file = Path.build_filename(config.home, Configuration.CONFIG_FILE);

        if (FileUtils.test(config_file, FileTest.EXISTS)) {
            KeyFile keyfile = new KeyFile();
            bool rv = keyfile.load_from_file(config_file, KeyFileFlags.NONE);
            if (rv) {
                config.last_file     = keyfile.get_string("ChmSee", "LAST_FILE");
                config.charset       = keyfile.get_string("ChmSee", "CHARSET");
                config.variable_font = keyfile.get_string("ChmSee", "VARIABLE_FONT");
                config.fixed_font    = keyfile.get_string("ChmSee", "FIXED_FONT");

                config.pos_x      = keyfile.get_integer("ChmSee", "POS_X");
                config.pos_y      = keyfile.get_integer("ChmSee", "POS_Y");
                config.width      = keyfile.get_integer("ChmSee", "WIDTH");
                config.height     = keyfile.get_integer("ChmSee", "HEIGHT");
                config.hpaned_pos = keyfile.get_integer("ChmSee", "HPANED_POSITION");
                config.fullscreen       = keyfile.get_boolean("ChmSee", "FULLSCREEN");
                config.startup_lastfile = keyfile.get_boolean("ChmSee", "STARTUP_LASTFILE");

                if (config.hpaned_pos <= 0)
                    config.hpaned_pos = 200;
            }
        }
    } catch (Error e) {
        // TODO: show error
        error("%s", e.message);
    }

    /* global default value */
    if (config.charset == null)
        config.charset = "Auto";
    if (config.variable_font == null)
        config.variable_font = "Sans 12";
    if (config.fixed_font == null)
        config.fixed_font = "Monospace 12";

    return config;
}

void save_config(CsConfig config) {
    try {
        string config_file = Path.build_filename(config.home, Configuration.CONFIG_FILE);

        KeyFile keyfile = new KeyFile();

        if (config.last_file != null)
            keyfile.set_string("ChmSee", "LAST_FILE", config.last_file);

        keyfile.set_string("ChmSee", "CHARSET", config.charset);
        keyfile.set_string("ChmSee", "VARIABLE_FONT", config.variable_font);
        keyfile.set_string("ChmSee", "FIXED_FONT", config.fixed_font);

        keyfile.set_integer("ChmSee", "POS_X", config.pos_x);
        keyfile.set_integer("ChmSee", "POS_Y", config.pos_y);
        keyfile.set_integer("ChmSee", "WIDTH", config.width);
        keyfile.set_integer("ChmSee", "HEIGHT", config.height);
        keyfile.set_integer("ChmSee", "HPANED_POSITION", config.hpaned_pos);
        keyfile.set_boolean("ChmSee", "FULLSCREEN", config.fullscreen);
        keyfile.set_boolean("ChmSee", "STARTUP_LASTFILE", config.startup_lastfile);

        FileUtils.set_data(config_file, (uint8[])keyfile.to_data().to_utf8());
    } catch (Error e) {
        // TODO: show error
        error("%s", e.message);
    }
}

int main(string[] args) {
    typeof(Configuration).class_ref(); // bump

    try {
        string? filename = null;

        bool option_version = false;

        OptionEntry[] options = new OptionEntry[] {
            OptionEntry(){
                long_name = "version",
                // arg = OptionArg.NONE,
                arg_data = &option_version,
                description = _("Display ChmSee version")
            },
            OptionEntry(){
                long_name = "verbose",
                short_name = 'v',
                flags = OptionFlags.NO_ARG, 
                arg = OptionArg.CALLBACK,
                arg_data = (void*)callback_verbose,
                description = _("Be verbose, repeat 3 times to get all information")
            },
            OptionEntry(){
                long_name = "quiet",
                short_name = 'q',
                flags = OptionFlags.NO_ARG,
                arg = OptionArg.CALLBACK,
                arg_data = (void*)callback_quiet,
                description = _("Be quiet, repeat 2 times to disable all information")
            }
        };

        string cmdparams = "[chmfile]\n\nGTK+ based CHM file viewer\nExample: chmsee Handbook.chm::toc.html";

        init_with_args(ref args, cmdparams, options, Configuration.GETTEXT_PACKAGE);

        if (option_version) {
            print("%s\n", Configuration.PACKAGE_STRING);
            return 0;
        }

        if (args.length >= 2)
            filename = args[1]; // only open the first specified file

        init_log(log_level);

        /* i18n */
        Intl.bindtextdomain(Configuration.GETTEXT_PACKAGE, Configuration.PACKAGE_LOCALE_DIR);
        Intl.bind_textdomain_codeset(Configuration.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain(Configuration.GETTEXT_PACKAGE);

        CsConfig config = load_config();

        Chmsee chmsee = new Chmsee(config);

        if (chmsee == null) {
            warning("Creating chmsee main window failed!");
            return 1;
        }

        if (filename != null)
            chmsee.open_file(filename);
        else if (config.startup_lastfile && config.last_file != null && config.last_file != "")
            chmsee.open_file(config.last_file);

        Gtk.main();

        save_config(config);

        return 0;
    } catch (Error e) {
        // TODO: print error
        printerr("%s", e.message);
        return 1;
    }
}

