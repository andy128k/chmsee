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

errordomain ParseError {
    SYNTAX_ERROR,
}

ArrayList<Link> cs_bookmarks_file_load(string path) {
    var links = new ArrayList<Link>();
    var file = File.new_for_path(path);

    if (!file.query_exists())
        return links;

    try {
        var dis = new DataInputStream(file.read());
        string line;
        while ((line = dis.read_line(null)) != null) {
            line._strip();

            if (line.length == 0 || line[0] == '#')
                continue;

            string[] parts = line.split("=", 1);
            if (parts.length != 2)
                throw new ParseError.SYNTAX_ERROR("Syntax error");

            string id = parts[0].strip();
            string val = parts[1].strip();

            if (val.length >= 2 && val[0] == '"' && val[-1] == '"')
                val = val[1:-1];
            val = val.replace("\\n", "\n").replace("\\t", "\t").replace("\\b", "\b");

            links.add(new Link(id, val));
        }
    } catch (Error e) {
        stderr.printf("ERROR: %s\n", e.message);
    }

    return links;
}

void cs_bookmarks_file_save(ArrayList<Link> links, string path) {
    try {
        var file = File.new_for_path(path);

        if (file.query_exists()) {
            file.delete();
        }

        var dos = new DataOutputStream(new BufferedOutputStream.sized(file.create(FileCreateFlags.REPLACE_DESTINATION), 65536));

        foreach (Link link in links) {
            dos.put_string(link.name);
            dos.put_string("=");
            dos.put_string(link.uri);
            dos.put_string("\n");
        }
    } catch (Error e) {
        stderr.printf("ERROR: %s\n", e.message);
    }
}

