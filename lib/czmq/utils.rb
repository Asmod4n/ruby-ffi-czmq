require 'ffi'

module CZMQ
  module Utils
    HEXY = 'H*'.freeze
    extend FFI::Library

    ffi_lib :libzmq, :czmq

    attach_function :zmq_version,   :zmq_version,     [:buffer_out, :buffer_out, :buffer_out], :void,    blocking: true
    attach_function :zsys_version,  :zsys_version,    [:buffer_out, :buffer_out, :buffer_out], :void,    blocking: true
    attach_function :errno,         :zmq_errno,       [],                                   :int
    attach_function :strerror,      :zmq_strerror,    [:int],                               :string

    module_function

    def version
      unless @version
        z_major = FFI::MemoryPointer.new :pointer
        z_minor = FFI::MemoryPointer.new :pointer
        z_patch = FFI::MemoryPointer.new :pointer

        c_major = FFI::MemoryPointer.new :pointer
        c_minor = FFI::MemoryPointer.new :pointer
        c_patch = FFI::MemoryPointer.new :pointer

        zmq_version  z_major, z_minor, z_patch
        zsys_version c_major, c_minor, c_patch

        @version = {
           zmq: {major: z_major.read_int, minor: z_minor.read_int, patch: z_patch.read_int},
          czmq: {major: c_major.read_int, minor: c_minor.read_int, patch: c_patch.read_int}
        }
      end

      @version
    end

    def check_for_pointer(ptr)
      ptr.is_a?(FFI::Pointer) && !ptr.null?
    end

    def error
      strerror(errno)
    end

    def bin2hex(bytes)
      bytes.to_str.unpack(HEXY).first
    end

    def hex2bin(hex)
      [hex].pack(HEXY)
    end

    if version[:czmq][:major] < 3
      fail LoadError, 'This needs at least czmq 3'
    end
  end
end
