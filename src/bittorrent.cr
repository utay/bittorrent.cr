require "digest"
require "uri"

module BitTorrent
  VERSION = "0.1.0"
end

require "./bittorrent/bencoding/*"
require "./bittorrent/*"

BitTorrent::Tracker.new("test.torrent")
