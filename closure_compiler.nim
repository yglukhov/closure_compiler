import httpclient
import cgi

type CompilationLevel* = enum
    SIMPLE_OPTIMIZATIONS
    WHITESPACE_ONLY
    ADVANCED_OPTIMIZATIONS

proc urlencode(params: openarray[tuple[k : string, v: string]]): string =
    result = ""
    for i, p in params:
        if i != 0:
            result &= "&"
        result &= encodeUrl(p.k)
        result &= "="
        result &= encodeUrl(p.v)

proc compileSource*(sourceCode: string, level: CompilationLevel = SIMPLE_OPTIMIZATIONS): string =
    var data = urlencode({
        "compilation_level" : $level,
        "output_format" : "text",
        "output_info" : "compiled_code",
        "js_code" : sourceCode
        })
    result = postContent("http://closure-compiler.appspot.com/compile", body=data, extraHeaders="Content-type: application/x-www-form-urlencoded")


proc compileFile*(f: string, level: CompilationLevel = SIMPLE_OPTIMIZATIONS): string = compileSource(readFile(f), level)
proc compileFileAndRewrite*(f: string, level: CompilationLevel = SIMPLE_OPTIMIZATIONS): bool {.discardable.} =
    result = true
    let r = compileSource(readFile(f), level)
    writeFile(f, r)

when isMainModule:
    import parseopt2

    proc usage() =
        echo "closure_compiler [-q] [-a|-w] file1 [fileN...]"

    proc main() =
        var files = newSeq[string]()
        var level = SIMPLE_OPTIMIZATIONS
        var quiet = false
        for kind, key, val in getopt():
            case kind:
                of cmdArgument: files.add(key)
                of cmdShortOption:
                    case key:
                        of "a": level = ADVANCED_OPTIMIZATIONS
                        of "w": level = WHITESPACE_ONLY
                        of "q": quiet = true
                        else:
                            usage()
                            return
                else:
                    usage()
                    return

        if files.len == 0:
            usage()
            return

        for f in files:
            if not quiet:
                echo "Processing: ", f
            compileFileAndRewrite(f, level)

    main()

