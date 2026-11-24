# frozen_string_literal: true

# Rewrites the names of language extensions that this compiler no longer
# accepts in package sources: a LANGUAGE pragma, an OPTIONS_GHC -X flag,
# a cabal extensions field or a cabal ghc-options -X flag naming one
# would be rejected as unsupported. A removed extension's name is
# dropped, in either polarity. A renamed extension (a deprecated alias
# the compiler no longer accepts) takes its current name, or is dropped
# when the same polarity of that name is already there. Only the names
# change; the surrounding layout is kept, and a pragma, flag or field
# left with nothing in it goes with its line. An extension that set a
# default for every instance of its module (OverlappingInstances,
# IncoherentInstances) is dropped like the others; the per-instance
# pragmas a package then needs are recorded as a patch.
module Strip
  # The extensions this compiler has removed. Their behaviour is fixed
  # (always on, or always off for CUSKs, StarIsType and DeepSubsumption),
  # so dropping the name changes nothing the compiler could still do for
  # the package.
  REMOVED = %w[
    AlternativeLayoutRule AlternativeLayoutRuleTransitional
    AutoDeriveTypeable CUSKs ConstrainedClassMethods DataKinds
    DatatypeContexts DeepSubsumption DeriveDataTypeable DoRec
    ExplicitForAll IncoherentInstances InstanceSigs KindSignatures
    MultiParamTypeClasses NullaryTypeClasses OverlappingInstances
    ParallelArrays ParallelListComp PatternSignatures PolyKinds RankNTypes
    RecursiveDo RelaxedPolyRec ScopedTypeVariables StarIsType TypeInType
  ].freeze

  # Deprecated aliases this compiler has removed, with the name it still
  # accepts. The alias meant exactly the current name, so renaming it
  # changes nothing for the package either.
  RENAMED = {
    'PolymorphicComponents' => 'RankNTypes',
    'Rank2Types' => 'RankNTypes',
    'RecordPuns' => 'NamedFieldPuns'
  }.freeze


  SOURCE_GLOB = '**/*.{hs,lhs,hsc,hs-boot,hsig,x,y,chs,cpphs,bkp,cabal}'

  MARK = "\0strip\0"

  module_function

  # Rewrites every source and cabal file under dir. Returns the changed paths.
  def tree(dir, names = REMOVED, renamed = RENAMED)
    files = Dir.glob(File.join(dir, SOURCE_GLOB), File::FNM_DOTMATCH)
                .reject { |f| f.match?(%r{/dist(-newstyle)?/}) || f.include?('/.git/') || File.symlink?(f) || !File.file?(f) }
                .sort
    files.select { |f| file(f, names, renamed) }
  end

  # Rewrites one file. Returns whether it changed.
  def file(path, names = REMOVED, renamed = RENAMED)
    # Bytes in, bytes out: the names are ASCII, so a source in any
    # encoding comes through unchanged apart from them.
    old = File.binread(path)
    new = text(old, names, renamed, cabal: path.end_with?('.cabal', '.cabal.in'))
    return false if new == old

    File.binwrite(path, new)
    true
  end

  def text(text, names = REMOVED, renamed = RENAMED, cabal: false)
    return text unless (names + renamed.keys).any? { |n| text.include?(n) }

    out = cabal ? cabal_text(text, names, renamed) : haskell_text(text, names, renamed)
    drop_marked_lines(out)
  end

  # ---- Haskell sources -------------------------------------------------

  # The pragma name is case-insensitive to GHC, so {-# Language ... #-} too.
  PRAGMA = /(\{-#\s*)(LANGUAGE|OPTIONS_GHC|OPTIONS)\b(.*?)#-\}/mi

  def haskell_text(text, names, renamed)
    text.gsub(PRAGMA) do
      whole, opener, kind, body = Regexp.last_match(0), Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3)
      # An empty pragma, which may sit in a string or a comment, is not ours.
      next whole if body.strip.empty?

      language = kind.casecmp?('LANGUAGE')
      new_body = rewrite(body, names, renamed, flags: !language)
      if new_body.nil? then MARK
      elsif new_body == body then whole
      else "#{opener}#{kind}#{new_body}#-}"
      end
    end
  end

  # Renames the aliases in a list of names or of -X flags, then drops the
  # removed names and the aliases whose current name was already there.
  # Returns nil when nothing is left.
  def rewrite(body, names, renamed, flags:)
    # A name starts at a word boundary, a flag at its -X.
    prefix = flags ? '-X' : ''
    open = flags ? '-X' : '\b'
    drop = names.dup
    renamed.each do |old, new|
      body = body.gsub(/#{open}(No)?#{old}\b/) do
        polarity = Regexp.last_match(1)
        if body.match?(/#{open}#{polarity}#{new}\b/)
          drop << "#{polarity}#{old}"
          "#{prefix}#{polarity}#{old}"
        else
          "#{prefix}#{polarity}#{new}"
        end
      end
    end
    flags ? drop_flags(body, drop) : drop_names(body, drop)
  end

  # Removes the names, in either polarity, from a comma-separated list
  # that may span lines. Returns nil when nothing is left.
  def drop_names(body, names)
    pats = names.map { |n| /\b(No)?#{n}\b/ }.select { |p| body.match?(p) }
    return body if pats.empty?

    lines = body.split("\n", -1)
    first_was_blank = lines.first.match?(/\A\s*\z/)
    lines = lines.each_with_index.map do |line, i|
      pats.each { |p| line = drop_token(line, p) }
      # A continuation line left blank goes; the first line is the one
      # carrying the pragma opener and the last the closer, so they stay.
      line.match?(/\A\s*\z/) && i.positive? && i < lines.size - 1 ? nil : line
    end.compact
    if lines.size > 1 && !first_was_blank && lines.first.match?(/\A\s*\z/)
      lines.shift
      lines[0] = ' ' + lines[0].lstrip
    end
    body = lines.join("\n")
    body = body.gsub(/,\s*,/, ',').sub(/\A\s*,/, '').sub(/,\s*\z/, ' ')
    return nil if body.match?(/\A\s*\z/)

    # The body follows the pragma or field name directly: keep it separated.
    body.start_with?(' ', "\t", "\n") ? body : ' ' + body
  end

  # Removes one name (and a neighbouring comma) from one line.
  def drop_token(line, pat)
    if line.match?(/,\s*#{pat.source}(?=\s*(,|\z))/)
      line.sub(/\s*,\s*#{pat.source}(?=\s*(,|\z))/, '')
    elsif line.match?(/#{pat.source}\s*,/)
      line.sub(/#{pat.source}\s*,\s*/, '')
    else
      line.sub(/[ \t]*#{pat.source}/, '')
    end
  end

  # Removes -XName and -XNoName flags from an OPTIONS body. nil when
  # nothing is left.
  def drop_flags(body, names)
    names.each { |n| body = body.gsub(/\s*-X(No)?#{n}\b/, '') }
    body.match?(/\A\s*\z/) ? nil : body
  end

  # ---- cabal files -------------------------------------------------------

  FIELDS = /\A([ \t]*)(default-extensions|other-extensions|extensions|ghc-options)[ \t]*:/i

  def cabal_text(text, names, renamed)
    lines = text.split("\n", -1)
    out = []
    i = 0
    while i < lines.size
      m = lines[i].match(FIELDS)
      unless m
        out << lines[i]
        i += 1
        next
      end
      indent = m[1].size
      j = i + 1
      j += 1 while j < lines.size && (lines[j].match?(/\A\s*\z/) || lines[j][/\A[ \t]*/].size > indent)
      j -= 1 while j - 1 > i && lines[j - 1].match?(/\A\s*\z/)
      field = lines[i...j]
      value_start = m[0].size
      head = field[0][0, value_start]
      body = ([field[0][value_start..]] + field[1..]).join("\n")
      new_body = rewrite(body, names, renamed, flags: m[2].casecmp?('ghc-options'))
      if new_body.nil?
        # nothing left in the field
      elsif new_body == body
        out.concat(field)
      else
        out.concat((head + new_body).split("\n", -1))
      end
      i = j
    end
    out.join("\n")
  end

  # ---- shared --------------------------------------------------------------

  # Drops lines that held only a removed pragma (a bird track may remain).
  def drop_marked_lines(text)
    return text unless text.include?(MARK)

    text.split("\n", -1).reject { |l| l.match?(/\A[ \t]*>?[ \t]*(#{Regexp.escape(MARK)}[ \t]*)+\z/) }
        .map { |l| l.gsub(MARK, '') }.join("\n")
  end
end
