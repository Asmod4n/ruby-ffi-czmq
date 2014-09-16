require 'bundler/setup'
require 'ffi-czmq'

class Worker
  extend Forwardable

  def_delegators :@parent_pipe, :<<, :tell, :recv, :wait, :destructor

  def initialize(id)
    @id = id
    @parent_pipe = CZMQ::Zactor.new_actor(&method(:run))
  end

  private

  def run(child_pipe)
    @reactor = CZMQ::Zloop.new
    @reactor.set_verbose(true)
    @reactor.add_reader(child_pipe, &method(:handle_pipe))

    @worker = CZMQ::Zsock.new_dealer('inproc://backend')
    @reactor.add_reader(@worker, &method(:handle_worker))

    child_pipe.signal(0)

    @reactor.start
  end

  def handle_pipe(zsock)
    msg = zsock.recv

    case msg.first.to_str
    when '$TERM'
      zsock.signal(0)
      -1
    end
  end

  def handle_worker(zsock)
    msg = zsock.recv

    sender = msg.first
    answer = CZMQ::Zmsg.new
    answer << sender << nil << @id << 'welcome'
    zsock.forward(answer)
  end
end

proxy = CZMQ::Zactor.new_zproxy
proxy << 'VERBOSE'

proxy.tell('BACKEND', 'DEALER', 'inproc://backend')
proxy.wait
proxy.tell('FRONTEND', 'ROUTER', 'tcp://*:7000')
proxy.wait

workers = []
4.times {|i| workers << Worker.new("worker#{i}") }

trap('INT') do
  exit
end

trap('TERM') do
  exit
end

sleep
