# frozen_string_literal: true

# Read-only access to the local Hackage index (01-index.tar, maintained by
# `cabal update`). Parses each package's latest cabal file with conditionals
# evaluated for a given GHC version on Linux/x86_64, and computes dependency
# closures over non-boot packages.

require 'rubygems/package'
require 'set'
require 'time'

module Hackage
  # Packages shipped with GHC. They never go into the corpus.
  BOOT = %w[
    base ghc-prim ghc-bignum ghc-internal template-haskell containers
    bytestring text deepseq array binary directory filepath process unix time
    transformers mtl stm exceptions parsec pretty haskeline terminfo xhtml
    os-string file-io semaphore-compat hpc ghc-boot ghc-boot-th ghc-heap
    ghc-compact ghc-experimental ghci integer-gmp Cabal Cabal-syntax ghc rts
    ghc-platform ghc-toolchain template-haskell-lift
    template-haskell-quasiquoter Win32 haddock-library haddock-api
    libffi-clib system-cxx-std-lib
  ].to_set.freeze

  # Test dependencies that use the GHC API and break on development
  # compilers. A test suite needing one of these is not run.
  FRAGILE = %w[doctest hint ghc-paths inspection-testing
               tasty-inspection-testing].to_set.freeze

# Evaluate a cabal version constraint such as "<2.7.0.0 || >2.7.0.0" or
# ">=1.2 && <1.3" against a version. Unparseable constraints allow
# everything.
def self.version_allowed?(constraint, version)
  expr = constraint.sub(/^[A-Za-z0-9-]+\s*/, '')
  tokens = expr.scan(/\|\||&&|\(|\)|==|>=|<=|>|<|\^>=|[0-9][0-9.]*(?:\.\*)?/)
  pos = 0
  parse_or = nil
  parse_atom = lambda do
    tok = tokens[pos]
    pos += 1
    case tok
    when '('
      v = parse_or.call
      pos += 1 if tokens[pos] == ')'
      v
    when '==', '>=', '<=', '>', '<', '^>='
      rhs = tokens[pos]
      pos += 1
      if rhs.to_s.end_with?('.*')
        prefix = rhs.sub(/\.\*$/, '')
        version.to_s == prefix || version.to_s.start_with?("#{prefix}.")
      else
        r = Gem::Version.new(rhs)
        case tok
        when '==' then version == r
        when '>=' then version >= r
        when '<=' then version <= r
        when '>' then version > r
        when '<' then version < r
        when '^>=' then version >= r && version.segments[0, 2] == r.segments[0, 2]
        end
      end
    else
      true
    end
  end
  parse_and = lambda do
    v = parse_atom.call
    while tokens[pos] == '&&'
      pos += 1
      v = parse_atom.call && v
    end
    v
  end
  parse_or = lambda do
    v = parse_and.call
    while tokens[pos] == '||'
      pos += 1
      v = parse_and.call || v
    end
    v
  end
  parse_or.call
rescue StandardError
  true
end

  def self.default_index_path
    File.expand_path('~/.cache/cabal/packages/hackage.haskell.org/01-index.tar')
  end

  Line = Struct.new(:indent, :text)

  Package = Struct.new(:name, :version, :uploaded, :lib_deps, :exe_deps,
                       :test_suites, :tools, :build_type, :extra_libraries,
                       :pkgconfig, :repo, keyword_init: true) do
    # Dependencies needed to build the library and executables.
    def build_deps
      (lib_deps + exe_deps).uniq
    end

    # Test suites whose dependencies can be satisfied inside the corpus.
    def runnable_tests
      test_suites.select { |t| t[:buildable] && (t[:deps] & FRAGILE.to_a).empty? }
    end

    def skipped_tests
      test_suites - runnable_tests
    end
  end

  class Index
    attr_reader :ghc_version

    def initialize(path: Hackage.default_index_path, ghc_version: '10.1',
                   cache: nil)
      @path = path
      @ghc_version = Gem::Version.new(ghc_version)
      @cache = cache
      @latest = load_latest
      @packages = {}
    end

    def names
      @latest.keys
    end

    def include?(name)
      @latest.key?(name)
    end

# The package at its chosen latest version, or at VERSION when given
# (that cabal file is then read from the tarball on demand).
def package(name, version: nil)
  if version
    entry = find_version(name, version)
    return entry ? parse_package(name, *entry) : nil
  end
  return @packages[name] if @packages.key?(name)

  entry = @latest[name]
  @packages[name] = entry ? parse_package(name, *entry) : nil
end

def find_version(name, version)
  want = Gem::Version.new(version)
  found = nil
  each_entry do |n, ver, e|
    found = [ver, e.read, e.header.mtime] if n == name && ver == want
  end
  found
