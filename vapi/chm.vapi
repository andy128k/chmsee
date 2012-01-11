[CCode (cheader_filename = "chm_lib.h")]
namespace Chm {
    [CCode (cprefix = "CHM_", cname = "int")]
    public enum Space {
        UNCOMPRESSED,
        COMPRESSED,
    }

    [CCode (cprefix = "CHM_PARAM_", cname = "int")]
    public enum Param {
        MAX_BLOCKS_CACHED
    }

    [CCode (cprefix = "CHM_")]
    public const uint MAX_PATHLEN /* = 512 */;

    [CCode (cname="struct chmUnitInfo")]
    public struct UnitInfo
    {
        uint64 start;
        uint64 length;
        int space;
        int flags;
        char path[513 /*CHM_MAX_PATHLEN + 1*/];
    }

    [CCode (cprefix = "CHM_ENUMERATOR_", cname = "int")]
    public enum EnumeratorStatus {
        FAILURE,
        CONTINUE,
        SUCCESS,
    }

    public delegate EnumeratorStatus Enumerator(File h, UnitInfo ui);

    [CCode (cprefix = "CHM_ENUMERATE_", cname = "int")]
    [Flags]
    public enum Enumerate {
        NORMAL = 1,
        META = 2,
        SPECIAL = 4,
        FILES = 8,
        DIRS = 16,
        ALL = 31
    }

    [CCode (cprefix = "CHM_RESOLVE_", cname = "int")]
    public enum ResolveStatus {
        SUCCESS,
        FAILURE,
    }

    [CCode (cname = "struct chmFile", free_function = "chm_close")]
    [Compact]
    public class File {
        [CCode (cname = "chm_open")]
        public File(string filename);

        [CCode (cname = "chm_set_param")]
        public void set_param(Param paramType, int paramVal);

        [CCode (cname = "chm_enumerate")]
        public bool enumerate(Enumerate what, Enumerator e);

        [CCode (cname = "chm_enumerate_dir")]
        public bool enumerate_dir(string prefix, Enumerate what, Enumerator e, void *context);

        [CCode (cname = "chm_retrieve_object")]
        public int64 retrieve_object(UnitInfo *ui, [CCode(array_length = false)] uint8[] buf, uint64 addr, int64 len);

        [CCode (cname = "chm_resolve_object")]
        public ResolveStatus resolve_object(string objPath, UnitInfo *ui);
    }
}

