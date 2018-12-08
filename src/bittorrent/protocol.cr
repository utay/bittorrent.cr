module BitTorrent
  KEEP_ALIVE     = 0x0000
  CHOKE          = {0x0001, 0}
  UNCHOKE        = {0x0001, 1}
  INTERESTED     = {0x0001, 2}
  NOT_INTERESTED = {0x0001, 3}
  HAVE           = {0x0005, 4}
  REQUEST        = {0x0013, 6}
end
