require_relative 'libczmq'
require_relative 'utils'
require_relative 'zsock'

module CZMQ
  class Zstr
    extend ::LibCZMQ

    czmq_function :recv_zstr,  :recv,  [:pointer],                        :pointer
    czmq_function :send_zstr,  :send,  [:pointer, :string],               :int
    czmq_function :sendm,      :sendm, [:pointer, :string],               :int
    czmq_function :sendx_zstr, :sendx, [:pointer, :string, :varargs],     :int
    czmq_function :recvx_zsrt, :recvx, [:pointer, :buffer_out, :varargs], :int
    czmq_function :free,       :free,  [:pointer],                        :void

    class << self
      def read_string(str_ptr)
        str = str_ptr.get_string(0)
        free_ptr = FFI::MemoryPointer.new(:pointer)
        free_ptr.write_pointer(str_ptr)
        free(free_ptr)
        str
      end

      def recv(socket)
        read_string(recv_zstr(Zsock.convert(socket)))
      end

      def sendx(socket, string, *strings)
        if strings.size.zero?
          fail ArgumentError, "Wrong number of Arguments, (2 for 3..n)", caller
        end

        strings_varargs = ([ :string ] * strings.size).zip(strings).flatten
        sendx_zstr(Zsock.convert(socket), string, *strings_varargs, :pointer, nil)
      end

      def recvx(socket, counter = 1)
        if counter < 1
          fail ArgumentError, "Counter must be >= 1, got #{counter}", caller
        end

        buffers = []
        buffers << FFI::Buffer.new_out(:pointer)
        counter.times do
          buffers << :buffer_out
          buffers << FFI::Buffer.new_out(:pointer)
        end

        recvx_zsrt(Zsock.convert(socket), *buffers, :pointer, nil)

        strings = []
        buffers.select {|buffer| buffer != :buffer_out}.each do |buffer|
          strings << buffer.read_pointer.get_string(0)
          free(buffer)
        end
        strings
      end
    end
  end
end
