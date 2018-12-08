module BitTorrent
  module BEncoding
    def self.encode(node)
      io = IO::Memory.new
      Encoder.new(io).encode(node)
      io.to_s
    end

    class Encoder
      def initialize(@io : IO)
      end

      def encode(node : Int)
        @io << NB_START
        @io << node.to_s
        @io << NB_END
      end

      def encode(node : String)
        @io << node.size
        @io << ARRAY_DIVIDER
        @io << node
      end

      def encode(node : Hash(String, Node))
        @io << DICT_START
        node.keys.sort.each do |key|
          encode(key)
          encode(node[key])
        end
        @io << DICT_END
      end

      def encode(node : Enumerable)
        @io << LIST_START
        node.each { |p| encode(p) }
        @io << LIST_END
      end
    end
  end
end
