#!/usr/bin/env ruby
# frozen_string_literal: true

# Add packages to the corpus. For each package: look up its latest
# non-deprecated Hackage release in the local index, add the upstream git
# repository as a shallow clone of the upstream repository at the release tag (or
# reuse the submodule if the repository is already present), and record
# the package in manifest.yaml. Package sources are never tracked by this
# repository; the manifest is. Packages without a usable git repository
# or tag, packages with build-type Configure (whose git checkouts lack the
# generated configure script), and tags whose cabal file carries another
# version are vendored as unpacked sdists under vendored/.
#
# Usage:
#   add.rb [--tier N] [--role root|dep] [--closure] [--dry-run]
#          [--vendor] [--replace] NAME...
#   add.rb --refresh [--dry-run]
#   add.rb --remove NAME...
#   add.rb --fetch
#   add.rb --version V [options] NAME
#
# --closure adds the whole dependency closure of the named packages (which
# become roots; everything else becomes a dep), skipping packages already
# in the manifest and GHC boot packages. --replace removes the existing
# entry first and, unless --tier/--role are given, keeps its tier and role.
# --refresh moves multi-package submodules forward when one of their
# packages is behind its latest release. Run inside `nix develop` so that
# cabal and git are available. Needs network access.

require 'optparse'
require 'open3'
require 'fileutils'
require_relative 'lib/hackage'
require_relative 'lib/manifest'

ROOT = __dir__
REPO = File.expand_path('..', ROOT)

opts = { tier: nil, role: nil, closure: false, dry_run: false, vendor: false,
         replace: false, refresh: false, remove: false, version: nil, fetch: false }
OptionParser.new do |o|
  o.banner = 'Usage: add.rb [options] NAME...'
  o.on('--tier N', Integer, 'Tier for the added packages (default 1, or that of the replaced entry)') { |v| opts[:tier] = v }
  o.on('--role ROLE', %w[root dep], 'root or dep (default root, or that of the replaced entry)') { |v| opts[:role] = v }
  o.on('--closure', 'Add the dependency closure of the named packages') { opts[:closure] = true }
  o.on('--dry-run', 'Only report what would be done') { opts[:dry_run] = true }
  o.on('--vendor', 'Vendor the sdist even when a git tag exists') { opts[:vendor] = true }
  o.on('--replace', 'Remove an existing entry (and its submodule or vendored copy) first') { opts[:replace] = true }
  o.on('--refresh', 'Advance submodules whose packages are behind their latest release, then exit') { opts[:refresh] = true }
  o.on('--remove', 'Remove the named packages from the corpus, then exit') { opts[:remove] = true }
  o.on('--fetch', 'Materialise every manifest entry missing from the working tree, apply patches, then exit') { opts[:fetch] = true }
  o.on('--version V', 'Use this release instead of the latest (one package only)') { |v| opts[:version] = v }
end.parse!
names = ARGV
abort 'add.rb: no package names given' if names.empty? && !opts[:refresh] && !opts[:fetch]

def run(*cmd, chdir: REPO)
  out, err, st = Open3.capture3(*cmd, chdir: chdir)
  [st.success?, out, err]
end

def run!(*cmd, chdir: REPO)
  ok, out, err = run(*cmd, chdir: chdir)
  raise "#{cmd.join(' ')} failed:\n#{err}#{out}" unless ok

  out
end