end

    # Transitive closure over non-boot packages. Roots contribute their
    # runnable test-suite dependencies; everything else contributes build
    # dependencies only. Returns { name => :root | :dep | :missing }.
    def closure(roots)
      members = {}
      work = roots.map { |r| [r, :root] }
      until work.empty?
        name, role = work.shift
        next if BOOT.include?(name)
        next if members[name] && (members[name] == :root || role != :root)

        members[name] = role
        pkg = package(name)
        unless pkg
          members[name] = :missing
          next
        end
        deps = pkg.build_deps
        if role == :root
          pkg.runnable_tests.each { |t| deps += t[:deps] + t[:tools] }
        end
        deps.each { |d| work << [d, :dep] unless BOOT.include?(d) }
      end
      members
    end

    private

    def load_latest
      stat = File.stat(@path)
      key = [stat.mtime.to_i, stat.size]
      if @cache && File.exist?(@cache)
        cached_key, data = Marshal.load(File.binread(@cache))
        return data if cached_key == key
      end
      data = scan_index
      if @cache
        File.binwrite(@cache, Marshal.dump([key, data]))
      end
      data
    end

# Two passes over the tarball. The first collects every version of every
# package and the preferred-versions constraints that Hackage uses to
# deprecate releases; the second extracts the cabal file of the newest
# version each package is allowed to have. Later entries for the same
# version are cabal-file revisions and replace earlier ones.
def scan_index
  versions = Hash.new { |h, k| h[k] = [] }
  preferred = {}
  each_entry do |name, ver, entry|
    if ver == 'preferred-versions'
      preferred[name] = entry.read.strip
    elsif ver
      versions[name] << ver
    end
  end
  chosen = {}
  versions.each do |name, vs|
    allowed = vs.uniq.sort
    if (c = preferred[name]) && !c.empty?
      ok = allowed.select { |v| Hackage.version_allowed?(c, v) }
      allowed = ok unless ok.empty?
    end
    chosen[name] = allowed.last
  end
  latest = {}
  each_entry do |name, ver, entry|
    next unless ver && chosen[name] == ver

    latest[name] = [ver, entry.read, entry.header.mtime]
  end
  latest
end

# Yields [name, version_or_nil, entry] for cabal files and
# [name, 'preferred-versions', entry] for deprecation lists.
def each_entry
  File.open(@path, 'rb') do |f|
    Gem::Package::TarReader.new(f) do |tar|
      tar.each do |e|
        fn = e.full_name
        parts = fn.split('/')
        if fn.end_with?('.cabal') && parts.size == 3
          v = begin
            Gem::Version.new(parts[1])
          rescue ArgumentError
            next
          end
          yield parts[0], v, e
        elsif parts.size == 2 && parts[1] == 'preferred-versions'
          yield parts[0], 'preferred-versions', e
        end
      end
    end
  end
