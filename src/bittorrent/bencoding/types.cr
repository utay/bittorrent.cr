module BitTorrent
  module BEncoding
    alias Node = Hash(String, Node) | Int64 | String | Array(Node)

    DICT_START    = 'd'
    DICT_END      = 'e'
    LIST_START    = 'l'
    LIST_END      = 'e'
    NB_START      = 'i'
    NB_END        = 'e'
    ARRAY_DIVIDER = ':'
  end
end
