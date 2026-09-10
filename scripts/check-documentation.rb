#!/usr/bin/env ruby
# Copyright © 2026 Marc Rousavy @ Margelo

require 'json'
require 'pathname'
require 'uri'

root = File.expand_path('..', __dir__)
build = ARGV.fetch(0, File.join(root, 'build/documentation'))
sources = File.join(root, 'Sources') + '/'
graphs = Dir.glob(File.join(build, '**/symbol-graph/swift/**/*.symbols.json'))
abort 'No Swift symbol graphs found. Run scripts/build-documentation.sh first.' if graphs.empty?

# Compiler-generated conformances and inherited SDK members do not have their own
# declarations to document. Every symbol declared in our sources must have a comment.
symbols = {}
graphs.each do |path|
  JSON.parse(File.read(path)).fetch('symbols').each do |symbol|
    identifier = symbol.fetch('identifier').fetch('precise')
    next if identifier.include?('::SYNTHESIZED::')
    next unless %w[public open].include?(symbol['accessLevel'])

    uri = symbol.dig('location', 'uri')
    next unless uri
    source = URI::DEFAULT_PARSER.unescape(URI(uri).path)
    next unless source.start_with?(sources)

    symbols[identifier] = symbol
  end
end
abort 'No public VisionCamera declarations found in the symbol graphs.' if symbols.empty?

missing = symbols.values.select do |symbol|
  lines = symbol.dig('docComment', 'lines') || []
  lines.none? { |line| !line.fetch('text').strip.empty? }
end

missing.sort_by { |symbol| symbol.fetch('pathComponents') }.each do |symbol|
  location = symbol.fetch('location')
  source = URI::DEFAULT_PARSER.unescape(URI(location.fetch('uri')).path)
  relative = Pathname.new(source).relative_path_from(Pathname.new(root))
  line = location.fetch('position').fetch('line') + 1
  warn "#{relative}:#{line}: error: Missing documentation for #{symbol.fetch('pathComponents').join('.')}"
end

documented = symbols.length - missing.length
puts "Public API documentation: #{documented}/#{symbols.length} declarations."
abort 'Document all public declarations before publishing the documentation.' unless missing.empty?
