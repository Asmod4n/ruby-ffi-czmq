require_relative 'zsys'

module CZMQ
  class Zlogger
    def fatal(message)
      Zsys.error(message)
    end
    
    def error(message)
      Zsys.warning(message)
    end
    
    def warn(message)
      Zsys.notice(message)
    end
    
    def info(message)
      Zsys.info(message)
    end
    
    def debug(message)
      Zsys.debug(message)
    end
  end
end
