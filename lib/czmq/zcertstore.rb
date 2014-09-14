require_relative 'utils'
require_relative 'libczmq'

if CZMQ::Utils.has_curve
  module CZMQ
    class Zcertstore
      extend ::LibCZMQ

      czmq_constructor [:string]
      czmq_destructor

      czmq_function :lookup,        :lookup,  [:pointer, :string],  :pointer
      czmq_function :insert_zcert,  :insert,  [:pointer, :pointer], :void
    end
  end
end
