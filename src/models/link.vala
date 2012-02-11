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

public class Link {
    public string name;
    public string uri;
    public ArrayList<Link> children;

    public Link(string name, string uri) {
        this.name = name;
        this.uri = uri;
        this.children = new ArrayList<Link>();
    }

    public bool has_children() {
        return children.size > 0;
    }

    private void collect(ArrayList<Link> output) {
        output.add(this);
        foreach (Link child in children)
            child.collect(output);
    }

    public ArrayList<Link> flatten() {
        ArrayList<Link> result = new ArrayList<Link>();
        collect(result);
        return result;
    }
}

