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

namespace Helpers {
    string convert_string_to_utf8(string str, string codeset) throws ConvertError {
        if (str.validate())
            return str;
        else
            return convert(str, -1, "UTF-8", codeset);
    }

    string convert_filename_to_utf8(string filename, string codeset) throws ConvertError {
        if (filename.validate()) {
            return filename;
        } else {
            string filename_utf8 = Filename.to_utf8(filename, -1, null, null);
            if (filename_utf8 == null)
                filename_utf8 = convert(filename, -1, "UTF-8", codeset);
            return filename_utf8;
        }
    }

    uint32 get_dword(uint8[] buf, uint offset) {
        uint32 result = buf[offset] + (buf[offset + 1] << 8) + (buf[offset + 2] << 16) + (buf[offset + 3] << 24);
        if (result == 0xFFFFFFFF)
            result = 0;
        return result;
    }

    uint16 get_word(uint8[] buf, uint offset) {
        return buf[offset] + (buf[offset+1] << 8);
    }

    string get_string(uint8[] buf, uint offset, uint length) {
        return (string)buf[offset:offset+length];
    }

    string get_asciiz(uint8[] buf, uint offset) {
        uint length = 0;
        while (buf[offset + length] != 0)
            ++length;
        return get_string(buf, offset, length);
    }

    string get_encoding_by_lcid(uint32 lcid) {
        switch (lcid) {
            case 0x0436:
            case 0x042d:
            case 0x0403:
            case 0x0406:
            case 0x0413:
            case 0x0813:
            case 0x0409:
            case 0x0809:
            case 0x0c09:
            case 0x1009:
            case 0x1409:
            case 0x1809:
            case 0x1c09:
            case 0x2009:
            case 0x2409:
            case 0x2809:
            case 0x2c09:
            case 0x3009:
            case 0x3409:
            case 0x0438:
            case 0x040b:
            case 0x040c:
            case 0x080c:
            case 0x0c0c:
            case 0x100c:
            case 0x140c:
            case 0x180c:
            case 0x0407:
            case 0x0807:
            case 0x0c07:
            case 0x1007:
            case 0x1407:
            case 0x040f:
            case 0x0421:
            case 0x0410:
            case 0x0810:
            case 0x043e:
            case 0x0414:
            case 0x0814:
            case 0x0416:
            case 0x0816:
            case 0x040a:
            case 0x080a:
            case 0x0c0a:
            case 0x100a:
            case 0x140a:
            case 0x180a:
            case 0x1c0a:
            case 0x200a:
            case 0x240a:
            case 0x280a:
            case 0x2c0a:
            case 0x300a:
            case 0x340a:
            case 0x380a:
            case 0x3c0a:
            case 0x400a:
            case 0x440a:
            case 0x480a:
            case 0x4c0a:
            case 0x500a:
            case 0x0441:
            case 0x041d:
            case 0x081d:
                return "ISO-8859-1";
            case 0x041c:
            case 0x041a:
            case 0x0405:
            case 0x040e:
            case 0x0418:
            case 0x041b:
            case 0x0424:
            case 0x081a:
                return "ISO-8859-2";
            case 0x0415:
                return "WINDOWS-1250";
            case 0x0419:
                return "WINDOWS-1251";
            case 0x0c01:
                return "WINDOWS-1256";
            case 0x0401:
            case 0x0801:
            case 0x1001:
            case 0x1401:
            case 0x1801:
            case 0x1c01:
            case 0x2001:
            case 0x2401:
            case 0x2801:
            case 0x2c01:
            case 0x3001:
            case 0x3401:
            case 0x3801:
            case 0x3c01:
            case 0x4001:
            case 0x0429:
            case 0x0420:
                return "ISO-8859-6";
            case 0x0408:
                return "ISO-8859-7";
            case 0x040d:
                return "ISO-8859-8";
            case 0x042c:
            case 0x041f:
            case 0x0443:
                return "ISO-8859-9";
            case 0x041e:
                return "ISO-8859-11";
            case 0x0425:
            case 0x0426:
            case 0x0427:
                return "ISO-8859-13";
            case 0x0411:
                return "cp932";
            case 0x0804:
            case 0x1004:
                return "cp936";
            case 0x0412:
                return "cp949";
            case 0x0404:
            case 0x0c04:
            case 0x1404:
                return "cp950";
            case 0x082c:
            case 0x0423:
            case 0x0402:
            case 0x043f:
            case 0x042f:
            case 0x0c1a:
            case 0x0444:
            case 0x0422:
            case 0x0843:
                return "cp1251";
            default:
                return "";
        }
    }
}

