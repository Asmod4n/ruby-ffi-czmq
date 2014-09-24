require 'bundler/setup'
require 'ffi-czmq'

class Worker
  include CZMQ
  extend Forwardable

  def_delegators :@parent_pipe, :<<, :tell, :recv, :wait, :signal, :destructor

  def initialize(id)
    @id = id
    @parent_pipe = Zactor.new_actor(&method(:run))
  end

  private

  def run(child_pipe)
    config = Zconfig.load("#{File.dirname(__FILE__)}/examples.cfg")
    endpoint = config.resolve('/proxy/backend/endpoint', nil)

    worker = Zsock.new(config.resolve('/proxy/backend/type', nil), endpoint)
    worker.connect(endpoint)

    child_pipe_sock = Zsock.convert(child_pipe)
    worker_sock = Zsock.convert(worker)

    poller = Zpoller.new_poller(child_pipe_sock, worker_sock)

    @terminated = false

    child_pipe.signal(0)

    until @terminated
      which = nil
      begin
        which = poller.wait(-1)
      rescue RuntimeError
        @terminated = true
      else
        case which
        when child_pipe_sock
          handle_pipe(child_pipe)
        when worker_sock
          handle_worker(worker)
        end
      end
    end
  end

  def handle_pipe(zsock)
    msg = zsock.recv
    command = msg.first.to_str

    Zsys.info("#{@id}: API command=#{command}")

    case command
    when '$TERM'
      @terminated = true
    end
  end

  def handle_worker(zsock)
    msg = zsock.recv

    msg.last = :welcome.to_s
    msg << @id
    zsock.forward(msg)
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
