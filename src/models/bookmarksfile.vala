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

namespace Bookmarks {
    public ArrayList<Link> load(string path) {
        var links = new ArrayList<Link>();
        try {
            if (FileUtils.test(path, FileTest.EXISTS)) {
                KeyFile keyfile = new KeyFile();
                keyfile.load_from_file(path, KeyFileFlags.NONE);
                foreach (string name in keyfile.get_keys("bookmarks")) {
                    string uri = keyfile.get_string("bookmarks", name);
                    links.add(new Link(name, uri));
                }
            }
        } catch (Error e) {
            stderr.printf("ERROR: %s\n", e.message);
        }
        return links;
    }

    public void save(ArrayList<Link> links, string path) {
        try {
            KeyFile keyfile = new KeyFile();
            foreach (Link link in links)
                keyfile.set_string("bookmarks", link.name, link.uri);
            FileUtils.set_data(path, (uint8[])keyfile.to_data().to_utf8());
        } catch (Error e) {
            stderr.printf("ERROR: %s\n", e.message);
        }
    }
}

