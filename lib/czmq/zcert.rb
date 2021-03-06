﻿require_relative 'utils'
require_relative 'libczmq'

module CZMQ
  class Zcert
    extend ::LibCZMQ

    czmq_constructor
    czmq_destructor

    czmq_function :new_from_zcert,  :new_from,    [:buffer_in, :buffer_in],               :pointer
    czmq_function :public_key,      :public_key,  [:pointer],                             :pointer
    czmq_function :secret_key,      :secret_key,  [:pointer],                             :pointer
    czmq_function :public_txt,      :public_txt,  [:pointer],                             :string
    czmq_function :secret_txt,      :secret_txt,  [:pointer],                             :string
    czmq_function :set_meta,        :set_meta,    [:pointer, :string, :string, :varargs], :void
    czmq_function :meta,            :meta,        [:pointer, :string],                    :string
    czmq_function :load_zcert,      :load,        [:string],                              :pointer
    czmq_function :save,            :save,        [:pointer, :string],                    :int
    czmq_function :save_public,     :save_public, [:pointer, :string],                    :int
    czmq_function :save_secret,     :save_secret, [:pointer, :string],                    :int
    czmq_function :apply,           :apply,       [:pointer, :pointer],                   :void
    czmq_function :dup_zcert,       :dup,         [:pointer],                             :pointer
    czmq_function :eq,              :eq,          [:pointer, :pointer],                   :bool

    def self.convert(cert)
      if Utils.check_for_pointer(cert)

        return cert
      elsif cert.respond_to?(:to_zcert) &&
            Utils.check_for_pointer(cert.to_zcert)

        return cert.to_zcert
      else
        fail ArgumentError, "#{cert.class} is not a CZMQ::Zcert", caller
      end
    end

    def self.new_from(public_key, secret_key)
      new_from_czmq_obj(new_from_zcert(public_key, secret_key))
    end

    def self.load(filename)
      unless (zcert = load_zcert(filename)).null?
        new_from_czmq_obj(zcert)
      else
        fail IOError, Utils.error, caller
      end
    end

    def dup
      self.class.new_from_czmq_obj(dup_zcert)
    end

    def ==(other)
      (object_id == other.object_id ||eq(self.class.convert(other)))
    end

    def !=(other)
      ! self.==(other)
    end
  end
end
