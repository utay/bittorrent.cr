module BitTorrent
  class Peer
    def initialize(torrent_file : String)
      @peer_id = "-AZ2060-xxxxxxxxxxxx"
      @torrent = Torrent.new(torrent_file)
      @tracker = Tracker.new(@torrent, @peer_id)
    end

    def leech
      @tracker.peers.each do |peer|
        begin
          socket = Socket.new(peer[0], peer[1])
        rescue
          next
        end

        socket.handshake(@torrent.info_hash, @peer_id)

        socket.send_message(UNCHOKE)
        socket.receive_message

        socket.send_message(INTERESTED)
        socket.receive_message

        socket.send_message(REQUEST, 0, 0, @torrent.length.to_i32)
        piece = socket.receive_message["block"].as(Bytes)

        if String.new(OpenSSL::SHA1.hash(String.new(piece)).to_slice) != @torrent.pieces
          raise "SHA1 mismatch"
        end

        File.write(@torrent.name, piece)

        socket.close
      end
    end
  end
end
