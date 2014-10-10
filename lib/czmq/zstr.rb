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
        if Utils.check_for_pointer(str_ptr)
          str = str_ptr.read_string
          FFI::MemoryPointer.new(:pointer) do |free_ptr|
            free_ptr.write_pointer(str_ptr)
            free(free_ptr)
          end
          str
        else
          fail ArgumentError, "#{str_ptr.class} is not a FFI::Pointer", caller
        end
      end

      def recv(socket)
        read_string(recv_zstr(Zsock.convert(socket)))
      end

      def sendx(socket, string, *strings)
        if strings.size == 0
          fail ArgumentError, "Wrong number of Arguments, (2 for 3..n)", caller
        end
        strings_varargs = ([ :string ] * strings.size).zip(strings).flatten
        sendx_zstr(Zsock.convert(socket), string, *strings_varargs, :pointer, nil)
      end

      def recvx(socket, counter = 1)
        if counter < 1
          fail ArgumentError, "Counter must be >= 1, got #{counter}", caller
        end
        first_buffer = FFI::Buffer.new_out(:pointer, 1)
        buffers = []
        counter.times do
          buffers << FFI::Buffer.new_out(:pointer, 1)
        end
        buffers_varargs = ([ :buffer_out ] * buffers.size).zip(buffers).flatten

        recvx_zsrt(Zsock.convert(socket), first_buffer, *buffers_varargs, :pointer, nil)

        strings = []
        strings << first_buffer.read_pointer.read_string
        free(first_buffer)
        buffers.each do |buffer|
          strings << buffer.read_pointer.read_string
          free(buffer)
        end
        strings
      end
    end
  end
end
