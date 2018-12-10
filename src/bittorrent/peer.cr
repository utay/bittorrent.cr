module BitTorrent
  REQUEST_BLOCK_SIZE = 16000

  enum DownloadState
    None
    Started
    Finished
  end

  class Peer
    def initialize(torrent_file : String)
      @peer_id = "-AZ2060-xxxxxxxxxxxx"
      @torrent = Torrent.new(torrent_file)
      @tracker = Tracker.new(@torrent, @peer_id)
      @length = @torrent.length.as(Int64)
      @end = Channel(Nil).new

      length = @torrent.length
      piece_length = @torrent.piece_length

      if length <= piece_length
        nb_pieces = 1
      else
        nb_pieces = (length / piece_length) + 1
      end

      @cache = Array(IO::Memory).new(nb_pieces, IO::Memory.new)
    end

    def leech
      length = @torrent.length
      piece_length = @torrent.piece_length

      if length <= piece_length
        nb_pieces = 1
      else
        nb_pieces = (length / piece_length) + 1
      end

      downloaded_pieces = Array(DownloadState).new(nb_pieces, DownloadState::None)

      @tracker.peers.each do |peer|
        begin
          socket = Socket.new(peer[0], peer[1])
        rescue
          next
        end

        spawn download_pieces(socket, downloaded_pieces)
      end

      @end.receive
    end

    private def download_pieces(socket, pieces)
      socket.handshake(@torrent.info_hash, @peer_id)

      socket.send_message(UNCHOKE)
      socket.receive_message

      socket.send_message(INTERESTED)
      socket.receive_message

      while piece_index = find_piece(pieces)
        if piece_index.nil?
          socket.close
          return
        end

        download_piece(socket, pieces, piece_index)
      end
    end

    private def download_piece(socket, pieces, piece_index)
      space_left = @torrent.length - piece_index * @torrent.piece_length
      length = Math.min(@torrent.piece_length, space_left)
      idx = 0
      piece = IO::Memory.new(@torrent.piece_length)
      while length > 0
        block_size = Math.min(REQUEST_BLOCK_SIZE, length)
        puts "piece_index #{piece_index} idx #{idx} block_size #{block_size}"
        socket.send_message(REQUEST, piece_index, idx, block_size)
        data = socket.receive_message["block"].as(Bytes)
        piece.write(data)
        idx += block_size
        length -= block_size
      end

      @cache[piece_index] = piece
      @length -= @torrent.piece_length

      if String.new(OpenSSL::SHA1.hash(piece.to_s).to_slice) != @torrent.hash(piece_index)
        raise "SHA1 mismatch"
      end

      pieces[piece_index] = DownloadState::Finished

      if @length <= 0
        write_pieces
        @end.send(nil)
      end
    end

    private def find_piece(pieces)
      piece_index = nil

      pieces.each_with_index do |piece, i|
        if piece == DownloadState::None
          piece_index = i
          pieces[piece_index] = DownloadState::Started
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
