require 'bundler/setup'
require 'ffi-czmq'

base = CZMQ::Zactor.new_zgossip('base')
base.tell('BIND', 'tcp://*:7001')

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
base << 'STATUS'

loop do
  msg = base.recv
  if msg.first.to_str == 'STATUS'
    break
  else
    puts msg.to_a.inspect
  end
end
