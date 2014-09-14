require 'bundler/setup'
ENV['ZSYS_LOGSENDER'] = 'inproc://logging'
require 'ffi-czmq'

class LogActor
  extend Forwardable

  def_delegators :@parent_pipe, :<<, :tell, :recv, :wait, :destructor

  def initialize
    @parent_pipe = CZMQ::Zactor.new_actor(&method(:run))
  end

  private

  def run(child_pipe)
    @logger = CZMQ::Zsock.new_sub('inproc://logging', '')

    @reactor = CZMQ::Zloop.new
    @reactor.add_reader(child_pipe, &method(:handle_pipe))
    @reactor.add_reader(@logger, &method(:handle_logger))

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

  def handle_logger(zsock)
    puts "logger recv: #{zsock.recv.first.to_str}"
    0
  end
end

logger = LogActor.new

CZMQ::Zsys.info('hallo')

logger.destructor
