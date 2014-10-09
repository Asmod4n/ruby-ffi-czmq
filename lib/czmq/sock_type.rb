require 'delegate'

module CZMQ
  class Zsock
    class SockType < ::Delegator
      # adopted from https://github.com/tarcieri/http/blob/master/lib/http/response/status.rb
      TYPE = {
        0   => 'PAIR',
        1   => 'PUB',
        2   => 'SUB',
        3   => 'REQ',
        4   => 'REP',
        5   => 'DEALER',
        6   => 'ROUTER',
        7   => 'PULL',
        8   => 'PUSH',
        9   => 'XPUB',
        10  => 'XSUB',
        11  => 'STREAM'
      }.each { |_, v| v.freeze }.freeze

      class << self
        # Coerces given value to SockType.
        #
        # @example
        #
        #   SockType.coerce("pair")       # => SockType.new(0)
        #   SockType.coerce(:pair)        # => SockType.new(0)
        #   SockType.coerce(0.0)          # => SockType.new(0)
        #   SockType.coerce(true)         # => raises ArgumentError
        #
        # @raise [ArgumentError] if coercion is impossible
        # @param [String, Symbol, Numeric] object
        # @return [SockType]
        def coerce(object)
          code = case object
                 when String  then SYMBOL_CODES[symbolize object]
                 when Symbol  then SYMBOL_CODES[object]
                 when Numeric then object.to_i
                 else nil
                 end

          return new code if code

          fail ArgumentError, "Can't coerce #{object.class}(#{object}) to #{self}", caller
        end
        alias_method :[], :coerce

      private

        # Symbolizes given string
        #
        # @example
        #
        #   symbolize "PAIR" # => :pair
        #
        # @param [#to_s] str
        # @return [Symbol]
        def symbolize(str)
          str.to_s.downcase.to_sym
        end
      end

      # Code to Symbol map
      #
      # @example Usage
      #
      #   SYMBOLS[0] # => :pair
      #   SYMBOLS[1] # => :pub
      #
      # @return [Hash<Fixnum => Symbol>]
      SYMBOLS = Hash[TYPE.map { |k, v| [k, symbolize(v)] }].freeze

      # Reversed {SYMBOLS} map.
      #
      # @example Usage
      #
      #   SYMBOL_CODES[:pair]     # => 0
      #   SYMBOL_CODES[:pub]      # => 1
      #
      # @return [Hash<Symbol => Fixnum>]
      SYMBOL_CODES = Hash[SYMBOLS.map { |k, v| [v, k] }].freeze

      # SockType code
      #
      # @return [Fixnum]
      attr_reader :code

      # SockType message
      #
      # @return [nil] unless code is well-known (see TYPE)
      # @return [String]
      def type
        TYPE[code]
      end

      # Symbolized {#type}
      #
      # @return [nil] unless code is well-known (see TYPE)
      # @return [Symbol]
      def symbolize
        SYMBOLS[code]
      end

      # Printable version of HTTP Status, surrounded by quote marks,
      # with special characters escaped.
      #
      # (see String#inspect)
      def inspect
        "#{code} #{type}".inspect
      end

      SYMBOLS.each do |code, symbol|
        class_eval <<-RUBY, __FILE__, __LINE__
          def #{symbol}?      # def pair?
            #{code} == code   # 0 == code
          end                 # end
        RUBY
      end

      def __setobj__(obj)
        @code = obj.to_i
      end

      def __getobj__
        @code
      end
    end
  end
end
