module BitTorrent
  module BEncoding
    def self.decode(str : String)
      Decoder.from(str).decode
    end

    class Decoder
      @current : Char?

      def self.from(str : String)
        Decoder.new(IO::Memory.new(str))
      end

      def initialize(@io : IO)
        @current = nil
      end

      def decode
        @current = @io.read_char
        raise DecodeError.new("empty io") unless @current
        decode_next_node
      end

      def decode_next_node
        @current = @io.read_char unless @current
        case @current
        when DICT_START
          decode_dict
        when LIST_START
          decode_list
        when NB_START
          decode_nb
        else
          decode_str
        end
      end

      def decode_dict
        @current = @io.read_char unless @current
        hash = {} of String => Node

        @current = @io.read_char
        while @current != DICT_END && @current != nil
          key = decode_str
          @current = @io.read_char
          val = decode_next_node
          hash[key] = val

          @current = @io.read_char
        end

        hash
      end

      def decode_list
        @current = @io.read_char unless @current
        list = [] of Node
        @current = @io.read_char
        while @current != LIST_END && @current != nil
          obj = decode_next_node
          list.push(obj)

          @current = @io.read_char
        end

        list
      end

      def decode_nb
        @current = @io.read_char unless @current
        number = @io.gets(NB_END)
        raise DecodeError.new("invalid number") unless number
        num = (number.chomp(NB_END)).to_i64

        num
      end

      def decode_str
        @current = @io.read_char unless @current
        to_colon = @io.gets(ARRAY_DIVIDER)
        raise DecodeError.new("invalid byte array length") unless to_colon
        length = ((@current.not_nil! + to_colon).chomp(ARRAY_DIVIDER)).to_u64

        slice = Slice(UInt8).new(length)
        read = @io.read(slice)
        while read < length
          slice += read
          read += @io.read(slice)
        end

        String.new(slice)
      end
    end

    class DecodeError < Exception
    end
  end
end