end

    def lex(txt)
      out = []
      txt.each_line do |raw|
        l = raw.sub(/\s--.*$/, '').sub(/^--.*$/, '').rstrip
        next if l.strip.empty?

        out << Line.new(l[/^\s*/].size, l.strip)
      end
      out
    end

    SECTION = /^(library|test-suite|benchmark|executable|common|flag|
                 source-repository|custom-setup|foreign-library)\b\s*(.*)$/ix
    FIELD = /^([A-Za-z][A-Za-z0-9-]*)\s*:\s*(.*)$/

    # Returns nested nodes:
    #   [:field, key, value]
    #   [:if, condition, then_nodes, else_nodes]
    #   [:section, kind, name, nodes]
    def parse_block(lines, i, indent)
      nodes = []
      while i < lines.size && lines[i].indent >= indent
        ln = lines[i]
        return parse_block(lines, i, ln.indent) if ln.indent > indent && nodes.empty?

        if ln.text =~ /^if\b\s*(.*)$/i
          cond = Regexp.last_match(1)
          sub, i = parse_block(lines, i + 1, ln.indent + 1)
          els = []
          if i < lines.size && lines[i].indent == ln.indent && lines[i].text =~ /^else\b/i
            els, i = parse_block(lines, i + 1, ln.indent + 1)
          end
          nodes << [:if, cond, sub, els]
        elsif ln.text =~ SECTION
          kind = Regexp.last_match(1).downcase
          name = Regexp.last_match(2).strip
          sub, i = parse_block(lines, i + 1, ln.indent + 1)
          nodes << [:section, kind, name, sub]
        elsif ln.text =~ FIELD
          key = Regexp.last_match(1).downcase
          val = +Regexp.last_match(2)
          i += 1
          while i < lines.size && lines[i].indent > ln.indent &&
                lines[i].text !~ FIELD && lines[i].text !~ /^(if|else)\b/i
            val << ' ' << lines[i].text
            i += 1
          end
          nodes << [:field, key, val]
        else
          i += 1
        end
      end
      [nodes, i]
    end

    def eval_cond(c, flags)
      s = c.strip
      s = s.gsub(/impl\(\s*ghc\s*([<>=!]+)\s*([0-9.]+)\s*\)/i) do
        op = Regexp.last_match(1)
        v = Gem::Version.new(Regexp.last_match(2))
        r = case op
            when '==' then @ghc_version == v
            when '>=' then @ghc_version >= v
            when '>' then @ghc_version > v
            when '<=' then @ghc_version <= v
            when '<' then @ghc_version < v
            else false
            end
        r ? 'true' : 'false'
      end
      s = s.gsub(/impl\(\s*ghc\s*\)/i, 'true').gsub(/impl\([^)]*\)/i, 'false')
      s = s.gsub(/os\(\s*linux\s*\)/i, 'true').gsub(/os\([^)]*\)/i, 'false')
      s = s.gsub(/arch\(\s*x86_64\s*\)/i, 'true').gsub(/arch\([^)]*\)/i, 'false')
      s = s.gsub(/flag\(\s*([A-Za-z0-9_-]+)\s*\)/i) do
        flags.fetch(Regexp.last_match(1).downcase, false) ? 'true' : 'false'
      end
      s = s.gsub('!', ' not ').gsub('&&', ' and ').gsub('||', ' or ')
      return false unless s =~ /\A[\s()a-z]+\z/ && s !~ /\b(then|the|end)\b/

      begin
        eval(s) # rubocop:disable Security/Eval -- only true/false/not/and/or
      rescue SyntaxError, StandardError
        false
      end
    end

    def collect(nodes, flags, acc)
      nodes.each do |n|
        case n[0]
        when :field then (acc[n[1]] ||= []) << n[2]
        when :if then collect(eval_cond(n[1], flags) ? n[2] : n[3], flags, acc)
        end
      end
      acc
    end

    def depnames(vals)
      (vals || []).join(',').gsub(/:\{[^}]*\}/, '').split(',')
                  .map { |d| d.strip[/^[A-Za-z][A-Za-z0-9-]*/] }.compact.uniq
    end

    def parse_package(name, version, txt, mtime)
      nodes, = parse_block(lex(txt), 0, 0)
      flags = {}
      nodes.each do |n|
        next unless n[0] == :section && n[1] == 'flag'

        f = collect(n[3], {}, {})
        flags[n[2].downcase] = (f['default'] || ['true']).first.strip.downcase == 'true'
      end
      commons = {}
      nodes.each { |n| commons[n[2]] = n[3] if n[0] == :section && n[1] == 'common' }
      top = collect(nodes.reject { |n| n[0] == :section }, flags, {})
      section_fields = lambda do |n|
        body = n[3]
        imports = depnames(collect(body, flags, {})['import'])
        extra = imports.flat_map { |c| commons[c] || [] }
        collect(extra + body, flags, {})
      end
      lib = depnames(top['build-depends'])
      exe = []
      tests = []
      tools = []
      extl = []
      pkgc = []
      repo = nil
      nodes.each do |n|
        next unless n[0] == :section

        f = section_fields.(n)
        extl += (f['extra-libraries'] || []).join(' ').split(/[\s,]+/)
        pkgc += (f['pkgconfig-depends'] || []).join(',').split(',')
                .map { |s| s.strip[/^[A-Za-z0-9_.+-]+/].to_s }
        section_tools = depnames(f['build-tool-depends']) +
                        (f['build-tools'] || []).join(',').split(',')
                        .map { |s| s.strip[/^[A-Za-z0-9-]+/].to_s }
        case n[1]
        when 'library'
          lib += depnames(f['build-depends'])
          tools += section_tools
        when 'executable'
          exe += depnames(f['build-depends'])
          tools += section_tools
        when 'test-suite'
          buildable = (f['buildable'] || ['true']).first.strip.downcase != 'false'
          tests << { name: n[2], deps: depnames(f['build-depends']) - [name],
                     tools: section_tools.reject(&:empty?), buildable: buildable }
        when 'source-repository'
          loc = (f['location'] || []).first.to_s.strip
          repo ||= loc unless loc.empty?
        end
      end
      Package.new(
        name: name, version: version.to_s, uploaded: Time.at(mtime),
        lib_deps: (lib - [name]).uniq, exe_deps: (exe - [name]).uniq,
        test_suites: tests, tools: tools.reject(&:empty?).uniq,
        build_type: (top['build-type'] || ['Simple']).first.strip,
        extra_libraries: extl.reject(&:empty?).uniq,
        pkgconfig: pkgc.reject(&:empty?).uniq, repo: repo
      )
    end
  end
end
