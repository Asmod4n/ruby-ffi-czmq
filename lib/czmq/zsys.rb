require_relative 'libczmq'

module CZMQ
  class Zsys
    extend ::LibCZMQ

    czmq_function :init,            :init,            [],         :pointer
    czmq_function :shutdown,        :shutdown,        [],         :void
    czmq_function :handler_set,     :handler_set,     [:pointer], :void
    czmq_function :handler_reset,   :handler_reset,   [],         :void
    czmq_function :set_io_threads,  :set_io_threads,  [:size_t],  :void
    czmq_function :set_max_sockets, :set_max_sockets, [:size_t],  :void
    czmq_function :socket_limit,    :socket_limit,    [],         :size_t
    czmq_function :set_linger,      :set_linger,      [:size_t],  :void
    czmq_function :set_sndhwm,      :set_sndhwm,      [:size_t],  :void
    czmq_function :set_rcvhwm,      :set_rcvhwm,      [:size_t],  :void
    czmq_function :set_pipehwm,     :set_pipehwm,     [:size_t],  :void
    czmq_function :pipehwm,         :pipehwm,         [],         :size_t
    czmq_function :set_ipv6,        :set_ipv6,        [:int],     :void
    czmq_function :set_interface,   :set_interface,   [:string],  :void
    czmq_function :set_logident,    :set_logident,    [:string],  :void
    czmq_function :set_logstream,   :set_logstream,   [:pointer], :void
    czmq_function :set_logsender,   :set_logsender,   [:string],  :void
    czmq_function :set_logsystem,   :set_logsystem,   [:bool],    :void
    czmq_function :error,           :error,           [:string],  :void
    czmq_function :warning,         :warning,         [:string],  :void
    czmq_function :notice,          :notice,          [:string],  :void
    czmq_function :info,            :info,            [:string],  :void
    czmq_function :debug,           :debug,           [:string],  :void

    attach_variable :interrupted, :zsys_interrupted, :int
    attach_variable :zctx_interrupted, :zctx_interrupted, :int

    handler_set(nil)
    set_ipv6(1)

    at_exit do
      zctx_interrupted = interrupted = 1
      shutdown
    end
  end
end
