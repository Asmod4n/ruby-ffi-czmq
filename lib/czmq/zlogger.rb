require_relative 'zsys'

module CZMQ
  class Zlogger
    STR = '%s'.freeze

    def fatal(message)
      Zsys.error(STR, :string, message)
    end

    def error(message)
      Zsys.warning(STR, :string, message)
    end

    def warn(message)
      Zsys.notice(STR, :string, message)
    end

    def info(message)
      Zsys.info(STR, :string, message)
    end

    def debug(message)
      Zsys.debug(STR, :string, message)
    end
  end
end
