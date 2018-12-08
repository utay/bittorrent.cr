module BitTorrent
  class Peer
    def initialize(torrent_file)
      tracker = BitTorrent::Tracker.new(torrent_file)
      puts tracker.peers
      puts tracker.info_hash
      puts tracker.peer_id
    end
  end
end