# Turn a cabal source-repository location into an https git URL, or nil
# when it is not a git repository we can clone.
def git_url(loc)
  return nil if loc.nil? || loc.empty?
  return nil if loc =~ /darcs|hg\.|svn|cvs/i

  u = loc.strip
  u = u.sub(%r{^git@github\.com:}, 'https://github.com/')
  u = u.sub(%r{^git://}, 'https://').sub(%r{^http://}, 'https://')
  u = u.sub(%r{/+$}, '')
  u += '.git' unless u.end_with?('.git')
  return nil unless u.start_with?('https://')

  u
end

def owner_repo(url)
  m = url.match(%r{https://[^/]+/(?:(.+)/)?([^/]+)\.git$})
  [m[1].to_s.tr('/', '-'), m[2]]
end

# Origin URL of an existing checkout under external-packages/, or nil.
def checkout_url(dirname)
  dir = File.join(ROOT, dirname)
  return nil unless File.exist?(File.join(dir, '.git'))

  ok, out, = run('git', 'remote', 'get-url', 'origin', chdir: dir)
  ok ? out.strip : nil
end

# Directory under external-packages/ for a repository, reusing an existing
# checkout of the same URL and avoiding collisions between repositories
# that share a basename. Returns [dirname, :existing | :new].
def repo_dir(url)
  owner, repo = owner_repo(url)
  [repo, "#{owner}-#{repo}"].each do |cand|
    existing = checkout_url(cand)
    return [cand, :new] if existing.nil? && !Dir.exist?(File.join(ROOT, cand))
    return [cand, :existing] if existing && existing.sub(/\.git$/, '') == url.sub(/\.git$/, '')
  end
  raise "cannot pick a directory name for #{url}"
end

def resolve_tag(url, name, version)
  ok, out, = run('git', 'ls-remote', '--tags', url)
  return nil unless ok

  tags = out.lines.map { |l| l.split("\t")[1].to_s.strip.sub(%r{^refs/tags/}, '').sub(/\^\{\}$/, '') }.uniq
  v = version
  candidates = [
    "v#{v}", v, "#{name}-#{v}", "#{name}-v#{v}", "#{name}_#{v}", "#{name}_v#{v}",
    "release-#{v}", "release/#{v}", "#{name}/#{v}", "#{name}/v#{v}",
    "v#{v.tr('.', '_')}", v.tr('.', '_'), "#{name}-#{v.tr('.', '_')}",
    "v#{v.tr('.', '-')}", v.tr('.', '-'), "#{name}-#{v.tr('.', '-')}"
  ]
  candidates.each do |c|
    hit = tags.find { |t| t.casecmp?(c) }
    return hit if hit
  end
  nil
end

def find_cabal(dir, name)
  hits = Dir.glob(File.join(dir, '**', "#{name}.cabal"), File::FNM_DOTMATCH)
            .reject { |p| p.include?('dist-newstyle') || p.include?('/.git/') }
  hits.min_by(&:length)
end

def cabal_version(file)
  File.read(file)[/^version\s*:\s*(\S+)/i, 1]
end

# Shallow clone at the release tag. Package sources are not tracked by
# this repository (see .gitignore), so no submodule and no git add.
def add_submodule(url, dirname, tag)
  dir = File.join(ROOT, dirname)
  run!('git', 'clone', '--quiet', '--depth', '1', '--branch', tag, '--', url, dir)
end

def remove_submodule(dirname)
  FileUtils.rm_rf(File.join(ROOT, dirname))
  # Older checkouts were git submodules; drop any leftover registration.
  run('git', 'config', '-f', '.gitmodules', '--remove-section', "submodule.external-packages/#{dirname}")
  FileUtils.rm_rf(File.join(REPO, '.git', 'modules', 'external-packages', dirname))
end

# Move an existing submodule to TAG and update the recorded version and tag
# of every manifest package that lives in it.
def advance_submodule(manifest, dirname, url, tag)
  sub = File.join(ROOT, dirname)
  run!('git', 'fetch', '--depth', '1', 'origin', 'tag', tag, chdir: sub)
  run!('git', 'checkout', '-q', tag, chdir: sub)
  manifest.packages.each do |e|
    next unless e['path'].split('/').first == dirname && e['source'].key?('git')

    cabal = find_cabal(sub, e['name'])
    e['version'] = cabal_version(cabal) if cabal
    e['source'] = { 'git' => url, 'tag' => tag }
  end
end

def current_tag(sub)
  ok, out, = run('git', 'describe', '--tags', '--exact-match', 'HEAD', chdir: sub)
  return out.strip if ok

  run!('git', 'rev-parse', 'HEAD', chdir: sub).strip
end

def vendor_sdist(name, version)
  dest = File.join(ROOT, 'vendored')
  FileUtils.mkdir_p(dest)
  target = File.join(dest, name)
  return target if Dir.exist?(target)

  run!('cabal', 'get', "#{name}-#{version}", '--destdir', dest, chdir: ROOT)
  FileUtils.mv(File.join(dest, "#{name}-#{version}"), target)
  target
end

# Returns a manifest entry for the package, obtaining its source first.
def obtain(manifest, pkg, role, tier, dry_run, vendor: false)
  entry = { 'name' => pkg.name, 'version' => pkg.version, 'tier' => tier,
            'role' => role.to_s, 'expected' => 'ok' }
  url = git_url(pkg.repo)
  note = nil
  if pkg.build_type =~ /configure/i
    url = nil
    note = 'build-type Configure needs the sdist'
  elsif vendor
    url = nil
    note = 'vendored on request'
  elsif url.nil?
    note = pkg.repo.to_s.empty? ? 'no source repository listed' : "not a git repository: #{pkg.repo}"
  end
  if url
    dirname, state = repo_dir(url)
    sub = File.join(ROOT, dirname)
    tag = nil
    if state == :new
      tag = resolve_tag(url, pkg.name, pkg.version)
      if tag.nil?
        note = "no tag for #{pkg.version} in #{url}"
      elsif dry_run
        puts "  would add submodule #{dirname} at #{tag}"
      else
        begin
          add_submodule(url, dirname, tag)
        rescue RuntimeError => e
          note = "submodule add failed: #{e.message.lines.first.to_s.strip}"
          remove_submodule(dirname)
        end
      end
    elsif !dry_run
      # The repository is already a submodule for another package. If this
      # package is behind its latest release there, move to its tag.
      cabal = find_cabal(sub, pkg.name)
      if cabal && Gem::Version.new(cabal_version(cabal).to_s) < Gem::Version.new(pkg.version) &&
         (newer = resolve_tag(url, pkg.name, pkg.version))
        puts "  advancing #{dirname} to #{newer}"
        advance_submodule(manifest, dirname, url, newer)
        tag = newer
      end
    end
    if Dir.exist?(sub)
      cabal = find_cabal(sub, pkg.name)
      found = cabal && cabal_version(cabal)
      if cabal.nil?
        note = "#{pkg.name}.cabal not found in #{dirname}"
      elsif found != pkg.version && state == :new
        # The tag points at a commit with another version (some upstreams
        # tag before bumping); the sdist is the real release.
        note = "tag #{tag} carries version #{found}, not #{pkg.version}"
        remove_submodule(dirname) unless dry_run
      else
        entry['path'] = File.dirname(cabal).sub("#{ROOT}/", '')
        entry['version'] = found || pkg.version
        entry['source'] = { 'git' => url, 'tag' => tag || current_tag(sub) }
      end
    end
  end
  unless entry['path']
    if dry_run
      puts "  would vendor sdist #{pkg.name}-#{pkg.version} (#{note})"
    else
      vendor_sdist(pkg.name, pkg.version)
      entry['path'] = "vendored/#{pkg.name}"
      entry['source'] = { 'sdist' => "#{pkg.name}-#{pkg.version}" }
      entry['note'] = note
    end
  end
  # cabal's `tests: True` is all-or-nothing for a package, so tests can
  # only run when every buildable suite is satisfiable in the corpus.
  buildable = pkg.test_suites.select { |t| t[:buildable] }
  fragile = buildable - pkg.runnable_tests
  entry['tests'] = role == :root && buildable.any? && fragile.empty?
  if role == :root && buildable.any? && !entry['tests']
    needs = fragile.flat_map { |t| t[:deps] & Hackage::FRAGILE.to_a }.uniq
    entry['reason'] = "test suite #{fragile.map { |t| t[:name] }.join(', ')} needs #{needs.join(', ')}"
  end
  entry
end

# Remove a package's entry and, when nothing else uses it, its submodule or
# vendored directory.
def remove(manifest, entry)
  path = entry['path']
  top = path.split('/').first
  shared = manifest.packages.any? { |e| !e.equal?(entry) && e['path'].split('/').first == top }
  if entry['source'].key?('sdist')
    FileUtils.rm_rf(File.join(ROOT, path))
  elsif !shared
    remove_submodule(top)
  end
  manifest.packages.delete(entry)
end

index = Hackage::Index.new(cache: File.join(ROOT, 'dist', 'hackage-index.cache'))
manifest = Manifest.load

if opts[:refresh]
  behind = manifest.packages.select do |e|
    e['source'].key?('git') && (p = index.package(e['name'])) &&
      Gem::Version.new(p.version) > Gem::Version.new(e['version'])
  end
  puts "add.rb: #{behind.size} submodule package(s) behind their latest release"
  behind.group_by { |e| e['path'].split('/').first }.each do |dirname, entries|
    url = entries.first['source']['git']
    sub = File.join(ROOT, dirname)
    tags = entries.filter_map do |e|
      pkg = index.package(e['name'])
      tag = resolve_tag(url, pkg.name, pkg.version)
      puts "  #{e['name']}: #{e['version']} -> #{pkg.version}#{tag ? " (tag #{tag})" : ': no tag'}"
      tag
    end.uniq
    next if tags.empty? || opts[:dry_run]

    # A repository hosting several packages moves once, to the newest of
    # the release tags its packages ask for.
    tags.each { |t| run!('git', 'fetch', '--depth', '1', 'origin', 'tag', t, chdir: sub) }
    newest = tags.max_by { |t| run!('git', 'log', '-1', '--format=%ct', t, chdir: sub).to_i }
    puts "  #{dirname}: checking out #{newest}"
    advance_submodule(manifest, dirname, url, newest)
    manifest.save
  end
  exit 0
end

# Rebuild the working tree from the manifest: submodules at their recorded
# tags, vendored sdists, then the patches. The package sources are not
# committed to this repository; the manifest is.
if opts[:fetch]
  manifest.packages.each do |e|
    top = e['path'].split('/').first
    next if Dir.exist?(File.join(ROOT, top))

    src = e['source']
    if src['git']
      puts "clone #{top} at #{src['tag']}"
      add_submodule(src['git'], top, src['tag']) unless opts[:dry_run]
    else
      puts "sdist #{src['sdist']}"
      vendor_sdist(e['name'], e['version']) unless opts[:dry_run]
    end
  end
  Dir.glob(File.join(ROOT, 'patches', '*.patch')).sort.each do |p|
    next if opts[:dry_run]

    ok, = run('git', 'apply', '--check', p)
    if ok
      run!('git', 'apply', p)
      puts "applied #{File.basename(p)}"
    else
      puts "#{File.basename(p)}: already applied or does not apply"
    end
  end
  exit 0
end

if opts[:remove]
  names.each do |n|
    e = manifest.find(n)
    next warn("#{n}: not in the manifest") unless e

    remove(manifest, e)
    puts "removed #{n}"
  end
  manifest.save
  exit 0
end

members = if opts[:closure]
            index.closure(names)
          else
            names.to_h { |n| [n, (opts[:role] || 'root').to_sym] }
          end
missing = members.select { |_, r| r == :missing }.keys
warn "add.rb: not in the Hackage index: #{missing.join(' ')}" unless missing.empty?

inherited = {}
if opts[:replace]
  members.each_key do |n|
    next unless (e = manifest.find(n))

    inherited[n] = { tier: e['tier'], role: e['role'] }
    remove(manifest, e)
  end
  manifest.save
end

todo = members.reject { |n, r| r == :missing || manifest.find(n) }
puts "add.rb: #{todo.size} package(s) to add, #{members.size - todo.size - missing.size} already present"
abort 'add.rb: --version takes exactly one package' if opts[:version] && todo.size != 1
todo.each_with_index do |(name, role), i|
  pkg = index.package(name, version: opts[:version])
  tier = opts[:tier] || inherited.dig(name, :tier) || 1
  role = (opts[:role] || inherited.dig(name, :role) || role).to_sym
  puts "[#{i + 1}/#{todo.size}] #{name}-#{pkg.version} (#{role}, tier #{tier})"
  begin
    entry = obtain(manifest, pkg, role, tier, opts[:dry_run], vendor: opts[:vendor])
  rescue RuntimeError => e
    warn "  failed: #{e.message.lines.first.to_s.strip}"
    next
  end
  next if opts[:dry_run]

  manifest.add(entry)
  manifest.save
  puts "  #{entry['path']} (#{entry['source'].to_a.flatten.join(' ')})"
end
