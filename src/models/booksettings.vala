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

public class BookSettings {
    public string variable_font = "";
    public string fixed_font = "";
    public string charset = ""; /* user specified on setup window */

    private string filename(string bookfolder) {
        return Path.build_filename(bookfolder, Configuration.BOOK_SETTINGS_FILE);
    }

    public void load(string bookfolder) {
        try {
            KeyFile keyfile = new KeyFile();
            keyfile.load_from_file(filename(bookfolder), KeyFileFlags.NONE);

            string vfont = keyfile.get_string("settings", "variable_font");
            if (vfont != "")
                variable_font = vfont;

            string ffont = keyfile.get_string("settings", "fixed_font");
            if (ffont != "")
                fixed_font = ffont;

            string ch = keyfile.get_string("settings", "charset");
            if (ch != "")
                charset = ch;
        } catch (KeyFileError e) {
            // TODO: show warning
        } catch (FileError e) {
            // TODO: show warning
        }
    }

    public void save(string bookfolder) {
        try {
            KeyFile keyfile = new KeyFile();
            keyfile.set_string("setting", "variable_font", variable_font);
            keyfile.set_string("setting", "fixed_font", fixed_font);
            keyfile.set_string("setting", "charset", charset);

            FileUtils.set_data(filename(bookfolder), (uint8[])keyfile.to_data().to_utf8());
        } catch (FileError e) {
            // TODO: show warning
        }
    }
}

