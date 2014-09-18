require 'bundler/setup'
require 'ffi-czmq'

config = CZMQ::Zconfig.load("#{File.dirname(__FILE__)}/examples.cfg")
client = CZMQ::Zsock.new_dealer(config.resolve('/client/endpoint', nil))

4.times do
  client.tell(nil, 'hello')
end

4.times do
  puts client.recv.to_a.inspect
end
