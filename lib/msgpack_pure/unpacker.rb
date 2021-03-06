# coding: utf-8

# MessagePack format specification
# http://msgpack.sourceforge.jp/spec

module MessagePackPure
  class Unpacker
  end
end

class MessagePackPure::Unpacker
  def initialize(io)
    @io = io
  end

  attr_reader :io

  def read
    type = self.unpack_uint8

    case
    when (type & 0b10000000) == 0b00000000 # positive fixnum
      return type
    when (type & 0b11100000) == 0b11100000 # negative fixnum
      return (type & 0b00011111) - (2 ** 5)
    when (type & 0b11100000) == 0b10100000 # fixraw
      size = (type & 0b00011111)
      return @io.read(size)
    when (type & 0b11110000) == 0b10010000 # fixarray
      size = (type & 0b00001111)
      return self.read_array(size)
    when (type & 0b11110000) == 0b10000000 # fixmap
      size = (type & 0b00001111)
      return self.read_hash(size)
    end

    case type
    when 0xC0 # nil
      return nil
    when 0xC2 # false
      return false
    when 0xC3 # true
      return true
    when 0xCA # float
      return self.unpack_float
    when 0xCB # double
      return self.unpack_double
    when 0xCC # uint8
      return self.unpack_uint8
    when 0xCD # uint16
      return self.unpack_uint16
    when 0xCE # uint32
      return self.unpack_uint32
    when 0xCF # uint64
      return self.unpack_uint64
    when 0xD0 # int8
      return self.unpack_int8
    when 0xD1 # int16
      return self.unpack_int16
    when 0xD2 # int32
      return self.unpack_int32
    when 0xD3 # int64
      return self.unpack_int64
    when 0xDA # raw16
      size = self.unpack_uint16
      return @io.read(size)
    when 0xDB # raw32
      size = self.unpack_uint32
      return @io.read(size)
    when 0xDC # array16
      size = self.unpack_uint16
      return self.read_array(size)
    when 0xDD # array32
      size = self.unpack_uint32
      return self.read_array(size)
    when 0xDE # map16
      size = self.unpack_uint16
      return self.read_hash(size)
    when 0xDF # map32
      size = self.unpack_uint32
      return self.read_hash(size)
    else
      raise("Unknown Type -- #{'0x%02X' % type}")
    end
  end

  def read_array(size)
    return size.times.map { self.read }
  end

  def read_hash(size)
    return size.times.inject({}) { |memo,|
      memo[self.read] = self.read
      memo
    }
  end

  def unpack_uint8
    return @io.read(1).unpack("C")[0]
  end

  def unpack_int8
    return @io.read(1).unpack("c")[0]
  end

  def unpack_uint16
    return @io.read(2).unpack("n")[0]
  end

  def unpack_int16
    num = self.unpack_uint16
    return (num < 2 ** 15 ? num : num - (2 ** 16))
  end

  def unpack_uint32
    return @io.read(4).unpack("N")[0]
  end

  def unpack_int32
    num = self.unpack_uint32
    return (num < 2 ** 31 ? num : num - (2 ** 32))
  end

  def unpack_uint64
    high = self.unpack_uint32
    low  = self.unpack_uint32
    return (high << 32) + low
  end

  def unpack_int64
    num = self.unpack_uint64
    return (num < 2 ** 63 ? num : num - (2 ** 64))
  end

  def unpack_float
    return @io.read(4).unpack("g")[0]
  end

  def unpack_double
    return @io.read(8).unpack("G")[0]
  end
end
