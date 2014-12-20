require_relative 'libczmq'

module CZMQ
  class Zconfig
    extend ::LibCZMQ

    czmq_constructor [:string, :pointer]
    czmq_destructor

    czmq_function :name,              :name,        [:pointer],                     :string
    czmq_function :value,             :value,       [:pointer],                     :string
    czmq_function :put,               :put,         [:pointer, :string, :string],   :void
    czmq_function :set_name,          :set_name,    [:pointer, :string],            :void
    czmq_function :set_value,         :set_value,   [:pointer, :string, :varargs],  :void
    czmq_function :child_zconfig,     :child,       [:pointer],                     :pointer
    czmq_function :next_zconfig,      :next,        [:pointer],                     :pointer
    czmq_function :locate_zconfig,    :locate,      [:pointer, :string],            :pointer
    czmq_function :resolve,           :resolve,     [:pointer, :string, :string],   :string
    czmq_function :zconfig_at_depth,  :at_depth,    [:pointer, :int],               :pointer
    czmq_function :execute_zconfig,   :execute,     [:pointer, :pointer, :pointer], :int
    czmq_function :set_comment,       :set_comment, [:pointer, :string, :varargs],  :void
    czmq_function :load_zconfig,      :load,        [:string],                      :pointer
    czmq_function :save,              :save,        [:pointer, :string],            :int
    czmq_function :filename,          :filename,    [:pointer],                     :string
    czmq_function :has_changed,       :has_changed, [:pointer],                     :bool

    def self.load(filename)
      unless (zconfig = load_zconfig(filename)).null?
        new_from_czmq_obj(zconfig)
      else
        fail IOError, Utils.error, caller
      end
    end

    def child
      unless (child_config = child_zconfig).null?
        self.class.new_from_czmq_obj(child_zconfig, nil)
      end
    end

    def next
      unless (next_config = next_zconfig).null?
        self.class.new_from_czmq_obj(next_zconfig, nil)
      end
    end

    def execute(&block)
      zconfig_fct = FFI::Function.new(:int, [:pointer, :pointer, :int], blocking: true) do |zconfig_t, args, level|
        zconfig = self.class.new_from_czmq_obj(zconfig_t, nil)
        yield zconfig, level
      end

      execute_zconfig(zconfig_fct, nil)
    end

    def locate(path)
      unless (zconfig = locate_zconfig(path)).null?
        self.class.new_from_czmq_obj(zconfig, nil)
      end
    end

    def at_depth(level)
      unless (zconfig = zconfig_at_depth(level)).null?
        self.class.new_from_czmq_obj(zconfig, nil)
      end
    end
  end
end
