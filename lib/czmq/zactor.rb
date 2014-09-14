require_relative 'libczmq'
require_relative 'utils'
require_relative 'zsock'
require_relative 'zmsg'

module CZMQ
  class Zactor
    extend ::LibCZMQ

    czmq_constructor [:pointer, :pointer]
    czmq_destructor

    czmq_function   :resolve,     :resolve,   [:pointer],                  :pointer
    attach_function :zauth,       :zauth,     [:pointer, :pointer], :void, :blocking => true
    attach_function :zbeacon,     :zbeacon,   [:pointer, :pointer], :void, :blocking => true
    attach_function :zmonitor,    :zmonitor,  [:pointer, :pointer], :void, :blocking => true
    attach_function :zproxy,      :zproxy,    [:pointer, :pointer], :void, :blocking => true

    def self.new_actor(&actor)
      zactor_fn = FFI::Function.new(:void, [:pointer, :pointer], :blocking => true) do |zsock_t, args|
        child_pipe = Zsock.new_from_czmq_obj(zsock_t, nil)
        actor.call(child_pipe)
      end

      zactor = new(zactor_fn, nil)
      at_exit { zactor.destructor }
      zactor
    end

    [:zauth, :zbeacon, :zproxy].each do |meth|
      instance_eval <<-RUBY, __FILE__, __LINE__
      def new_#{meth.to_s}
        zactor_fn = FFI::Function.new(:void, [:pointer, :pointer], :blocking => true) do |zsock_t, args|
          #{meth.to_s}(zsock_t, args)
        end

        new(zactor_fn, nil)
      end
      RUBY
    end

    def self.new_zmonitor(sock)
      zactor_fn = FFI::Function.new(:void, [:pointer, :pointer], :blocking => true) do |zsock_t, args|
        zmonitor(zsock_t, args)
      end

      new(zactor_fn, Zsock.convert(sock))
    end

    def tell(*msgs)
      zmsg = Zmsg.new
      msgs.each {|msg| zmsg << msg}
      zmsg.send_zmsg(@czmq_obj)
    end

    alias_method :<<, :tell

    def recv
      Zmsg.recv(@czmq_obj)
    end

    def wait
      Zsock.wait(@czmq_obj)
    end
  end
end
