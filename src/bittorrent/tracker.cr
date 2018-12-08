module BitTorrent
  class Tracker
    getter peer_id : String

    def initialize(torrent_file)
      @metadata = BEncoding.decode(
        File.read(torrent_file)
      ).as(Hash(String, BEncoding::Node))

      @peer_id = "-AZ2060-xxxxxxxxxxxx"
    end

    def peers
      peers = self.register.as(Hash(String, BEncoding::Node))["peers"].as(String)

      res = [] of {String, UInt16}

      peers.bytes.in_groups_of(6, filled_up_with = 0.to_u8).map do |peer|
        case peer
        when Array
          ip = Slice.new(peer[0, 4].to_unsafe, 4)
          port = Slice.new(peer[4, 2].to_unsafe, 2)

          p = IO::ByteFormat::NetworkEndian.decode(UInt16, port)

          res << {ip.map(&.to_i).join('.'), p}
        else
          raise "Peer wasn't an array"
        end
      end

      res
    end

    def info_hash
      infos = @metadata["info"].as(Hash(String, BEncoding::Node))
      OpenSSL::SHA1.hash(BEncoding.encode(infos))
    end

    def register
      infos = @metadata["info"].as(Hash(String, BEncoding::Node))

      resp = HTTP::Client.get(
        build_url(
          @metadata["announce"].as(String),
          String.new(self.info_hash.to_slice),
          infos["length"]
        )
      )

      BEncoding.decode(resp.body)
    end

    private def build_url(endpoint, info_hash, length)
      url = URI.parse(endpoint)

      query = {
        "info_hash"  => URI.escape(info_hash),
        "peer_id"    => @peer_id,
        "port"       => "6881",
        "compact"    => "1",
        "downloaded" => "0",
        "event"      => "started",
        "uploaded"   => "0",
        "left"       => length.to_s,
      }

      url.query = query.map { |key, value|
        key + "=" + value
      }.join('&')

      url.to_s
    end
  end
end
