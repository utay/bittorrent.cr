require "http"
require "openssl"
require "socket"
require "uri"

module BitTorrent
  VERSION = "0.1.0"
end

require "./bittorrent/bencoding/*"
require "./bittorrent/*"

def handle_client(client)
  message = client.gets
  client.puts message
end

spawn do
  server = TCPServer.new("localhost", 6881)
  while client = server.accept?
    spawn handle_client(client)
  end
end

tracker = BitTorrent::Tracker.new("test.torrent")
tracker.register
