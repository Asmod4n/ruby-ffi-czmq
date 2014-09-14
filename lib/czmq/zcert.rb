require_relative 'utils'
require_relative 'libczmq'

if CZMQ::Utils.has_curve
  module CZMQ
    class Zcert
      extend ::LibCZMQ

      czmq_constructor
      czmq_destructor

      czmq_function :public_txt,  :public_txt,  [:pointer],           :string
      czmq_function :secret_txt,  :secret_txt,  [:pointer],           :string
      czmq_function :load_zcert,  :load,        [:string],            :pointer
      czmq_function :save,        :save,        [:pointer, :string],  :int
      czmq_function :save_public, :save_public, [:pointer, :string],  :int
      czmq_function :save_secret, :save_secret, [:pointer, :string],  :int
      czmq_function :apply,       :apply,       [:pointer, :pointer], :void
      czmq_function :dup_zcert,   :dup,         [:pointer],           :pointer
      czmq_function :eq,          :eq,          [:pointer, :pointer], :bool

      def self.convert(cert)
        if Utils.check_for_pointer(cert)

          return cert
        elsif cert.respond_to?(:to_zcert) &&
              Utils.check_for_pointer(cert.to_zcert)

          return cert.to_zcert
        else
          fail ArgumentError, "#{cert.class} is not a #{self.class}"
        end
      end

      def self.load(filename)
        unless (zcert = load_zcert(filename)).null?
          new_from_czmq_obj(zcert)
        else
          fail IOError, Utils.error
        end
      end

      def dup
        self.class.new_from_czmq_obj(dup_zcert)
      end

      def ==(other)
        eq(self.class.convert(other))
      end

      def !=(other)
        ! self.==(other)
      end
    end
  end
end
