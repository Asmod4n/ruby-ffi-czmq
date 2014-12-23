require 'ffi'
require_relative 'czmq/utils'

module Libzmq
  extend FFI::Library
  ffi_lib :libzmq

  POLLIN  = 1
  POLLOUT = 2
  POLLERR = 4
  POLLPRI = 8

  class PollItem < FFI::Struct
    FD_TYPE = if FFI::Platform.windows? # ftp://ftp.microsoft.com/bussys/winsock/winsock2/winsock2.h:84
                (FFI::Platform::ADDRESS_SIZE == 64) ? :uint64_t : :uint
              else
                :int
              end

    layout  :socket,  :pointer,
            :fd,      FD_TYPE,
            :events,  :short,
            :revents, :short

    def readable?
      (self[:revents] & POLLIN) > 0
    end

    def writable?
      (self[:revents] & POLLOUT) > 0
    end

    def error?
      (self[:revents] & POLLERR) > 0
    end

    def priority?
      (self[:revents] & POLLPRI) > 0
    end
  end

  attach_function :poll, :zmq_poll, [:pointer, :int, :long],            :int,     blocking: true
  attach_function :zmq_z85_decode,  [:buffer_out, :string],             :pointer, blocking: true
  attach_function :zmq_z85_encode,  [:buffer_out, :buffer_in, :size_t], :string,  blocking: true

  class PollItems < Array
    def to_ptr
      items_pointer = FFI::MemoryPointer.new(PollItem, size, true)
      offset = 0
      each do |item|
        (items_pointer + offset).__copy_from__(item.to_ptr, item.size)
        offset += item.size
      end
      items_pointer
    end
  end

  module_function

  def z85_decode(str)
    if (str.bytesize % 5 == 0)
      buffer = CZMQ::Utils.zeros(str.bytesize * 0.8)
      zmq_z85_decode(buffer, str)
      buffer
    else
      raise ArgumentError, "str=#{str} bytesize=#{str.bytesize} is not divisible by 5", caller
    end
  end

  def z85_encode(data)
    size = data.respond_to?(:bytesize) ? data.bytesize : data.size
    if (size % 4 == 0)
      zmq_z85_encode(CZMQ::Utils.zeros(size * 1.25 + 1), data, size)
    else
      raise ArgumentError, "data=#{data} size=#{size} is not divisible by 4", caller
    end
  end
end
