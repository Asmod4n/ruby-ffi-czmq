require 'bundler/setup'
require 'ffi-czmq'

class BaseConfig
  def initialize(endpoint)
    @endpoint = endpoint
    @parent_pipe = CZMQ::Zactor.new_actor(&method(:run))
  end

  private

  def run(child_pipe)
    @reactor = CZMQ::Zloop.new
    @reactor.add_reader(child_pipe, &method(:handle_pipe))

    @base = CZMQ::Zactor.new_zgossip('base')
    @base.tell('BIND', @endpoint)

    @reactor.add_reader(@base, &method(:handle_gossip))

    child_pipe.signal(0)

    @reactor.start
  end

  def handle_pipe(zsock)
    msg = zsock.recv

    case msg.first.to_str
    when '$TERM'
      -1
    end
  end

  def handle_gossip(zsock)
    puts zsock.recv.to_a.inspect
    0
  end
end

base = BaseConfig.new('tcp://*:7001')

node1 = CZMQ::Zactor.new_zgossip('node1')
node1.tell('BIND', 'tcp://*:*')
node1.tell('CONNECT', 'tcp://localhost:7001')

node1 << 'PORT'
port1 = node1.recv.last.to_str
node1.tell('PUBLISH', 'service1', "tcp://localhost:#{port1}")

node2 = CZMQ::Zactor.new_zgossip('node2')
node2.tell('BIND', 'tcp://*:*')
node2.tell('CONNECT', 'tcp://localhost:7001')

node2 << 'PORT'
port2 = node2.recv.last.to_str
node2.tell('PUBLISH', 'service2', "tcp://localhost:#{port2}")

sleep 1
