require_relative 'libczmq'

module CZMQ
  class Zsys
    extend ::LibCZMQ

    czmq_function :handler_set,   :handler_set,   [:pointer], :void
    czmq_function :handler_reset, :handler_reset, [],         :void
    czmq_function :set_logsender, :set_logsender, [:string],  :void
    czmq_function :set_logsystem, :set_logsystem, [:bool],    :void

    attach_variable :zsys_interrupted, :zsys_interrupted, :int
    attach_variable :zctx_interrupted, :zctx_interrupted, :int

    handler_set(nil)

    at_exit do
      zctx_interrupted = zsys_interrupted = 1
    end
  end
end
