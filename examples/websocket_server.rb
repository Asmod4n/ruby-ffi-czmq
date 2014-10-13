require 'bundler/setup'
require 'ffi-czmq'
require 'websocket/driver'
require 'hitimes'

class Client
  extend Forwardable

  def_delegators :@driver, :parse

  def initialize(client_id, server)
    @client_id, @server = client_id, server
    @latency = Hitimes::TimedMetric.new(:latency)
    @driver = WebSocket::Driver.server(self)

    @driver.on(:connect) do
      if WebSocket::Driver.websocket?(@driver.env)
        @driver.start
      else
        @server.disconnect(@client_id)
      end
    end

    @driver.on(:message) {|e| @driver.frame(e.data); puts e.inspect }
    @driver.on(:close)   {|e| @server.disconnect(@client_id); puts e.inspect }
  end

  def write(data)
    @server.write(@client_id, data)
  end

  def ping
    @latency.start
    @driver.ping(@client_id.inspect) do
      @latency.stop
      puts "#{@client_id.inspect} latency: #{@latency.mean}"
    end
  end
end

class Server
  include CZMQ
  extend Forwardable

  def_delegators :@parent_pipe, :<<, :tell, :recv, :wait, :signal, :destructor

  def initialize
    @parent_pipe = Zactor.new_actor(&method(:run))
    at_exit { destructor }
  end

  def disconnect(client_id)
    @clients.delete(client_id)
    write(client_id, nil)
  end

  def write(client_id, data)
    @server.tell(client_id, data)
  end

  private

  def run(child_pipe)
    @reactor = Zloop.new
    @reactor.add_reader(child_pipe, &method(:handle_pipe))

    @server = Zsock.new_stream('@tcp://*:7002')
    @server.set_maxmsgsize(1024 * 1024)

    @reactor.add_reader(@server, &method(:handle_server))

    @clients = {}

    @reactor.add_timer(5000, 0) do |timer_id|
      @clients.each_value do |client|
        client.ping
      end
    end

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

  def handle_server(zsock)
    msg = zsock.recv

    client_id = msg.first.to_str
    data = msg.next.to_str

    unless @clients.include?(client_id)
      @clients[client_id] = Client.new(client_id, self)
    end

    @clients[client_id].parse(data)
  end
end

server = Server.new

trap('INT') do
  exit
end

trap('TERM') do
  exit
end

sleep
