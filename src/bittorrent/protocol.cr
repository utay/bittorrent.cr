module BitTorrent
  KEEP_ALIVE         = 0x0000
  CHOKE              = {1, 0_u8}
  UNCHOKE            = {1, 1_u8}
  INTERESTED         = {1, 2_u8}
  NOT_INTERESTED     = {1, 3_u8}
  HAVE               = {5, 4_u8}
  REQUEST            = {13, 6_u8}
  REQUEST_BLOCK_SIZE = 16000
end
