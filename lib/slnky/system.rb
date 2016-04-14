require 'socket'

module Slnky
  class System
    class << self
      def pid
        service = Slnky.config.service || 'unknown'
        "#{ipaddress}/#{service}-#{$$}"
      end

      def hostname
        @hostname ||= Socket.gethostname
      end

      def ipaddress
        @ipaddress ||= Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
      end
    end
  end
end
