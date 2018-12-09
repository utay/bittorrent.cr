module BitTorrent
  class Socket
    alias BigEndian = IO::ByteFormat::BigEndian

    def initialize(@ip : String, @port : UInt16)
      @socket = TCPSocket.new(@ip, @port)
    end

    def handshake(info_hash : StaticArray(UInt8, 20), peer_id : String)
      if info_hash.size != 20
        raise "info_hash must be 20 bytes"
      end

      if peer_id.bytesize != 20
        raise "peer_id must be 20 bytes"
      end

      @socket.write(Slice[19.to_u8])
      @socket.write("BitTorrent protocol".to_slice)
      @socket.write(Slice(UInt8).new(8))
      @socket.write(info_hash.to_slice)
      @socket.write(peer_id.to_slice)

      client_info_hash = Bytes.new(20)
      @socket.read_byte
      @socket.read_string(19)
      @socket.skip(8)
      @socket.read(client_info_hash)
      peer_id = @socket.read_string(20)

      if client_info_hash != info_hash.to_slice
        raise "info hash didn't match"
      end
    end

    def send_message(message)
      @socket.write_bytes(message[0], BigEndian)
      @socket.write_byte(message[1])
    end

    def send_message(message, *payload)
      self.send_message(message)
      payload.each do |b|
        @socket.write_bytes(b, BigEndian)
      end
    end

    def receive_message
      length = @socket.read_bytes(Int32, BigEndian)
      message_id = @socket.read_byte

      if message_id == 7
        index = @socket.read_bytes(Int32, BigEndian)
        start = @socket.read_bytes(Int32, BigEndian)

        slice = Bytes.new(length - 9)
        @socket.read_fully(slice)

        {"message_id" => message_id, "block" => slice, "index" => index, "start" => start}
      else
        slice = Bytes.new(length - 1)
        @socket.read(slice)

        {"message_id" => message_id, "block" => slice}
      end
    end

    def close
      @socket.close
    end
  end
end
