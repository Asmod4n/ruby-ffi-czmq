﻿require_relative 'libczmq'
require_relative 'utils'
require_relative 'zstr'
require_relative 'zsock'

module CZMQ
  class Zframe
    include Comparable
    MORE     = 1
    REUSE    = 2
    DONTWAIT = 4

    extend ::LibCZMQ

    czmq_constructor [:buffer_in, :size_t]
    czmq_destructor

    czmq_function :new_empty_zframe,  :new_empty, [],                               :pointer
    czmq_function :recv_zframe,       :recv,      [:pointer],                       :pointer
    czmq_function :send_zframe,       :send,      [:pointer, :pointer, :int],       :int
    czmq_function :size,              :size,      [:pointer],                       :size_t
    czmq_function :data,              :data,      [:pointer],                       :pointer
    czmq_function :dup_zframe,        :dup,       [:pointer],                       :pointer
    czmq_function :strhex,            :strhex,    [:pointer],                       :pointer
    czmq_function :strdup,            :strdup,    [:pointer],                       :pointer
    czmq_function :more,              :more,      [:pointer],                       :bool
    czmq_function :set_more,          :set_more,  [:pointer, :bool],                :void
    czmq_function :eq,                :eq,        [:pointer, :pointer],             :bool
    czmq_function :reset,             :reset,     [:pointer, :buffer_in, :size_t],  :void
    czmq_function :print,             :print,     [:pointer, :string],              :void

    def self.new_empty
      unless (zframe = new_empty_zframe).null?
        new_from_czmq_obj(zframe)
      else
        fail RuntimeError, Utils.error, caller
      end
    end

    def self.convert(frame)
      if Utils.check_for_pointer(frame)

        return frame
      elsif frame.respond_to?(:to_zframe) &&
            Utils.check_for_pointer(frame.to_zframe)

        return frame.to_zframe
      else
        fail ArgumentError, "#{frame.class} is not a CZMQ::Zframe", caller
      end
    end

    def dup
      self.class.new_from_czmq_obj(dup_zframe)
    end

    def str_hex
      Zstr.read_string(strhex)
    end

    def str_dup
      Zstr.read_string(strdup)
    end

    def more?
      more
    end

    def <=>(other)
      size <=> other.size
    end

    def ==(other)
      (object_id == other.object_id ||eq(self.class.convert(other)))
    end

    def !=(other)
      ! self.==(other)
    end

    def to_str
      data.read_bytes(size)
    end

    def self.recv(socket)
      zsock = Zsock.convert(socket)

      unless (zframe = recv_zframe(zsock)).null?
        new_from_czmq_obj(zframe)
      else
        fail IOError, Utils.error, caller
      end
    end
  end
end
