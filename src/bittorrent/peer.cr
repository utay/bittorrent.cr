module BitTorrent
  class Peer
    def initialize(torrent_file : String)
      @peer_id = "-AZ2060-xxxxxxxxxxxx"
      @torrent = Torrent.new(torrent_file)
      @tracker = Tracker.new(@torrent, @peer_id)
    end

    def leech
      Download.new(@peer_id, @torrent, @tracker.peers).start
    end
  end
end
