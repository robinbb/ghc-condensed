# frozen_string_literal: true

# Checks that every patch under patches/ still applies on a fresh fetch.
# A patch is a diff against the stripped tree, since `add.rb --fetch`
# strips every package before it applies the patches. A removal whose
# strip touches a patch's context, or whose name a patch adds, leaves the
# patch stale: `git apply --check` fails and add.rb skips the patch with a
# one-line message, or the patch puts back a pragma the compiler rejects.
# For each patch this rebuilds the package's pristine source in a scratch
# directory (the sdist tarball from cabal's cache, or `git archive` of the
# checkout at the manifest's tag), strips it as add.rb does, applies the
# patch and compares the patched files with the working copy.
#
#   ruby external-packages/audit-patches.rb [--keep DIR] [NAME...]
#
# Prints one row per patch and exits 1 if any patch fails to apply, puts
# back a stripped name, or leaves a file that differs from the working
# copy. Run it after every removal. A stale patch is regenerated as the
# diff between the stripped pristine source, kept under DIR with --keep,
# and the working copy (see patches/README.md).
require 'fileutils'
require 'open3'
require 'tmpdir'
require 'yaml'
require_relative 'lib/strip'

ROOT = File.expand_path(__dir__)
REPO = File.dirname(ROOT)
REL = File.basename(ROOT)
CACHE = File.expand_path('~/.cache/cabal/packages/hackage.haskell.org')
MANIFEST = YAML.load_file(File.join(ROOT, 'manifest.yaml'))['packages']

keep = nil
if (i = ARGV.index('--keep'))
  keep = File.expand_path(ARGV[i + 1])
  ARGV.slice!(i, 2)
end
only = ARGV.dup

# The checkout holding a manifest path: the nearest ancestor with a .git.
def checkout_root(path)
  r = path
  r = File.dirname(r) until File.exist?(File.join(REPO, r, '.git')) || r == REL
  r
end

def untar(name, version, dest)
  tar = File.join(CACHE, name, version, "#{name}-#{version}.tar.gz")
  return "no tarball at #{tar}" unless File.exist?(tar)

  Dir.mktmpdir do |tmp|
    system('tar', '-xzf', tar, '-C', tmp) or return "cannot unpack #{tar}"
    FileUtils.mkdir_p(File.dirname(dest))
    FileUtils.mv(File.join(tmp, "#{name}-#{version}"), dest)
  end
  nil
end

# Materialises the pristine source a patch applies to under mirror, laid
# out as in the repository. Returns [description, dirs to strip, error].
def pristine(base, files, mirror)
  if base.start_with?('purescript-')
    name = base.sub('purescript-', '')
    dir = files.first.split('/')[0, 5].join('/')
    version = File.basename(dir).sub("#{name}-", '')
    err = untar(name, version, File.join(mirror, dir))
    return ['sdist', [dir], err]
  end
  entry = MANIFEST.find { |e| e['name'] == base }
  return [nil, [], 'no manifest entry of that name'] unless entry

  path = File.join(REL, entry['path'])
  if entry['source']['git']
    root = checkout_root(path)
    tag = entry['source']['tag']
    FileUtils.mkdir_p(File.join(mirror, root))
    ok = system("git -C #{File.join(REPO, root)} archive #{tag} 2>/dev/null | tar -x -C #{File.join(mirror, root)}")
    return ["git #{tag}", [], "cannot archive #{tag} from #{root}"] unless ok && !Dir.empty?(File.join(mirror, root))

    dirs = MANIFEST.map { |e| File.join(REL, e['path']) }.select { |p| p == root || p.start_with?("#{root}/") }
    ["git #{tag}", dirs, nil]
  else
    err = untar(base, entry['version'], File.join(mirror, path))
    ['sdist', [path], err]
  end
end

def audit(patch, scratch)
  base = File.basename(patch, '.patch')
  files = File.readlines(patch).grep(%r{^\+\+\+ b/}).map { |l| l.sub('+++ b/', '').strip }.uniq
  mirror = File.join(scratch, base)
  FileUtils.rm_rf(mirror)
  src, dirs, err = pristine(base, files, mirror)
  return [base, src.to_s, '-', 'NO SOURCE', '-', err] if err

  stripped = dirs.sum { |d| Dir.exist?(File.join(mirror, d)) ? Strip.tree(File.join(mirror, d)).size : 0 }
  out, st = Open3.capture2e('git', 'apply', '--check', patch, chdir: mirror)
  return [base, src, stripped, 'FAILS', '-', out.lines.first.to_s.strip] unless st.success?

  system('git', 'apply', patch, chdir: mirror) or abort "audit-patches: cannot apply #{patch}"
  same = files.count { |f| FileUtils.identical?(File.join(mirror, f), File.join(REPO, f)) }
  back = files.select { |f| t = File.binread(File.join(mirror, f)); Strip.text(t) != t }
  note = []
  note << "puts back a stripped name: #{back.map { |f| File.basename(f) }.join(' ')}" unless back.empty?
  note << 'differs from the working copy' if same < files.size
  [base, src, stripped, 'applies', "#{same}/#{files.size}", note.join('; ')]
end

patches = Dir.glob(File.join(ROOT, 'patches', '*.patch')).sort
patches.select! { |p| only.include?(File.basename(p, '.patch')) } unless only.empty?
abort 'audit-patches: no such patch' if patches.empty?

run = lambda do |scratch|
  rows = patches.map { |p| audit(p, scratch) }
  puts format('%-32s %-24s %5s %-8s %-6s %s', 'patch', 'pristine', 'strip', 'apply', 'same', 'note')
  rows.each { |r| puts format('%-32s %-24s %5s %-8s %-6s %s', *r) }
  bad = rows.reject { |r| r[3] == 'applies' && r[5].empty? }
  puts
  if bad.empty?
    puts "audit-patches: all #{rows.size} patches apply to a stripped fresh fetch and reproduce the working copies"
  else
    puts "audit-patches: needing attention: #{bad.map(&:first).join(', ')}"
    puts "stripped pristine sources kept under #{scratch}" if scratch == keep
  end
  bad.empty?
end

ok = if keep
       FileUtils.mkdir_p(keep)
       run.call(keep)
     else
       Dir.mktmpdir('audit-patches') { |d| run.call(d) }
     end
exit(ok ? 0 : 1)
