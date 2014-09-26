require 'thread_safe'

module CZMQ
  module Registry
    class << self
      def init
        return @registry if @registry
        @registry = ::ThreadSafe::Cache.new
      end

      def []=(object_id, pointer)
        @registry[object_id] = pointer
      end

      def delete(object_id)
        @registry.delete(object_id)
      end
    end

    init
  end
end
