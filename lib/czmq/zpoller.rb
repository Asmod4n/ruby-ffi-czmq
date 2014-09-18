require_relative 'libczmq'

module CZMQ
  class Zpoller
    extend ::LibCZMQ

    czmq_constructor [:pointer, :varargs]
    czmq_destructor

    czmq_function :add,         :add,         [:pointer,  :pointer],  :int
    czmq_function :remove,      :remove,      [:pointer,  :pointer],  :int
    czmq_function :wait,        :wait,        [:pointer,  :int],      :pointer
    czmq_function :expired,     :expired,     [:pointer],             :bool
    czmq_function :terminated,  :terminated,  [:pointer],             :pointer

    def self.new_poller(*pollitems)
      zsocks = []
      pollitems.each do |pollitem|
        zsocks << Zsock.convert(pollitem)
      end
      first_sock = zsocks.delete(zsocks.first)
      other_socks = ([ :pointer ] * zsocks.size).zip(zsocks).flatten
      new(first_sock, *other_socks, :pointer, nil)
    end
  end
end
