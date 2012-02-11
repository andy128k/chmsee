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

private static string MD5File(string filename) throws FileError {
    uint8[] contents;
    FileUtils.get_data(filename, out contents);
    return Checksum.compute_for_data(ChecksumType.MD5, contents);
}

public class CsChmfile {
    public Link toc_tree { get; private set; }
    public ArrayList<Link> toc_list { get; private set; }
    public ArrayList<Link> index_list { get; private set; }
    public ArrayList<Link> bookmarks_list { get; private set; }

    public string bookfolder { get; private set; }     /* the folder CHM file extracted to */
    public string chm { get; private set; } /* opened CHM file name */ // rename to 'filename'
    public string page { get; private set; }           /* :: specified page */

    public Bookinfo bookinfo = new Bookinfo();
    public BookSettings settings = new BookSettings();

    private void parse_filename(string filename) {
        int p = filename.last_index_of("::");
        if (p >= 0) {
            chm = filename.substring(0, p);
            page = filename.substring(p + 2);
        } else {
            chm = filename;
        }
    }

    public CsChmfile(string filename, string bookshelf) throws Error {
        parse_filename(filename);

        if (!chm.has_suffix(".CHM") && !chm.has_suffix(".chm"))
            return;

        /* Use chmfile's MD5 as the folder name */
        string md5 = MD5File(chm);
        bookfolder = Path.build_filename(bookshelf, md5);

        /* If this chmfile already exists in the bookshelf, load it's bookinfo file */
        if (FileUtils.test(bookfolder, FileTest.IS_DIR)) {
            bookinfo = new Bookinfo.load(bookfolder);
        } else {
            extract_chm(chm, bookfolder);
            bookinfo = new Bookinfo.extract(bookfolder, chm);
        }

        settings.load(bookfolder);
        // settings.save(bookfolder);

        /* Parse hhc file */
        if (bookinfo.hhc != "") {
            string hhcfile = Path.build_filename(bookfolder, bookinfo.hhc);

            toc_tree = cs_parse_file(hhcfile, bookinfo.encoding);
            toc_list = toc_tree.flatten();
        }

        /* Parse hhk file */
        if (bookinfo.hhk != "") {
            string hhkfile = Path.build_filename(bookfolder, bookinfo.hhk);

            Link tree = cs_parse_file(hhkfile, bookinfo.encoding);
            index_list = tree.flatten();
        }

        /* Load bookmarks */
        string bookmarks_file = Path.build_filename(bookfolder, Configuration.BOOKMARKS_FILE);
        bookmarks_list = Bookmarks.load(bookmarks_file);
    }

    public void update_bookmarks_list(ArrayList<Link> links) {
        bookmarks_list = links;

        string bookmarks_file = Path.build_filename(bookfolder, Configuration.BOOKMARKS_FILE);
        Bookmarks.save(bookmarks_list, bookmarks_file);
    }
}

