require "../bittorrent"

# def handle_client(client)
#   message = client.gets
#   client.puts message
# end
#
# spawn do
#   server = TCPServer.new("localhost", 6881)
#   while client = server.accept?
#     spawn handle_client(client)
#   end
# end

peer = BitTorrent::Peer.new("/home/utay/torrent/test.torrent")
peer.leech
