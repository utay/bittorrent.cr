module BitTorrent
  class Tracker
    def initialize(torrent_file)
      @metadata = BEncoding.decode(
        File.read(torrent_file)
      ).as(Hash(String, BEncoding::Node))
    end

    def register
      infos = @metadata["info"].as(Hash(String, BEncoding::Node))
      info_hash = OpenSSL::SHA1.hash(BEncoding.encode(infos)).to_slice

      resp = HTTP::Client.get(
        build_url(
          @metadata["announce"].as(String),
          String.new(info_hash),
          infos["length"]
        )
      )

      body = BEncoding.decode(resp.body)

      peers = body.as(Hash(String, BEncoding::Node))["peers"].as(String)

      peers.bytes.in_groups_of(6, filled_up_with = 0.to_u8).map do |peer|
        case peer
        when Array
          ip = Slice.new(peer[0, 4].to_unsafe, 4)
          port = Slice.new(peer[4, 2].to_unsafe, 2)
          puts ip.map(&.to_i).join('.')
          puts port

          i = IO::ByteFormat::NetworkEndian.decode(UInt32, ip)
          p = IO::ByteFormat::NetworkEndian.decode(UInt16, port)

          {i, p}
        else
          raise "Peer wasn't an array"
        end
      end
    end

    def peers
    end

    private def build_url(endpoint, info_hash, length)
      url = URI.parse(endpoint)

      query = {
        "info_hash"  => URI.escape(info_hash),
        "peer_id"    => "-AZ2060-xxxxxxxxxxxx",
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
