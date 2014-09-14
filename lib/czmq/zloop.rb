require_relative 'libczmq'
require_relative 'zsock'
require_relative 'utils'

module CZMQ
  class Zloop
    extend ::LibCZMQ

    czmq_constructor
    czmq_destructor

    czmq_function :reader,        :reader,        [:pointer, :pointer, :pointer, :pointer],         :int
    czmq_function :reader_end,    :reader_end,    [:pointer, :pointer],                             :void
    czmq_function :timer,         :timer,         [:pointer, :size_t, :size_t, :pointer, :pointer], :int
    czmq_function :timer_end,     :timer_end,     [:pointer, :int],                                 :int
    czmq_function :set_verbose,   :set_verbose,   [:pointer, :bool],                                :void
    czmq_function :start,         :start,         [:pointer],                                       :int

    def initialize
      @reader_callbacks = []
      @timer_callbacks  = []
    end

    def add_reader(zsock, &block)
      zloop_reader_fn = FFI::Function.new(:int, [:pointer, :pointer, :pointer], :blocking => true) do |zloop_t, zsock_t, args|
        zsocky = Zsock.new_from_czmq_obj(zsock_t, nil)
        block.call(zsocky)
      end

      reader(Zsock.convert(zsock), zloop_reader_fn, nil)
      @reader_callbacks << {zsock: zsock, zloop_reader_fn: zloop_reader_fn, block: block}
    end

    def remove_reader(zsock)
      @reader_callbacks.delete_if {|reader| reader[:zsock] == zsock}
      reader_end(Zsock.convert(zsock))
    end

    def add_timer(delay, times, &block)
      zloop_timer_fn = FFI::Function.new(:int, [:pointer, :int, :pointer], :blocking => true) do |zloop_t, timer_id, args|
        block.call(timer_id)
      end

      timer_id = timer(delay, times, zloop_timer_fn, nil)
      @timer_callbacks << {timer_id: timer_id, delay: delay, times: times, zloop_timer_fn: zloop_timer_fn, block: block}
      timer_id
    end

    def remove_timer(timer_id)
      @timer_callbacks.delete_if {|timer| timer[:timer_id] == timer_id}
      timer_end(timer_id)
    end
  end
end
