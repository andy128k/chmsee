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

    /* see http://code.google.com/p/chmsee/issues/detail?id=12 */
    private static void extract_post_file_write(string fname) {
        string basename = Path.get_basename(fname);
        int pos = basename.index_of(";");
        if (pos >= 0) {
            string dirname = Path.get_dirname(fname);
            basename = basename.substring(0, pos);
            string newfname = Path.build_filename(dirname, basename);
            if (FileUtils.rename(fname, newfname) != 0) {
                // TODO: g_error("rename \"%s\" to \"%s\" failed: %s", fname, newfname, strerror(errno));
            }
        }
    }

    class ExtractContext {
        public string base_path;

        public Chm.EnumeratorStatus _extract_callback(Chm.File h, Chm.UnitInfo ui) {
            string path = (string)ui.path;

            if (path[0] != '/') {
                return Chm.EnumeratorStatus.CONTINUE;
            }

            if (path.index_of("/../") >= 0) {
                return Chm.EnumeratorStatus.CONTINUE;
            }

            if (base_path.length + path.length > 1024) {
                return Chm.EnumeratorStatus.FAILURE;
            }

            string fname = Path.build_filename(base_path, path.substring(1));

            /* Distinguish between files and dirs */
            if (ui.path[-1] != '/') {
                uint8[] buffer = new uint8[32768];
                uint64 len, remain = ui.length;
                uint64 offset = 0;

                DirUtils.create_with_parents(Path.get_dirname(fname), 0777);

                FileStream fout;
                if ((fout = FileStream.open(fname, "wb")) == null) {
                    return Chm.EnumeratorStatus.FAILURE;
                }
                while (remain != 0) {
                    len = h.retrieve_object(&ui, buffer, offset, 32768);
                    if (len > 0) {
                        if (fout.write(buffer) != len) {
                            return Chm.EnumeratorStatus.FAILURE;
                        }
                        offset += len;
                        remain -= len;
                    } else {
                        break;
                    }
                }

                CsChmfile.extract_post_file_write(fname);
            } else {
                if (DirUtils.create_with_parents(fname, 0777) == -1) {
                    return Chm.EnumeratorStatus.FAILURE;
                }
            }

            return Chm.EnumeratorStatus.CONTINUE;
        }
    }

    static void extract_chm(string filename, string base_path) throws IOError {
        Chm.File handle = new Chm.File(filename);
        if (handle == null)
            throw new IOError.NOT_FOUND(_("File '%s' was not found."), filename);

        ExtractContext ec = new ExtractContext();
        ec.base_path = base_path;

        bool r = handle.enumerate(Chm.Enumerate.NORMAL | Chm.Enumerate.SPECIAL, ec._extract_callback);
        if (!r)
            throw new IOError.FAILED(_("File '%s' cannot be extracted."), filename);
    }

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

