module BitTorrent
  class Peer
    def initialize(torrent_file : String)
      @peer_id = "-AZ2060-xxxxxxxxxxxx"

      torrent = Torrent.new(torrent_file)
      tracker = Tracker.new(torrent, @peer_id)
      peers = tracker.peers
      @client = TCPSocket.new(peers[1][0], peers[1][1])
      handshake(torrent.info_hash, @peer_id)

      send_message(UNCHOKE)
      receive_message

      send_message(INTERESTED)
      receive_message

      send_message(REQUEST, 0, 0, torrent.length)
      piece = receive_message["block"].as(Bytes)

      if OpenSSL::SHA1.hash(String.new(piece)) == OpenSSL::SHA1.hash(torrent.pieces)
        puts "SHA1 verified"
      else
        raise "SHA1 mismatch"
      end

      puts "Done"

      File.write(torrent.name, piece)
    end

    def handshake(info_hash : StaticArray(UInt8, 20), peer_id : String)
      if info_hash.size != 20
        raise "info_hash must be 20 bytes"
      end

      if peer_id.bytesize != 20
        raise "peer_id must be 20 bytes"
      end

      @client.write(Slice[19.to_u8])
      @client.write("BitTorrent protocol".to_slice)
      @client.write(Slice(UInt8).new 8)
      @client.write(info_hash.to_slice)
      @client.write(peer_id.to_slice)

      client_info_hash = Bytes.new(20)
      @client.read_byte
      @client.read_string(19)
      @client.skip(8)
      @client.read(client_info_hash)
      peer_id = @client.read_string(20)

      if client_info_hash != info_hash.to_slice
        raise "info hash didn't match"
      end
    end

    def send_message(message)
      @client.write_bytes(message[0], IO::ByteFormat::BigEndian)
      @client.write(Slice[message[1].to_u8])
    end

    def send_message(message, *payload)
      self.send_message(message)
      payload.each { |i|
        @client.write_bytes(i, IO::ByteFormat::BigEndian)
      }
    end

    def receive_message
      length = @client.read_bytes(Int32, IO::ByteFormat::NetworkEndian)
      puts "got block of length #{length}"
      message_id = @client.read_byte

      if message_id == 7
        index = @client.read_bytes(Int32, IO::ByteFormat::NetworkEndian)
        start = @client.read_bytes(Int32, IO::ByteFormat::NetworkEndian)

        slice = Bytes.new(length - 9)
        @client.read_fully(slice)

        {"message_id" => message_id, "block" => slice, "index" => index, "start" => start}
      else
        slice = Bytes.new(length - 1)
        @client.read(slice)

        {"message_id" => message_id, "block" => slice}
      end
    end

    def close
      @client.close
    end
  end
end
