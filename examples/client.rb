require 'bundler/setup'
require 'ffi-czmq'

config = CZMQ::Zconfig.load("#{File.dirname(__FILE__)}/examples.cfg")
connect = config.resolve('/client/connect', nil)
client = CZMQ::Zsock.new(config.resolve('/client/type', nil), connect)
client.attach(connect, false)

4.times do
  client.tell(nil, 'hello')
end

4.times do
  client.recv.print
end
