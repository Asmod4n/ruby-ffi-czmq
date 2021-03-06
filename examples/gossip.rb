﻿require 'bundler/setup'
require 'ffi-czmq'

class BaseConfig
  include CZMQ
  extend Forwardable

  def_delegators :@parent_pipe, :<<, :tell, :recv, :wait, :signal, :destructor

  def initialize
    @parent_pipe = Zactor.new_actor(&method(:run))
    at_exit { destructor }
  end

  private

  def run(child_pipe)
    @reactor = Zloop.new
    @reactor.add_reader(child_pipe, &method(:handle_pipe))

    config = Zconfig.load("#{File.dirname(__FILE__)}/examples.cfg")
    @base = Zactor.new_zgossip(config.resolve('/gossip/base/logprefix', nil))
    @base.tell('BIND', config.resolve('/gossip/base/endpoint', nil))

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
    puts zsock.recv.print
    0
  end
end

base = BaseConfig.new

config = CZMQ::Zconfig.load("#{File.dirname(__FILE__)}/examples.cfg")
node_prefix = config.resolve('/gossip/node/logprefix', nil)
node_endpoint = config.resolve('/gossip/node/endpoint', nil)
node_connect = config.resolve('/gossip/node/connect', nil)

nodes = []

4.times do |i|
  nodes << node = CZMQ::Zactor.new_zgossip("#{node_prefix}#{i}")
  node.tell('CONNECT', node_connect)
  node.tell('BIND', node_endpoint)
  node << 'PORT'
  port = node.recv.last.to_str
  node.tell('PUBLISH', "service#{i}", "tcp://localhost:#{port}")
end

sleep 1
