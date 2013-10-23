#!/usr/bin/env ruby

books = Dir.entries(Dir.pwd).select do |entry|
  File.directory?(entry) && !entry.match(%r(^[.]))
end

deps = []

books.each do |book|
  path ="#{book}/metadata.rb"
  begin
    File.open(path, 'r') do |file|
      file.each_line do |line|
        line.match(%r(^depends "(.*)")) do |match|
          deps << match[1]
        end
      end
    end
  rescue => e
    puts e.to_s
    exit 1
  end
end

deps.flatten!
deps.uniq!

books.each do |book|
  deps.delete(book.to_s)
end

if deps.length > 0
  $stderr.puts "Unsatisfied dependencies: #{deps.join(', ')}."
  exit 1
else
  $stdout.puts 'All depencies satisfied.'
end