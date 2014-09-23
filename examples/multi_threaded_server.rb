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

    config = CZMQ::Zconfig.load("#{File.dirname(__FILE__)}/examples.cfg")
    endpoint = config.resolve('/proxy/backend/endpoint', nil)

    @worker = CZMQ::Zsock.new(config.resolve('/proxy/backend/type', nil), endpoint)
    @worker.connect(endpoint)

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
    zsock.tell(sender, nil, @id, 'welcome')
  end
end

proxy = CZMQ::Zactor.new_zproxy
proxy << 'VERBOSE'

config = CZMQ::Zconfig.load("#{File.dirname(__FILE__)}/examples.cfg")

proxy.tell('BACKEND', config.resolve('/proxy/backend/type', nil), config.resolve('/proxy/backend/endpoint', nil))
proxy.wait

workers = []
4.times {|i| workers << Worker.new("worker#{i}") }

proxy.tell('FRONTEND', config.resolve('/proxy/frontend/type', nil), config.resolve('/proxy/frontend/endpoint', nil))
proxy.wait

# manual destruction is needed here i am afraid.
# while i am trying to let the garbage collector do its work so it feels more like ruby
# i have yet to find a way how to destroy the objects in the right order without
# having to create a registry of sorts for czmq objects.
# (you are supposed to terminate actors first which will then cleanup themself, but the way
# at_exit works its the other way around ... and without the at_exit handlers
# the process won't shut down with one SIGTERM or SIGINT, but only when you send them twice.)

trap('INT') do
  workers.each {|worker| worker.destructor }
  exit
end

trap('TERM') do
  workers.each {|worker| worker.destructor }  
  exit
end

sleep
