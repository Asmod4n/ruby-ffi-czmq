require_relative 'libczmq'
require_relative 'utils'
require_relative 'zsock'

module CZMQ
  class Zframe
    include Comparable
    MORE     = 1
    REUSE    = 2
    DONTWAIT = 4

    extend ::LibCZMQ

    czmq_constructor [:pointer, :size_t]
    czmq_destructor

    czmq_function :new_empty,           :new_empty,   [],                         :pointer
    czmq_function :recv_zframe,         :recv,        [:pointer],                 :pointer
    czmq_function :send_zframe,         :send,        [:pointer, :pointer, :int], :int
    czmq_function :size,                :size,        [:pointer],                 :size_t
    czmq_function :data,                :data,        [:pointer],                 :pointer
    czmq_function :dup_zframe,          :dup,         [:pointer],                 :pointer
    czmq_function :str_hex,             :strhex,      [:pointer],                 :string
    czmq_function :str_eq,              :streq,       [:pointer, :string],        :bool
    czmq_function :str_dup,             :strdup,      [:pointer],                 :string
    czmq_function :more,                :more,        [:pointer],                 :int
    czmq_function :set_more,            :set_more,    [:pointer, :int],           :void

    def self.convert(frame)
      if Utils.check_for_pointer(frame)

        return frame
      elsif frame.respond_to?(:to_zframe) &&
            Utils.check_for_pointer(frame.to_zframe)

        return frame.to_zframe
      else
        fail ArgumentError, "#{frame.class} is not a CZMQ::Zframe"
      end
    end

    def dup
      self.class.new_from_czmq_obj(dup_zframe)
    end

    def <=>(other)
      size <=> other.size
    end

    def ==(other)
      to_str == other.to_str
    end

    def !=(other)
      ! self.==(other)
    end

    def to_str
      Utils.hex2bin(str_hex)
    end

    def self.recv(socket)
      zsock = Zsock.convert(socket)

      unless (zframe = recv_zframe(zsock)).null?
        new_from_czmq_obj(zframe)
      else
        fail IOError, Utils.error
      end
    end
  end
end
