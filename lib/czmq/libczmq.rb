require 'ffi'
require_relative 'utils'
require_relative 'sock_type'

module LibCZMQ
  def self.extended(klass)
    klass.extend FFI::Library
    klass.ffi_lib('czmq', 'libzmq')
  end

  def czmq_class
    return @czmq_class if @czmq_class
    @czmq_class = "#{self.singleton_class.inspect.split('::').last[0...-1].downcase}".to_sym
  end

  def czmq_constructor(constructor_params = [])
    module_eval <<-RUBY, __FILE__, __LINE__
    if #{czmq_class == :zsock}
      attach_function :constructor, "#{czmq_class}_new_", [:int, :string, :size_t], :pointer, blocking: true
    else
      attach_function :constructor, "#{czmq_class}_new",  #{constructor_params.inspect},  :pointer, blocking: true
    end
    attach_function :test,  "#{czmq_class}_test", [:bool],  :void,  blocking: true

    def self.new_from_czmq_obj(czmq_obj, owned_by_ruby = true)
      if CZMQ::Utils.check_for_pointer(czmq_obj)
        instance = allocate

        instance.instance_variable_set(:@czmq_obj, czmq_obj)
        instance.instance_variable_set(:@owned_by_ruby, owned_by_ruby)
        instance.send :setup_finalizer

        if instance.method(:initialize).parameters.size > 0
          instance.send :initialize, czmq_obj
        else
          instance.send :initialize
        end

        instance
      else
        fail ArgumentError, "Didn't pass a valid Pointer"
      end
    end

    def self.new(*args)
      instance = allocate
      if #{czmq_class == :zsock}
        czmq_obj = instance.class.constructor(CZMQ::Zsock::SockType[args.first], __FILE__, __LINE__)
      elsif #{constructor_params.empty?}
        czmq_obj = instance.class.constructor
      else
        czmq_obj = instance.class.constructor(*args)
      end

      !czmq_obj.null? ||fail("Cannot allocate #{czmq_class} because of #{CZMQ::Utils.error}")

      instance.instance_variable_set(:@czmq_obj, czmq_obj)
      instance.instance_variable_set(:@owned_by_ruby, true)

      instance.send :setup_finalizer
      if instance.method(:initialize).parameters.size > 0
        instance.send :initialize, *args
      else
        instance.send :initialize
      end

      instance
    end

    def to_#{czmq_class}
      @czmq_obj
    end

    def to_czmq
      @czmq_obj
    end
    RUBY
  end

  def czmq_destructor
    module_eval <<-RUBY, __FILE__, __LINE__
    if #{czmq_class == :zsock}
      attach_function :destructor,  :zsock_destroy_,  [:pointer, :string, :size_t], :void,  blocking: true
    else
      attach_function :destructor,  "#{czmq_class}_destroy",  [:pointer], :void,  blocking: true
    end

    def destructor
      remove_finalizer

      if @owned_by_ruby
        if CZMQ::Utils.check_for_pointer(@czmq_obj)
          FFI::MemoryPointer.new(:pointer) do |p|
            p.write_pointer(@czmq_obj)
            if #{czmq_class == :zsock}
              self.class.destructor(p, __FILE__, __LINE__)
            else
              self.class.destructor(p)
            end
          end
        end
      end

      instance_variables.each do |var|
        instance_variable_set(var, nil)
      end

      true
    end

    private

    def setup_finalizer
      if @owned_by_ruby
        at_exit { destructor }
      end
      ObjectSpace.define_finalizer(self, self.class.close_instance(self))
    end

    def remove_finalizer
      ObjectSpace.undefine_finalizer self
    end

    def self.close_instance(selfie)
      Proc.new do
        selfie.destructor
      end
    end
    RUBY
  end

  def czmq_function(name, function, arguments, returns)
    fn = "#{czmq_class}_#{function}"

    module_eval <<-RUBY, __FILE__, __LINE__
    attach_function #{name.inspect}, #{fn.inspect}, #{arguments.inspect}, #{returns.inspect}, blocking: true

    def #{name}(*args)
      if CZMQ::Utils.check_for_pointer(@czmq_obj)

        case #{function.inspect}
        when :send
          z_obj = @owned_by_ruby ? self : dup

          czmq_obj = FFI::MemoryPointer.new(:pointer)
          czmq_obj.write_pointer(z_obj.to_czmq)
          zsock = CZMQ::Zsock.convert(args.first)
          result = self.class.#{name}(czmq_obj, zsock, *args[1..-1])

          unless(#{czmq_class == :zframe} && args.last & CZMQ::Zframe::REUSE > 0)
            z_obj.instance_variable_set(:@owned_by_ruby, nil)
          end
        when :insert, :append, :prepend
          if args.first.instance_variable_get(:@owned_by_ruby)
            z_obj = args.first
          else
            z_obj = args.first.dup
          end

          czmq_obj = FFI::MemoryPointer.new(:pointer)
          czmq_obj.write_pointer(z_obj.to_czmq)
          result = self.class.#{name}(@czmq_obj, czmq_obj)

          z_obj.instance_variable_set(:@owned_by_ruby, nil)
        when :reload
          czmq_obj = FFI::MemoryPointer.new(:pointer)
          czmq_obj.write_pointer(@czmq_obj)
          result = self.class.#{name}(czmq_obj)
        else
          result = self.class.#{name}(@czmq_obj, *args)
        end

      else
        fail "#{czmq_class} is not initialized"
      end

      case #{returns.inspect}
      when :pointer
        !result.null? ||fail(CZMQ::Utils.error)
        result
      when :int
        case #{function.inspect}
        when :send,/^save.*$/
          result != -1 ||fail(IOError, CZMQ::Utils.error)
        else
          result != -1 ||fail(CZMQ::Utils.error)
        end
        result
      else
        result
      end

    end
    RUBY
  end
end

require_relative 'zsys'
require_relative 'zframe'
require_relative 'zsock'
