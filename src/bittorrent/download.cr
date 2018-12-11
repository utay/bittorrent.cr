module BitTorrent
  class Download
    enum DownloadState
      None
      Started
      Finished
    end

    def initialize(@peer_id : String, @torrent : Torrent, @peers : PeerList)
      @length = @torrent.length.as(Int64)
      @end = Channel(Nil).new
      @bar = ProgressBar.new
      @nb_pieces = ((@length / @torrent.piece_length) + 1).to_i32

      if @length <= @torrent.piece_length
        @nb_pieces = 1
      end

      @bar.width = @nb_pieces
      @downloaded_pieces = Array(DownloadState).new(@nb_pieces, DownloadState::None)
      @cache = Array(IO::Memory).new(@nb_pieces, IO::Memory.new)
    end

    def start
      @peers.each do |peer|
        begin
          socket = Socket.new(peer[0], peer[1])
        rescue
          next
        end

        spawn download_pieces(socket)
      end

      @end.receive
    end

    private def download_pieces(socket)
      socket.handshake(@torrent.info_hash, @peer_id)

      socket.send_message(UNCHOKE)
      socket.receive_message

      socket.send_message(INTERESTED)
      socket.receive_message

      while piece_index = find_piece
        if piece_index.nil?
          socket.close
          return
        end

        download_piece(socket, piece_index)
      end
    end

    private def download_piece(socket, piece_index)
      space_left = @torrent.length - piece_index * @torrent.piece_length
      length = Math.min(@torrent.piece_length, space_left)
      idx = 0
      piece = IO::Memory.new(@torrent.piece_length)
      while length > 0
        block_size = Math.min(REQUEST_BLOCK_SIZE, length)
        socket.send_message(REQUEST, piece_index, idx, block_size)
        data = socket.receive_message["block"].as(Bytes)
        piece.write(data)
        idx += block_size
        length -= block_size
      end

      @bar.inc
      @cache[piece_index] = piece
      @length -= @torrent.piece_length

      if String.new(OpenSSL::SHA1.hash(piece.to_s).to_slice) != @torrent.hash(piece_index)
        raise "SHA1 mismatch"
      end

      @downloaded_pieces[piece_index] = DownloadState::Finished

      if @length <= 0
        write_pieces
        @end.send(nil)
      end
    end

    private def find_piece
      piece_index = nil

      @downloaded_pieces.each_with_index do |piece, i|
        if piece == DownloadState::None
          piece_index = i
          @downloaded_pieces[piece_index] = DownloadState::Started
          break
        end
      end

      piece_index
    end

    private def write_pieces
      file = File.new(@torrent.name, mode = "a")
      @cache.each do |data|
        file.write(data.to_slice)
      end
    end
  end
end
