require_relative 'libczmq'

module CZMQ
  class Ziflist
    include Enumerable
    extend ::LibCZMQ

    czmq_constructor
    czmq_destructor

    czmq_function :reload,    :reload,    [:pointer], :void
    czmq_function :size,      :size,      [:pointer], :size_t
    czmq_function :first,     :first,     [:pointer], :string
    czmq_function :next,      :next,      [:pointer], :string
    czmq_function :address,   :address,   [:pointer], :string
    czmq_function :broadcast, :broadcast, [:pointer], :string
    czmq_function :netmask,   :netmask,   [:pointer], :string

    def each
      yield first
      size.pred.times do
        yield self.next
      end
    end

    def to_h
      hsh = {}
      each do |interface|
        hsh[interface] = {
          address:    address,
          broadcast:  broadcast,
          netmask:    netmask
        }
      end
      hsh
    end
  end
end
