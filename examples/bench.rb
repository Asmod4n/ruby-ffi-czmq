require 'bundler/setup'
require 'ffi-czmq'
require 'hitimes'
include CZMQ

class Bench
  include CZMQ
  extend Forwardable

  def_delegators :@parent_pipe, :<<, :tell, :recv, :wait, :signal, :destructor, :to_czmq

  def initialize
    @parent_pipe = Zactor.new_actor(&method(:run))
    at_exit { destructor }
  end

  private

  def run(child_pipe)
    child_sock = Zsock.convert(child_pipe)

    child_pipe.signal(0)

    loop { Zframe.recv_zframe(child_sock) }
  end
end

bench = Bench.new

bench_sock = Zsock.convert(bench.to_czmq)
frame = Zframe.new('hello', 5)
frame_ptr = FFI::MemoryPointer.new(:pointer)
frame_ptr.write_pointer(frame.to_czmq)

duration = Hitimes::Interval.measure do
  100000.times do
    Zframe.send_zframe(frame_ptr, bench_sock, Zframe::REUSE)
  end
end

puts duration
