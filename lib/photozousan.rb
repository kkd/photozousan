require "photozousan/version"
require "photozousan/client"
require 'io/console'
require 'optparse'

module Photozousan
  def self.run(id, pass, album_id, limit)
    if album_id.nil?
      print 'donwload photozou-album id?:'
      album_id = gets.to_i
    end

    if limit.nil?
      print 'donwload image limit?(1-1000):'
      limit = gets.to_i
    end

    if id.nil?
      print 'your photozou id?:'
      id = gets.chomp
    end

    if pass.nil?
      print 'your photozou password?:'
      pass = STDIN.noecho(&:gets).chomp
    end

    Client.new(id, pass).dowmload_all_images(album_id, limit)
  end

  def self.parse_arguments
    options = {}

    OptionParser.new do |opts|
      opts.banner = "Usage: photozousan [options] or ruby lib/photozousan.rb [options]"

      opts.on("-i", "--id ID", "PhotoZou user ID or email") do |id|
        options[:id] = id
      end

      opts.on("-p", "--password PASSWORD", "PhotoZou password") do |password|
        options[:password] = password
      end

      opts.on("-a", "--album ALBUM_ID", Integer, "Album ID to download") do |album_id|
        options[:album_id] = album_id
      end

      opts.on("-l", "--limit LIMIT", Integer, "Number of images to download (1-1000)") do |limit|
        options[:limit] = limit
      end

      opts.on("-h", "--help", "Show this help message") do
        puts opts
        exit
      end

      opts.on("-v", "--version", "Show version") do
        puts "PhotoZousan version #{Photozousan::VERSION}"
        exit
      end
    end.parse!

    options
  end
end

if __FILE__ == $0
  begin
    options = Photozousan.parse_arguments

    id = options[:id]
    pass = options[:password]
    album_id = options[:album_id]
    limit = options[:limit]

    Photozousan.run(id, pass, album_id, limit)
  rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
    puts "Error: #{e.message}"
    puts "Use -h or --help for usage information"
    exit 1
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end
