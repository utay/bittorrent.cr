module BitTorrent
  class Torrent
    def initialize(torrent_file)
      @metadata = BEncoding.decode(
        File.read(torrent_file)
      ).as(Hash(String, BEncoding::Node))
    end

    def infos
      @metadata["info"].as(Hash(String, BEncoding::Node))
    end

    def announce
      @metadata["announce"].as(String)
    end

    def info_hash
      OpenSSL::SHA1.hash(BEncoding.encode(self.infos))
    end

    def name
      self.infos["name"].as(String)
    end

    def length
      self.infos["length"].as(Int64)
    end

    def pieces
      self.infos["pieces"].as(String)
    end
  end
end
