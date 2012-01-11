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

string RESOURCE_FILE(string file) {
    return Path.build_filename(Configuration.DATA_DIR, file);
}

int ncase_compare_utf8_string(string str1, string str2) {
    string normalized_str1 = str1.casefold().normalize(-1, NormalizeMode.DEFAULT);
    string normalized_str2 = str2.casefold().normalize(-1, NormalizeMode.DEFAULT);
    return normalized_str1.collate(normalized_str2);
}

/* Remove '#', ';' fragment in uri */
string get_real_uri(string uri) {
    var p = uri.last_index_of("#");
    string result;
    if (p >= 0)
        result = uri.substring(0, p);
    else
        result = uri;

    p = result.last_index_of(";");
    if (p >= 0)
        result = result.substring(0, p);

    return result;
}

string? file_exist_ncase(string path) {
    if (FileUtils.test(path, FileTest.EXISTS)) {
        return path;
    }

    string old_dir = Path.get_dirname(path);
    string dirname = file_exist_ncase(old_dir);
    if (dirname == null)
        return null;

    /* check new dirname with basename */
    string filename = Path.get_basename(path);
    string newfile = "%s/%s".printf(dirname, filename);
    if (FileUtils.test(newfile, FileTest.EXISTS))
        return newfile;

    string? found = null;
    try {
        Dir dir = Dir.open(dirname);
        if (dir != null) {
            string? entry;
            while ((entry = dir.read_name()) != null) {
                if (0 == filename.ascii_casecmp(entry)) {
                    found = "%s/%s".printf(dirname, entry);
                    break;
                }
            }
        }
    } catch (FileError e) {
        // silently ignore
    }

    return found;
}

