# frozen_string_literal: true

# Finds the per-instance pragmas a package needs now that
# OverlappingInstances and IncoherentInstances are gone. Reads the
# overlap errors in GHC output (a check.rb build log, or a testsuite log)
# and proposes, or applies, the
# per-instance pragma that resolves each: OVERLAPPING on the most
# specific matching instance when it can be edited, OVERLAPPABLE on the
# editable others when it cannot, INCOHERENT when no instance is most
# specific or the choice depends on an instantiation (what module-wide
# incoherence allowed). Instance heads are compared by one-way matching.
#
#   ruby external-packages/overlap-pragmas.rb [--apply] --root DIR LOG...
#
# Paths in the errors are resolved under DIR by suffix. Run, rebuild and
# run again until no proposal is left; then record the package's pragmas
# as a patch (see patches/README.md).
require 'set'
apply = ARGV.delete('--apply')
root = ARGV[ARGV.index('--root') + 1]; ARGV.delete_at(ARGV.index('--root')); ARGV.delete(root)

# ---- instance heads ------------------------------------------------------
def tokens(s)
  s.scan(/->|[()\[\],]|'?[A-Za-z_][\w.']*|[^\s()\[\],]+/)
end
# type ::= btype ('->' type)?
def parse_type(ts)
  l = parse_apps(ts)
  if ts.first == '->' then ts.shift; ['app', ['app', ['con', '->'], l], parse_type(ts)] else l end
end
def parse_apps(ts)
  t = parse_atom(ts)
  while ts.first && !['->', ')', ']', ','].include?(ts.first)
    t = ['app', t, parse_atom(ts)]
  end
  t
end
def parse_atom(ts)
  tok = ts.shift
  case tok
  when '('
    if ts.first == ')' then ts.shift; return ['con', '()'] end
    parts = [parse_type(ts)]
    while ts.first == ',' do ts.shift; parts << parse_type(ts) end
    ts.shift # ')'
    parts.size == 1 ? parts[0] : parts.reduce(['con', "(#{',' * (parts.size - 1)})"]) { |f, x| ['app', f, x] }
  when '['
    if ts.first == ']' then ts.shift; return ['con', '[]'] end
    inner = parse_type(ts); ts.shift
    ['app', ['con', '[]'], inner]
  else
    if tok == 'String' then ['app', ['con', '[]'], ['con', 'Char']]
    else tok =~ /\A'?[a-z_]/ && tok !~ /\./ ? ['var', tok] : ['con', tok.sub(/\A'/, '')]
    end
  end
end
def head_type(head)
  h = head.sub(/\A\[safe\] /, '').sub(/\Aforall\b[^.]*\.\s*/, '')
  depth = 0; cut = nil
  (0...h.size).each { |i| c = h[i]; depth += 1 if '([' .include?(c); depth -= 1 if ')]'.include?(c); cut = i if depth.zero? && h[i, 2] == '=>' }
  h = h[(cut + 2)..] if cut
  parse_apps(tokens(h.strip))
end
def match(pat, term, env)
  case pat[0]
  when 'var' then env.key?(pat[1]) ? env[pat[1]] == term : (env[pat[1]] = term; true)
  when 'con' then term[0] == 'con' && term[1] == pat[1]
  when 'app' then term[0] == 'app' && match(pat[1], term[1], env) && match(pat[2], term[2], env)
  end
end
def instance_of?(specific, general) = match(head_type(general), head_type(specific), {})

# A line that already carries a pragma gets the union of the two.
def merge(have, want)
  return 'INCOHERENT' if [have, want].include?('INCOHERENT')
  return have if have == want || have == 'OVERLAPS'
  'OVERLAPS'
end

# ---- the logs ------------------------------------------------------------
Inst = Struct.new(:head, :file, :line)
proposals = {}
ARGV.each do |log|
  text = File.read(log, encoding: 'BINARY').force_encoding('UTF-8').scrub
  text.scan(/Overlapping instances for (.+?)\n(.*?)(?=\n\s*• In |\n[^\s•]|\z)/m).each do |constraint, block|
    matching_text = block[/Matching instances:(.*?)(?:Potentially matching instances:|\z)/m, 1].to_s
    matching = matching_text.scan(/^\s*instance ([\s\S]+?)\s+-- Defined (?:at (\S+?):(\d+):\d+|in ‘[^’]+’)/).map { |h, f, l| Inst.new(h.gsub(/\s+/, ' ').strip, f, l&.to_i) }
    next if matching.empty?
    local = matching.select(&:file)
    next if local.empty?
    unifying = block.include?('depends on the instantiation')
    most = matching.select { |m| (matching - [m]).all? { |n| instance_of?(m.head, n.head) } }
    specific = most.size == 1 ? most.first : nil
    decision =
      if unifying || specific.nil?
        [[local.min_by { |i| [i.file, i.line] }, 'INCOHERENT']]
      elsif specific.file
        [[specific, 'OVERLAPPING']]
      else
        (local - [specific]).map { |i| [i, 'OVERLAPPABLE'] }
      end
    decision.each do |inst, pragma|
      key = [inst.file, inst.line]
      proposals[key] = proposals[key] ? [inst, merge(proposals[key][1], pragma), constraint.strip] : [inst, pragma, constraint.strip]
    end
  end
end

# ---- resolve and apply -------------------------------------------------
HEAD_RE = /\b(instance)([ \t]+)(?!\{-#)/
MARKED_RE = /\b(instance)([ \t]+)\{-# (OVERLAPPING|OVERLAPPABLE|OVERLAPS|INCOHERENT) #-\}[ \t]+/
all = Dir.glob(File.join(root, '**', '*.{hs,lhs,bkp,hsig}')).reject { |f| f.include?('/dist/') }
rows = proposals.values.sort_by { |i, _, _| [i.file, i.line] }
rows.each do |inst, pragma, constraint|
  cands = all.select { |f| f.end_with?("/#{inst.file}") || File.basename(f) == File.basename(inst.file) }
  path = cands.size == 1 ? cands.first : cands.find { |f| File.read(f).lines[inst.line - 1].to_s.include?(inst.head.sub(/\A\[safe\] /, '')[0, 20]) }
  status = path ? path.sub("#{root}/", '') : "UNRESOLVED(#{cands.size})"
  if apply && path
    lines = File.readlines(path)
    l = lines[inst.line - 1]
    if l && l =~ HEAD_RE
      lines[inst.line - 1] = l.sub(HEAD_RE) { "#{$1}#{$2}{-# #{pragma} #-} " }
      File.write(path, lines.join)
      status += ' APPLIED'
    elsif l && l =~ MARKED_RE
      merged = merge($3, pragma)
      lines[inst.line - 1] = l.sub(MARKED_RE) { "#{$1}#{$2}{-# #{merged} #-} " }
      File.write(path, lines.join)
      status += " MERGED->#{merged}"
    else
      status += ' NO-INSTANCE-ON-LINE'
    end
  end
  puts [status, inst.line, pragma, inst.head, constraint].join("\t")
end
puts "#{rows.size} proposal(s)"