public class Bookinfo {

    private string hhc_ = "";
    public string hhc {
        get {
            return hhc_;
        }
        private set {
            if (hhc_ == "" && value.ascii_casecmp("(null)") != 0 && check_file(value))
                hhc_ = value;
        }
    }

    private string hhk_ = "";
    public string hhk {
        get {
            return hhk_;
        }
        private set {
            if (hhk_ == "" && check_file(value))
                hhk_ = value;
        }
    }

    private string bookname_ = "";
    public string bookname {
        get {
            return bookname_;
        }
        private set {
            if (value != "")
                bookname_ = value;
        }
    }

    private string homepage_ = "";
    public string homepage {
        get {
            return homepage_;
        }
        private set {
            if (value != "" && value != "/")
                homepage_ = value;
        }
    }

    public string encoding = "UTF-8";

    private Chm.File cfd = null;

    private bool check_file(string s) {
        if (cfd == null)
            return true;
        Chm.UnitInfo ui = Chm.UnitInfo();
        return cfd.resolve_object(s, &ui) == Chm.ResolveStatus.SUCCESS;
    }

    private static string check_file_ncase(string bookfolder, string file) {
        string filename = Path.build_filename(bookfolder, file);
        string new_file = "";

        if (!FileUtils.test(filename, FileTest.EXISTS)) {
            string found = file_exist_ncase(filename);
            if (found != "")
                new_file = Path.get_basename(found);
        }
        return new_file;
    }

    public Bookinfo.extract(string bookfolder, string filename) throws Error {
        Chm.File cfd = new Chm.File(filename);
        if (cfd == null)
            throw new IOError.FAILED(_("Can not open chm file %s."), filename);

        read_system_info(cfd);
        read_windows_info(cfd);

        if (hhc != "") {
            string new_hhc = check_file_ncase(bookfolder, hhc);
            if (new_hhc != "")
                hhc = new_hhc;
        }

        if (hhk != "") {
            string new_hhk = check_file_ncase(bookfolder, hhk);
            if (new_hhk != "")
                hhk = new_hhk;
        }

        /* Convert encoding to UTF-8 */
        if (encoding != "") {
            if (bookname != "")
                bookname = Helpers.convert_string_to_utf8(bookname, encoding);

            if (hhc != "")
                hhc = Helpers.convert_filename_to_utf8(hhc, encoding);

            if (hhk != "")
                hhk = Helpers.convert_filename_to_utf8(hhk, encoding);

            if (homepage != "")
                homepage = Helpers.convert_filename_to_utf8(homepage, encoding);
        }

        if (bookname == "")
            bookname = Path.get_basename(filename);
    }

    public Bookinfo.load(string bookfolder) throws Error {
        string bookinfo_file = Path.build_filename(bookfolder, Configuration.BOOKINFO_FILE);

        KeyFile keyfile = new KeyFile();
        keyfile.load_from_file(bookinfo_file, KeyFileFlags.NONE);

        hhc      = keyfile.get_string("Bookinfo", "hhc");
        hhk      = keyfile.get_string("Bookinfo", "hhk");
        homepage = keyfile.get_string("Bookinfo", "homepage");
        bookname = keyfile.get_string("Bookinfo", "bookname");
        encoding = keyfile.get_string("Bookinfo", "encoding");
    }

