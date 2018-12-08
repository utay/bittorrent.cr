module BitTorrent
  class Tracker
    def initialize(@torrent : Torrent, @peer_id : String)
    end

    def peers
      peers = self.register.as(Hash(String, BEncoding::Node))["peers"].as(String)

      res = [] of {String, UInt16}

      peers.bytes.in_groups_of(6, filled_up_with = 0.to_u8).map do |peer|
        case peer
        when Array
          ip = Slice.new(peer[0, 4].to_unsafe, 4)
          port = Slice.new(peer[4, 2].to_unsafe, 2)

          res << {
            ip.map(&.to_i).join('.'),
            IO::ByteFormat::NetworkEndian.decode(UInt16, port),
          }
        else
          raise "Peer wasn't an array"
        end
      end

      res
    end

    def register
      resp = HTTP::Client.get(self.url)
      BEncoding.decode(resp.body)
    end

    private def url
      url = URI.parse(@torrent.announce)

      query = {
        "info_hash"  => URI.escape(String.new(@torrent.info_hash.to_slice)),
        "peer_id"    => @peer_id,
        "port"       => "6881",
        "compact"    => "1",
        "downloaded" => "0",
        "event"      => "started",
        "uploaded"   => "0",
        "left"       => @torrent.length.to_s,
      }

      url.query = query.map { |key, value|
        key + "=" + value
      }.join('&')

      url.to_s
    end
  end
end
