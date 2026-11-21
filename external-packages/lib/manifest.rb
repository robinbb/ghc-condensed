# frozen_string_literal: true

# manifest.yaml is the single source of truth for the corpus.
#
#   index_state: the Hackage index-state written into cabal.project
#   packages:    one entry per package with
#     name:     Hackage package name
#     version:  version at the pinned revision
#     path:     directory holding the .cabal file, relative to
#               external-packages/
#     tier:     1, 2 or 3
#     role:     root (chosen for coverage) or dep (pulled in by a root)
#     tests:    whether its test suites are run
#     flags:    cabal flags for the package, e.g. "+os-string" (optional)
#     constraints: extra solver constraints for the package's project,
#               e.g. "any.happy ==2.0.2" (optional)
#     env:      environment variables for its test run, e.g. {CI: 'true'}
#               (optional)
#     test_runs: argument strings for the test executable, one cabal test
#               run each, when a subset of its tests is wanted (optional)
#     source:   { git: URL, tag: TAG }, { git: URL, commit: SHA } or
#               { sdist: NAME-VERSION }
#     project:  name of the standalone project the package belongs to
#               (optional). Such packages live under projects/NAME/ and
#               are solved and built in their own cabal project, with the
#               exact dependency versions recorded in that project's
#               cabal.project.freeze, instead of in the tier projects.
#     expected: ok | build-failure | test-failure | flaky | unsolvable
#               (flaky: the test suite passes or fails nondeterministically)
#     reason:   free text; required when expected is not ok, or when a
#               root's tests are not run

require 'yaml'

class Manifest
  FILE = File.expand_path('../manifest.yaml', __dir__)
  EXPECTED = %w[ok build-failure test-failure flaky unsolvable].freeze

  attr_reader :packages
  attr_accessor :index_state

  def self.load(file = FILE)
    data = File.exist?(file) ? (YAML.safe_load(File.read(file)) || {}) : {}
    new(data['index_state'], (data['packages'] || []).map { |e| e.transform_keys(&:to_s) }, file)
  end

  def initialize(index_state, packages, file = FILE)
    @index_state = index_state
    @packages = packages
    @file = file
  end

  def save
    @packages.sort_by! { |e| [e['tier'], e['name'].downcase] }
    @packages.each do |e|
      next if EXPECTED.include?(e['expected'])

      raise ArgumentError, "#{e['name']}: bad expected value #{e['expected'].inspect}"
    end
    data = { 'index_state' => @index_state, 'packages' => @packages }
    File.write(@file, YAML.dump(data, line_width: 76))
  end

  def find(name)
    @packages.find { |e| e['name'] == name }
  end

  def add(entry)
    raise ArgumentError, "#{entry['name']} is already in the manifest" if find(entry['name'])

    @packages << entry
  end

  def roots(max_tier)
    @packages.select { |e| e['role'] == 'root' && e['tier'] <= max_tier }
  end

  # Packages that take part in dependency solving for the given tier.
  # Standalone projects solve on their own.
  def solvable(max_tier)
    @packages.select { |e| e['tier'] <= max_tier && e['expected'] != 'unsolvable' && !e['project'] }
  end

  # Names of the standalone projects with a package in tiers 1..max_tier.
  def projects(max_tier = Float::INFINITY)
    @packages.select { |e| e['project'] && e['tier'] <= max_tier }.map { |e| e['project'] }.uniq.sort
  end

  def project_entries(project)
    @packages.select { |e| e['project'] == project }
  end
end
