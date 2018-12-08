module BitTorrent
  class Tracker
    def initialize(torrent_file)
      metadata = BEncoding.decode(File.read(torrent_file)).as(Hash(String, BEncoding::Node))
      puts typeof(metadata)
      puts metadata
      infos = metadata["info"].as(Hash(String, BEncoding::Node))
      encode = BEncoding.encode(infos)
      puts encode
      puts Digest::SHA1.digest(encode)
      puts build_url(metadata["announce"].as(String), "-MB2020-", infos["length"])
    end

    def register
    end

    def peers
    end

    private def build_url(endpoint : String, peer_id, length)
      url = URI.parse(endpoint)
      query = {
        "info_hash"  => "f%60%21%95%EE%24%B6%15M%CB%EBLP%C7%B0%D11%5C%868",
        "peer_id"    => peer_id,
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
