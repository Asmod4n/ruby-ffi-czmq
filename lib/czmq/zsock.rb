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

    czmq_function :attach,    :attach,    [:pointer, :string, :bool], :int
    czmq_function :endpoint,  :endpoint,  [:pointer],                 :string
    czmq_function :type_str,  :type_str,  [:pointer],                 :string
    czmq_function :signal,    :signal,    [:pointer, :uchar],         :int
    czmq_function :wait,      :wait,      [:pointer],                 :int
    czmq_function :resolve,   :resolve,   [:pointer],                 :pointer

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

    def self.new_sub(endpoints, subscribe = nil)
      sock = new(:sub, endpoints, subscribe)
      sock.attach(endpoints, false)
      if subscribe
        sock.set_subscribe(subscribe)
      end
      sock
    end

    def tell(*msgs)
      zmsg = Zmsg.new
      msgs.each {|msg| zmsg << msg}
      zmsg.send_zmsg(@czmq_obj)
    end

    alias_method :<<, :tell

    def forward(zmsg)
      zmsg.send_zmsg(@czmq_obj)
    end

    def recv
      Zmsg.recv(@czmq_obj)
    end

    def method_missing(meth, *args, &blk)
      if args.length == 1 &&
         meth.to_s =~ SET_SOCKOPT &&
         (args.first.is_a?(Integer) || args.first.is_a?(String))
        begin

          self.class.instance_eval <<-RUBY, __FILE__, __LINE__
          attach_function #{meth.inspect}, "zsock_#{meth.to_s}", [:pointer, :varargs], :void
          RUBY

        rescue FFI::NotFoundError
          super
        else

          if args.first.is_a?(Integer)
            self.class.class_eval <<-RUBY, __FILE__, __LINE__
            def #{meth.to_s}(arg)
              self.class.#{meth.to_s}(@czmq_obj, :int, arg)
            end
            RUBY
          elsif args.first.is_a?(String)
            self.class.class_eval <<-RUBY, __FILE__, __LINE__
            def #{meth.to_s}(arg)
              self.class.#{meth.to_s}(@czmq_obj, :string, arg)
            end
            RUBY
          end

          send meth, args.first

        end
      else
        super
      end

    end
  end
end
