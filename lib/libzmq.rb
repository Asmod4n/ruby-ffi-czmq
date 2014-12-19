require 'ffi'

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

  attach_function  :poll, :zmq_poll,  [:pointer, :int, :long], :int,  blocking: true

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
end
