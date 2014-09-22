require_relative 'libczmq'
require_relative 'utils'
require_relative 'sock_type'
require_relative 'zmsg'

module CZMQ
  class Zsock
    SET_SOCKOPT = /^set_(.+)$/.freeze

    extend ::LibCZMQ

    czmq_constructor
    czmq_destructor

    czmq_function :bind,        :bind,      [:pointer, :string],        :int
    czmq_function :endpoint,    :endpoint,  [:pointer],                 :string
    czmq_function :unbind,      :unbind,    [:pointer, :string],        :int
    czmq_function :connect,     :connect,   [:pointer, :string],        :int
    czmq_function :disconnect,  :disconnect,[:pointer, :string],        :int
    czmq_function :attach,      :attach,    [:pointer, :string, :bool], :int
    czmq_function :type_str,    :type_str,  [:pointer],                 :string
    czmq_function :signal,      :signal,    [:pointer, :uchar],         :int
    czmq_function :wait,        :wait,      [:pointer],                 :int
    czmq_function :resolve,     :resolve,   [:pointer],                 :pointer

    def self.convert(czmq_obj)
      if Utils.check_for_pointer(czmq_obj)

        return czmq_obj
      elsif czmq_obj.respond_to?(:to_zsock) &&
            Utils.check_for_pointer(czmq_obj.to_zsock)

        return czmq_obj.to_zsock
      elsif czmq_obj.respond_to?(:to_zactor) &&
            Utils.check_for_pointer(czmq_obj.to_zactor)

        return czmq_obj.to_zactor
      else
        fail ArgumentError, "#{czmq_obj.class} is not a CZMQ::Zsock or CZMQ::Zactor"
      end
    end

    [:rep, :router, :pull, :pub, :xpub].each do |meth|
      instance_eval <<-RUBY, __FILE__, __LINE__
      def new_#{meth.to_s}(endpoints)
        sock = new(#{meth.inspect}, endpoints)
        sock.attach(endpoints, true)
        sock
      end
      RUBY
    end

    [:req, :dealer, :push, :xsub, :pair, :stream].each do |meth|
      instance_eval <<-RUBY, __FILE__, __LINE__
      def new_#{meth.to_s}(endpoints)
        sock = new(#{meth.inspect}, endpoints)
        sock.attach(endpoints, false)
        sock
      end
      RUBY
    end

    def self.new_sub(endpoints, *subscriptions)
      sock = new(:sub, endpoints, *subscriptions)
      sock.attach(endpoints, false)
      subscriptions.each do |subscription|
        sock.set_subscribe(subscription)
      end
      sock
    end

    def tell(*msgs)
      zmsg = Zmsg.new
      msgs.each {|msg| zmsg << msg}
      forward(zmsg)
    end

    alias_method :<<, :tell

    def forward(zmsg)
      zmsg.send_zmsg(@czmq_obj)
    end

    def recv
      Zmsg.recv(@czmq_obj)
    end

    # generated via https://github.com/neelance/ffi-gen

    czmq_function :tos, :tos, [:pointer], :int
    czmq_function :zap_domain, :zap_domain, [:pointer], :string
    czmq_function :mechanism, :mechanism, [:pointer], :int
    czmq_function :plain_server, :plain_server, [:pointer], :int
    czmq_function :plain_username, :plain_username, [:pointer], :string
    czmq_function :plain_password, :plain_password, [:pointer], :string
    czmq_function :curve_server, :curve_server, [:pointer], :int
    czmq_function :curve_publickey, :curve_publickey, [:pointer], :string
    czmq_function :curve_secretkey, :curve_secretkey, [:pointer], :string
    czmq_function :curve_serverkey, :curve_serverkey, [:pointer], :string
    czmq_function :gssapi_server, :gssapi_server, [:pointer], :int
    czmq_function :gssapi_plaintext, :gssapi_plaintext, [:pointer], :int
    czmq_function :gssapi_principal, :gssapi_principal, [:pointer], :string
    czmq_function :gssapi_service_principal, :gssapi_service_principal, [:pointer], :string
    czmq_function :ipv6, :ipv6, [:pointer], :int
    czmq_function :immediate, :immediate, [:pointer], :int
    czmq_function :ipv4only, :ipv4only, [:pointer], :int
    czmq_function :type, :type, [:pointer], :int
    czmq_function :sndhwm, :sndhwm, [:pointer], :int
    czmq_function :rcvhwm, :rcvhwm, [:pointer], :int
    czmq_function :affinity, :affinity, [:pointer], :int
    czmq_function :identity, :identity, [:pointer], :string
    czmq_function :rate, :rate, [:pointer], :int
    czmq_function :recovery_ivl, :recovery_ivl, [:pointer], :int
    czmq_function :sndbuf, :sndbuf, [:pointer], :int
    czmq_function :rcvbuf, :rcvbuf, [:pointer], :int
    czmq_function :linger, :linger, [:pointer], :int
    czmq_function :reconnect_ivl, :reconnect_ivl, [:pointer], :int
    czmq_function :reconnect_ivl_max, :reconnect_ivl_max, [:pointer], :int
    czmq_function :backlog, :backlog, [:pointer], :int
    czmq_function :maxmsgsize, :maxmsgsize, [:pointer], :int
    czmq_function :multicast_hops, :multicast_hops, [:pointer], :int
    czmq_function :rcvtimeo, :rcvtimeo, [:pointer], :int
    czmq_function :sndtimeo, :sndtimeo, [:pointer], :int
    czmq_function :tcp_keepalive, :tcp_keepalive, [:pointer], :int
    czmq_function :tcp_keepalive_idle, :tcp_keepalive_idle, [:pointer], :int
    czmq_function :tcp_keepalive_cnt, :tcp_keepalive_cnt, [:pointer], :int
    czmq_function :tcp_keepalive_intvl, :tcp_keepalive_intvl, [:pointer], :int
    czmq_function :tcp_accept_filter, :tcp_accept_filter, [:pointer], :string
    czmq_function :rcvmore, :rcvmore, [:pointer], :int
    czmq_function :fd, :fd, [:pointer], :int
    czmq_function :events, :events, [:pointer], :int
    czmq_function :last_endpoint, :last_endpoint, [:pointer], :string
    czmq_function :set_tos, :set_tos, [:pointer, :int], :void
    czmq_function :set_router_handover, :set_router_handover, [:pointer, :int], :void
    czmq_function :set_router_mandatory, :set_router_mandatory, [:pointer, :int], :void
    czmq_function :set_probe_router, :set_probe_router, [:pointer, :int], :void
    czmq_function :set_req_relaxed, :set_req_relaxed, [:pointer, :int], :void
    czmq_function :set_req_correlate, :set_req_correlate, [:pointer, :int], :void
    czmq_function :set_conflate, :set_conflate, [:pointer, :int], :void
    czmq_function :set_zap_domain, :set_zap_domain, [:pointer, :string], :void
    czmq_function :set_plain_server, :set_plain_server, [:pointer, :int], :void
    czmq_function :set_plain_username, :set_plain_username, [:pointer, :string], :void
    czmq_function :set_plain_password, :set_plain_password, [:pointer, :string], :void
    czmq_function :set_curve_server, :set_curve_server, [:pointer, :int], :void
    czmq_function :set_curve_publickey, :set_curve_publickey, [:pointer, :string], :void
    czmq_function :set_curve_publickey_bin, :set_curve_publickey_bin, [:pointer, :pointer], :void
    czmq_function :set_curve_secretkey, :set_curve_secretkey, [:pointer, :string], :void
    czmq_function :set_curve_secretkey_bin, :set_curve_secretkey_bin, [:pointer, :pointer], :void
    czmq_function :set_curve_serverkey, :set_curve_serverkey, [:pointer, :string], :void
    czmq_function :set_curve_serverkey_bin, :set_curve_serverkey_bin, [:pointer, :pointer], :void
    czmq_function :set_gssapi_server, :set_gssapi_server, [:pointer, :int], :void
    czmq_function :set_gssapi_plaintext, :set_gssapi_plaintext, [:pointer, :int], :void
    czmq_function :set_gssapi_principal, :set_gssapi_principal, [:pointer, :string], :void
    czmq_function :set_gssapi_service_principal, :set_gssapi_service_principal, [:pointer, :string], :void
    czmq_function :set_ipv6, :set_ipv6, [:pointer, :int], :void
    czmq_function :set_immediate, :set_immediate, [:pointer, :int], :void
    czmq_function :set_router_raw, :set_router_raw, [:pointer, :int], :void
    czmq_function :set_ipv4only, :set_ipv4only, [:pointer, :int], :void
    czmq_function :set_delay_attach_on_connect, :set_delay_attach_on_connect, [:pointer, :int], :void
    czmq_function :set_sndhwm, :set_sndhwm, [:pointer, :int], :void
    czmq_function :set_rcvhwm, :set_rcvhwm, [:pointer, :int], :void
    czmq_function :set_affinity, :set_affinity, [:pointer, :int], :void
    czmq_function :set_subscribe, :set_subscribe, [:pointer, :string], :void
    czmq_function :set_unsubscribe, :set_unsubscribe, [:pointer, :string], :void
    czmq_function :set_identity, :set_identity, [:pointer, :string], :void
    czmq_function :set_rate, :set_rate, [:pointer, :int], :void
    czmq_function :set_recovery_ivl, :set_recovery_ivl, [:pointer, :int], :void
    czmq_function :set_sndbuf, :set_sndbuf, [:pointer, :int], :void
    czmq_function :set_rcvbuf, :set_rcvbuf, [:pointer, :int], :void
    czmq_function :set_linger, :set_linger, [:pointer, :int], :void
    czmq_function :set_reconnect_ivl, :set_reconnect_ivl, [:pointer, :int], :void
    czmq_function :set_reconnect_ivl_max, :set_reconnect_ivl_max, [:pointer, :int], :void
    czmq_function :set_backlog, :set_backlog, [:pointer, :int], :void
    czmq_function :set_maxmsgsize, :set_maxmsgsize, [:pointer, :int], :void
    czmq_function :set_multicast_hops, :set_multicast_hops, [:pointer, :int], :void
    czmq_function :set_rcvtimeo, :set_rcvtimeo, [:pointer, :int], :void
    czmq_function :set_sndtimeo, :set_sndtimeo, [:pointer, :int], :void
    czmq_function :set_xpub_verbose, :set_xpub_verbose, [:pointer, :int], :void
    czmq_function :set_tcp_keepalive, :set_tcp_keepalive, [:pointer, :int], :void
    czmq_function :set_tcp_keepalive_idle, :set_tcp_keepalive_idle, [:pointer, :int], :void
    czmq_function :set_tcp_keepalive_cnt, :set_tcp_keepalive_cnt, [:pointer, :int], :void
    czmq_function :set_tcp_keepalive_intvl, :set_tcp_keepalive_intvl, [:pointer, :int], :void
    czmq_function :set_tcp_accept_filter, :set_tcp_accept_filter, [:pointer, :string], :void
  end
end
