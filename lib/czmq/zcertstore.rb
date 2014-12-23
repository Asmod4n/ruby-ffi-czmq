require_relative 'libczmq'
require_relative 'zcert'

module CZMQ
  class Zcertstore
    extend ::LibCZMQ

    czmq_constructor [:string]
    czmq_destructor

    czmq_function :lookup_zcert,  :lookup,  [:pointer, :string],  :pointer
    czmq_function :insert_zcert,  :insert,  [:pointer, :pointer], :void
    czmq_function :print,         :print,   [:pointer],           :void

    def lookup(public_key)
      Zcert.new_from_czmq_obj(lookup_zcert(public_key))
    end

    def insert(zcert)
      insert_zcert(Zcert.convert(zcert))
    end
  end
end
