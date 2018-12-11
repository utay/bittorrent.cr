require "option_parser"
require "../bittorrent"

# def handle_client(client)
#   message = client.gets
#   client.puts message
# end
#
# spawn do
#   server = TCPServer.new("localhost", 6881)
#   while client = server.accept?
#     spawn handle_client(client)
#   end
# end

options = {} of Symbol => Bool

OptionParser.parse! do |parser|
  parser.banner = "Usage: bittorrent [arguments]"

  parser.on("-d", "--dump-peers", "Dumps the peers of this torrent") do
    options[:dump] = true
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit(0)
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

if options[:dumps]?
else
  peer = BitTorrent::Peer.new("/home/utay/torrent/test.torrent")
  peer.leech
end
