require_relative 'libczmq'
require_relative 'zstr'

module CZMQ
  class Zclock
    extend ::LibCZMQ

    czmq_function :sleep,   :sleep,   [:int], :void
    czmq_function :time,    :time,    [],     :int64
    czmq_function :mono,    :mono,    [],     :int64
    czmq_function :usecs,   :usecs,   [],     :int64
    czmq_function :timestr, :timestr, [],     :pointer

    def self.time_str
      Zstr.read_string(timestr)
    end

    def self.test(verbose = false)
      start = Zclock.time
      Zclock.sleep 10
      raise unless (Zclock.time - start) >= 10
      start = Zclock.mono
      usecs = Zclock.usecs
      Zclock.sleep 10
      raise unless (Zclock.mono - start) >= 10
      raise unless (Zclock.usecs - usecs) >= 10000
      puts time_str if verbose
    end
  end
end
