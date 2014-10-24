require_relative 'libczmq'
require_relative 'utils'
require_relative 'zsock'
require_relative 'zmsg'

module CZMQ
  class Zactor
    extend ::LibCZMQ

    czmq_constructor [:pointer, :pointer]
    czmq_destructor

    czmq_function   :resolve,     :resolve,   [:pointer],           :pointer
    attach_function :zauth,       :zauth,     [:pointer, :pointer], :void, blocking: true
    attach_function :zbeacon,     :zbeacon,   [:pointer, :pointer], :void, blocking: true
    attach_function :zgossip,     :zgossip,   [:pointer, :string],  :void, blocking: true
    attach_function :zmonitor,    :zmonitor,  [:pointer, :pointer], :void, blocking: true
    attach_function :zproxy,      :zproxy,    [:pointer, :pointer], :void, blocking: true

    def self.new_actor(&actor)
      zactor_fn = FFI::Function.new(:void, [:pointer, :pointer], blocking: true) do |zsock_t, args|
        child_pipe = Zsock.new_from_czmq_obj(zsock_t, nil)
        actor.call(child_pipe)
      end

      new(zactor_fn, nil)
    end

    [:zauth, :zbeacon, :zproxy].each do |meth|
      instance_eval <<-RUBY, __FILE__, __LINE__
      const_set("#{meth.to_s.upcase}", FFI::Function.new(:void, [:pointer, :pointer], blocking: true) {|zsock_t, args| #{meth.to_s}(zsock_t, args)})
  
      def new_#{meth.to_s}
        new(#{meth.to_s.upcase}, nil)
      end
      RUBY
    end

    ZMONITOR = FFI::Function.new(:void, [:pointer, :pointer], blocking: true) {|zsock_t, args| zmonitor(zsock_t, args)}

    def self.new_zmonitor(sock)
      new(ZMONITOR, Zsock.convert(sock))
    end

    ZGOSSIP = FFI::Function.new(:void, [:pointer, :string], blocking: true) {|zsock_t, args| zgossip(zsock_t, args)}

    def self.new_zgossip(logprefix)
      new(ZGOSSIP, logprefix)
    end

    def tell(*msgs)
      zmsg = Zmsg.new
      msgs.each {|msg| zmsg << msg }
      zmsg.send_zmsg(@czmq_obj)
    end

    alias_method :<<, :tell

    def recv
      Zmsg.recv(@czmq_obj)
    end

    def wait
      Zsock.wait(@czmq_obj)
    end

    def signal(uchar = 0)
      Zsock.signal(@czmq_obj, uchar)
    end
  end
end
