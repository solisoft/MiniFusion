# The CAD editor's script, assembled from src/ on demand — what build.js used to
# write into fusion_mvp.html. The files are a CONTIGUOUS partition of one script:
# they are concatenated in name order, each preceded by its section banner, so
# top-level statements run in the same order as before. Edit src/, reload: no
# build step. The result is kept per worker until one of the files changes.
class CadBundle
  static memo_stamp: String = ""
  static memo_source: String = ""

  static def files
    File.glob("src/[0-9][0-9]-*.js").sort
  end

  static def source -> String
    paths = CadBundle.files
    stamp = paths.map { |path| path + "@" + str(File.modified(path)) }.join("|")
    return CadBundle.memo_source if stamp == CadBundle.memo_stamp

    CadBundle.memo_source = CadBundle.assemble(paths)
    CadBundle.memo_stamp = stamp
    CadBundle.memo_source
  end

  # APP_VER as src/00 declares it: the editor's version badge, and the cache
  # buster on public/ assets (Soli serves them `immutable` for a year).
  static def app_ver -> String
    found = Regex.capture("const APP_VER='(?P<ver>[^']+)'", File.read("src/00-entete-et-outils.js"))
    found.nil? ? "dev" : found["ver"]
  end

  static def assemble(paths) -> String
    chunks = paths.map do |path|
      name = path.split("/").last
      title = Regex.replace("^[0-9][0-9]-", name, "")
      title = Regex.replace("\\.js$", title, "").split("-").join(" ")
      body = Regex.replace("\\s+$", File.read(path), "")
      rule = "═" * 15
      "/* #{rule} #{name} — #{title} #{rule} */\n" + body
    end
    chunks.join("\n\n")
  end
end
