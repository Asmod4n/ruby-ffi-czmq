require_relative 'libczmq'

module CZMQ
  class Zsys
    extend ::LibCZMQ

    czmq_function :error,         :error,         [:string],  :void
    czmq_function :warning,       :warning,       [:string],  :void
    czmq_function :notice,        :notice,        [:string],  :void
    czmq_function :info,          :info,          [:string],  :void
    czmq_function :debug,         :debug,         [:string],  :void

    attach_variable :zsys_interrupted, :zsys_interrupted, :int
    attach_variable :zctx_interrupted, :zctx_interrupted, :int

    ENV['ZSYS_SIGHANDLER'] = 'false'

    at_exit do
      zctx_interrupted = zsys_interrupted = 1
    end
  end
end
