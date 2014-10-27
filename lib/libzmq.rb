require 'ffi'

module Libzmq
  extend FFI::Library
  ffi_lib :libzmq, FFI::Library::LIBC

  POLLIN  = 1
  POLLOUT = 2
  POLLERR = 4
  POLLPRI = 8

  class PollItem < FFI::Struct
    FD_TYPE = (FFI::Platform.windows? && FFI::Platform::ADDRESS_SIZE == 64) ? :uint64 : :int

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
  end

  attach_function  :memmove,             [:pointer, :pointer, :size_t],  :pointer
  attach_function  :poll,    :zmq_poll,  [:pointer, :int, :long],        :int,  blocking: true

  class PollItems < Array
    def to_ptr
      items_pointer = FFI::MemoryPointer.new(PollItem, size, true)
      offset = 0
      each do |item|
        Libzmq.memmove(items_pointer + offset, item, item.size)
        offset += item.size
      end
      items_pointer
    end
  end
end
