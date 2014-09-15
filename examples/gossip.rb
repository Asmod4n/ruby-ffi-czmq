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

nodes = []

4.times do |i|
  nodes << node = CZMQ::Zactor.new_zgossip("node#{i}")
  node.tell('BIND', 'tcp://*:*')
  node.tell('CONNECT', 'tcp://localhost:7001')
  node << 'PORT'
  port = node.recv.last.to_str
  node.tell('PUBLISH', "service#{i}", "tcp://localhost:#{port}")
end

sleep 1