    private void read_system_info(Chm.File cfd) {
        Chm.UnitInfo ui = Chm.UnitInfo();

        uint8[] buffer = new uint8[4096];
        int index = 0;

        if (cfd.resolve_object("/#SYSTEM", &ui) != Chm.ResolveStatus.SUCCESS)
            return;

        var size = cfd.retrieve_object(&ui, buffer, 4, 4096);
        if (size == 0)
            return;

        buffer[size - 1] = 0;

        while (index < size - 4) {
            uint16 value = Helpers.get_word(buffer, index);
            uint16 length = Helpers.get_word(buffer, index+2);
            index += 4;

            switch (value) {
                case 0:
                    hhc = "/" + Helpers.get_string(buffer, index, length);
                    break;
                case 1:
                    hhk = "/" + Helpers.get_string(buffer, index, length);
                    break;
                case 2:
                    homepage = "/" + Helpers.get_string(buffer, index, length);
                    break;
                case 3:
                    bookname = Helpers.get_string(buffer, index, length);
                    break;
                case 4:
                    encoding = Helpers.get_encoding_by_lcid(Helpers.get_dword(buffer, index));
                    break;
                case 6:
                    string n = Helpers.get_string(buffer, index, length);
                    hhc = "/" + n + ".hhc";
                    hhk = "/" + n + ".hhk";
                    break;
            }
            index += length;
        }
    }

    private void read_windows_info(Chm.File cfd) {
        Chm.UnitInfo ui = Chm.UnitInfo();
        uint8[] buffer = new uint8[4096];
        int64 size = 0;

        if (cfd.resolve_object("/#WINDOWS", &ui) != Chm.ResolveStatus.SUCCESS)
            return;

        size = cfd.retrieve_object(&ui, buffer, 0, 8);

        if (size < 8)
            return;

        uint32 entries = Helpers.get_dword(buffer, 0);
        if (entries < 1)
            return;

        uint32 entry_size = Helpers.get_dword(buffer, 4);
        size = cfd.retrieve_object(&ui, buffer, 8, entry_size);
        if (size < entry_size)
            return;

        uint32 hhc_offset = Helpers.get_dword(buffer, 0x60);
        uint32 hhk_offset = Helpers.get_dword(buffer, 0x64);
        uint32 homepage_offset = Helpers.get_dword(buffer, 0x68);
        uint32 bookname_offset = Helpers.get_dword(buffer, 0x14);

        if (cfd.resolve_object("/#STRINGS", &ui) != Chm.ResolveStatus.SUCCESS)
            return;

        size = cfd.retrieve_object(&ui, buffer, 0, 4096);

        if (size == 0)
            return;

        if (hhc_offset != 0)
            hhc = "/" + Helpers.get_asciiz(buffer, hhc_offset);

        if (hhk_offset != 0)
            hhk = "/" + Helpers.get_asciiz(buffer, hhk_offset);

        if (homepage_offset != 0)
            homepage = "/" + Helpers.get_asciiz(buffer, homepage_offset);

        if (bookname_offset != 0)
            bookname = Helpers.get_asciiz(buffer, bookname_offset);
    }

    public void save(string bookfolder) throws Error {
        string bookinfo_file = Path.build_filename(bookfolder, Configuration.BOOKINFO_FILE);

        KeyFile keyfile = new KeyFile();

        if (hhc != "")
            keyfile.set_string("Bookinfo", "hhc", hhc);
        if (hhk != "")
            keyfile.set_string("Bookinfo", "hhk", hhk);
        if (homepage != "")
            keyfile.set_string("Bookinfo", "homepage", homepage);
        if (bookname != "")
            keyfile.set_string("Bookinfo", "bookname", bookname);
        keyfile.set_string("Bookinfo", "encoding", encoding);

        FileUtils.set_data(bookinfo_file, (uint8[])keyfile.to_data().to_utf8());
    }
}

