require 'bundler/setup'
require 'ffi-czmq'

client = CZMQ::Zsock.new_dealer('tcp://localhost:7000')

4.times do
  client.tell(nil, 'hello')
end

4.times do
  puts client.recv.to_a.inspect
end
