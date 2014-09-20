require 'bundler/setup'
require 'ffi-czmq'
require 'websocket/driver'

class Client
  extend Forwardable

  def_delegators :@driver, :parse

  def initialize(client_id, server)
    @client_id, @server = client_id, server
    @driver = WebSocket::Driver.server(self)

    @driver.on(:connect) do
      if WebSocket::Driver.websocket?(@driver.env)
        @driver.start
      else
        server.disconnect(client_id)
      end
    end

    @driver.on(:message) { |e| @driver.text(e.data) }
    @driver.on(:close)   { |e| server.disconnect(client_id) }
  end

  def write(data)
    @server.write(@client_id, data)
  end
end

class Server
  def initialize
    @parent_pipe = CZMQ::Zactor.new_actor(&method(:run))
  end

  def disconnect(client_id)
    @clients.delete(client_id)
    @server.tell(client_id, nil)
  end

  def write(client_id, data)
    @server.tell(client_id, data)
  end

  private

  def run(child_pipe)
    @reactor = CZMQ::Zloop.new
    @reactor.set_verbose(true)
    @reactor.add_reader(child_pipe, &method(:handle_pipe))

    @server = CZMQ::Zsock.new_stream('@tcp://*:7002')
    @server.set_maxmsgsize(1024 * 1024)

    @reactor.add_reader(@server, &method(:handle_server))

    @clients = {}

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
      client = @clients[client_id] = Client.new(client_id, self)
    else
      client = @clients[client_id]
    end

    client.parse(data)
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
