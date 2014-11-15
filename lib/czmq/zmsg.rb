require_relative 'libczmq'
require_relative 'zframe'
require_relative 'zsock'
require_relative 'utils'

module CZMQ
  class Zmsg
    INTF = '%zd'.freeze
    include Enumerable
    extend ::LibCZMQ

    czmq_constructor
    czmq_destructor

    czmq_function :recv_zmsg,         :recv,          [:pointer],                       :pointer
    czmq_function :send_zmsg,         :send,          [:pointer, :pointer],             :int
    czmq_function :size,              :size,          [:pointer],                       :size_t
    czmq_function :content_size,      :content_size,  [:pointer],                       :size_t
    czmq_function :prepend_zframe,    :prepend,       [:pointer, :pointer],             :int
    czmq_function :append_zframe,     :append,        [:pointer, :pointer],             :int
    czmq_function :pop_zframe,        :pop,           [:pointer],                       :pointer
    czmq_function :push_mem,          :pushmem,       [:pointer, :buffer_in, :size_t],  :int
    czmq_function :add_mem,           :addmem,        [:pointer, :buffer_in, :size_t],  :int
    czmq_function :push_zstr,         :pushstr,       [:pointer, :string],              :int
    czmq_function :add_zstr,          :addstr,        [:pointer, :string],              :int
    czmq_function :push_zstrf,        :pushstrf,      [:pointer, :string, :varargs],    :int
    czmq_function :add_zstrf,         :addstrf,       [:pointer, :string, :varargs],    :int
    czmq_function :remove_zframe,     :remove,        [:pointer, :pointer],             :void
    czmq_function :first_zframe,      :first,         [:pointer],                       :pointer
    czmq_function :next_zframe,       :next,          [:pointer],                       :pointer
    czmq_function :last_zframe,       :last,          [:pointer],                       :pointer
    czmq_function :encode_zmsg,       :encode,        [:pointer, :buffer_out],          :size_t
    czmq_function :decode_zmsg,       :decode,        [:pointer, :size_t],              :pointer
    czmq_function :dup_zmsg,          :dup,           [:pointer],                       :pointer
    czmq_function :print,             :print,         [:pointer],                       :void

    def each
      yield first
      size.pred.times do
        yield self.next
      end
    end

    def to_a
      ary = []
      each {|frame| ary << frame.to_str }
      ary
    end

    def add(data)
      case data
      when FFI::Pointer
        add_mem(data, data.size)
      when Zframe
        append_zframe(data)
      when String
        add_mem(data, data.bytesize)
      when Fixnum
        add_zstrf(INTF, :ssize_t, data)
      when NilClass
        add_mem(data, 0)
      else
        if data.respond_to?(:to_ptr) &&
           data.respond_to?(:size)

          add_mem(data.to_ptr, data.size)
        elsif data.respond_to?(:to_zframe)
          append_zframe(data.to_zframe)
        elsif data.respond_to?(:data) &&
              data.respond_to?(:size)

          add_mem(data.data, data.size)
        elsif data.respond_to?(:to_str)
          add_mem(data.to_str, data.to_str.bytesize)
        elsif data.nil?
          add_mem(nil, 0)
        else
          fail ArgumentError, 'Unknown data type', caller
        end
      end
      self
    end

    alias_method :<<, :add

    def push(data)
      case data
      when FFI::Pointer
        push_mem(data, data.size)
      when Zframe
        prepend_zframe(data)
      when String
        push_mem(data, data.bytesize)
      when Fixnum
        push_zstrf(INTF, :ssize_t, data)
      when NilClass
        push_mem(data, 0)
      else
        if data.respond_to?(:to_ptr) &&
           data.respond_to?(:size)

          push_mem(data.to_ptr, data.size)
        elsif data.respond_to?(:to_zframe)
          prepend_zframe(data.to_zframe)
        elsif data.respond_to?(:data) &&
              data.respond_to?(:size)

          push_mem(data.data, data.size)
        elsif data.respond_to?(:to_str)
          push_mem(data.to_str, data.to_str.bytesize)
        elsif data.nil?
          push_mem(nil, 0)
        else
          fail ArgumentError, 'Unknown data type', caller
        end
      end
      self
    end

    [:first, :next, :last].each do |meth|
      class_eval <<-RUBY, __FILE__, __LINE__
      def #{meth.to_s}
         CZMQ::Zframe.new_from_czmq_obj(#{meth.to_s}_zframe, nil)
      end
      RUBY
    end

    [:first=, :next=, :last=].each do |meth|
      class_eval <<-RUBY, __FILE__, __LINE__
      def #{meth.to_s}(content)
         CZMQ::Zframe.reset(#{meth.to_s[0...-1]}_zframe, content, content.bytesize)
      end
      RUBY
    end

    def pop
      Zframe.new_from_czmq_obj(pop_zframe)
    end

    def dup
      self.class.new_from_czmq_obj(dup_zmsg)
    end

    def remove(zframe)
      remove_zframe(Zframe.convert(zframe))
    end

    def self.recv(socket)
      zsock = Zsock.convert(socket)

      unless (zmsg = recv_zmsg(zsock)).null?
        new_from_czmq_obj(zmsg)
      else
        fail IOError, Utils.error, caller
      end
    end

    def encode
      buffer = FFI::MemoryPointer.new(:pointer)
      size = encode_zmsg(buffer)
      bPtr = buffer.read_pointer()
      bPtr.null? ? fail(RuntimeError, Utils.error, caller) : bPtr.read_bytes(size)
    end

    def self.decode(bytes)
      new_from_czmq_obj(decode_zmsg(bytes, bytes.bytesize))
    end
  end
end
