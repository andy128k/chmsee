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
using Xml;

class StackItem {
    public ArrayList<Link> children;
    public Link link;
    public StackItem next;
}

class Context {
    public StackItem stack;
    public ArrayList<Link> children;
    public Link link;
}

static string get_attr(string[] atts, string key) {
    for (int i = 0; i < atts.length; i += 2) {
        if (atts[i].ascii_casecmp(key) == 0) {
            return atts[i + 1];
        }
    }
    return "";
}

static void startElementHH(void* ctx, string name, [CCode (array_length = false, array_null_terminated = true)] string[] atts) {
    Context context = (Context)ctx;

    if (name.ascii_casecmp("object") == 0) {
        context.link = new Link("", "");
        context.children.add(context.link);
    } else if (name.ascii_casecmp("param") == 0) {
        string param_name = get_attr(atts, "name");
        string param_value = get_attr(atts, "value");
        if (param_name.ascii_casecmp("name") == 0) {
            context.link.name = param_value;
        } else if (param_name.ascii_casecmp("local") == 0) {
            context.link.uri = param_value;
        }
    } else if (name.ascii_casecmp("ul") == 0) {
        StackItem i = new StackItem();
        i.children = context.children;
        i.link = context.link;
        i.next = context.stack;
        context.stack = i;

        context.children = new ArrayList<Link>();
        context.link = null;
    }
}

static void endElementHH(void* ctx, string name) {
    Context context = (Context)ctx;

    if (name.ascii_casecmp("ul") == 0) {
        context.link = context.stack.link;
        context.link.children = context.children;
        context.children = context.stack.children;
        
        StackItem i = context.stack;
        context.stack = context.stack.next;
        i.next = null;
    }
}

Link cs_parse_file(string filename, string encoding) {
    Context context = new Context();
    context.children = new ArrayList<Link>();
    context.link = new Link("", "");

    SAXHandler hhSAXHandler = SAXHandler();
    hhSAXHandler.initialized = 1;
    hhSAXHandler.startElement = startElementHH;
    hhSAXHandler.endElement = endElementHH;

    Html.Doc.sax_parse_file(filename,
                            encoding,
                            &hhSAXHandler,
                            context);

    return context.link;
}

