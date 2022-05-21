module pxtone.error;
// '16/12/16 pxtnError.

class PxtoneException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) @safe {
        super(msg, file, line);
    }
}
