#!/usr/bin/env ruby
# frozen_string_literal: true

# Collects the warnings that the compilers emit during a Hadrian build, so
# that the builds before and after a change can be compared.
#
#   ruby build-warnings/warnings.rb extract BUILD.log > baseline.txt
#   ruby build-warnings/warnings.rb compare baseline.txt BUILD.log
#
# A warning is any `path:line:col: warning:` message in the log, from GHC
# or from the C compiler, plus the conflict and unused-symbol counts that
# happy prints; the Nix, configure and cpp noise in a log has another
# shape. Each site is listed once, although Hadrian compiles every module
# once per way (vanilla, profiling, dynamic). The extracted list is itself
# a valid input, so `compare` takes logs and extracted lists alike. The
# comparison ignores line and column numbers and counts the sites per
# file, flag and message, so an edit above a warning does not register as
# a change. It exits 1 when a warning appears that the baseline lacks.
#
# Hadrian interleaves the output of parallel jobs, so a warning's message
# line can be separated from its header; such a site keeps the message
# from another way's compile of the same module when there is one.

LOCATION = /(?<path>[^\s:]+):(?<line>\d+):(?<col>\d+(?:-\d+)?)/
WARNING = /\A#{LOCATION}: warning:(?<rest>.*)\z/
HAPPY_COUNTS = 'unused terminals|unused rules|shift/reduce conflicts|' \
               'reduce/reduce conflicts'
HAPPY = /\A(?:#{HAPPY_COUNTS}): \d+\z/
FLAG = /\[(?:GHC-\d+|-W[^\]]+)\]/

Site = Struct.new(:path, :line, :col, :flag, :message) do
  def key = [path, flag, message]

  def to_s
    "#{path}:#{line}:#{col}: warning: #{flag} #{message}".squeeze(' ')
  end
end

def squeeze(text) = text.strip.gsub(/\s+/, ' ')

# Every warning site in a log or an extracted list, each once.
def sites(file)
  lines = File.readlines(file, chomp: true)
  found = {}
  lines.each_with_index do |line, i|
    if HAPPY.match?(line)
      site = Site.new('happy', 0, '0', '', line)
      found[site.to_a] = site
      next
    end
    m = WARNING.match(line) or next
    flag = m[:rest].scan(FLAG).join(' ')
    message = squeeze(m[:rest].gsub(FLAG, ''))
    if message.empty?
      following = lines[i + 1..].take_while { |l| l.start_with?(' ') }
      message = squeeze(following.find { |l| !l.strip.empty? } || '')
    end
    path = m[:path].sub(%r{\A_build[^/]*/}, '_build/')
    site = Site.new(path, m[:line].to_i, m[:col], flag, message)
    id = [path, site.line, site.col, flag]
    found[id] = site unless found[id] && message.empty?
  end
  found.values
end

def extract(log)
  root = File.expand_path('..', __dir__)
  head = `git -C #{root} rev-parse --short HEAD`.strip
  date = Time.now.utc.strftime('%Y-%m-%d')
  puts "# Warnings in #{File.basename(log)}, extracted #{date} at #{head}"
  sites(log).sort_by { |s| [s.path, s.line, s.col.to_s, s.flag, s.message] }
            .each { |s| puts s }
end

def compare(base, log)
  tally = ->(file) { sites(file).group_by(&:key).transform_values(&:size) }
  before = tally.call(base)
  after = tally.call(log)
  up = down = 0
  (before.keys | after.keys).sort.each do |key|
    nb = before.fetch(key, 0)
    na = after.fetch(key, 0)
    next if nb == na

    na > nb ? up += 1 : down += 1
    puts "#{na > nb ? '+' : '-'} #{key.join(' ')} " \
         "(#{na} site(s), was #{nb})"
  end
  puts "#{base}: #{before.values.sum} sites; #{log}: #{after.values.sum} " \
       "sites; #{up} warning(s) up, #{down} down"
  exit(up.zero? ? 0 : 1)
end

case ARGV
in ['extract', log] then extract(log)
in ['compare', base, log] then compare(base, log)
else
  warn "usage: #{$PROGRAM_NAME} extract LOG | compare BASELINE LOG"
  exit 2
end
