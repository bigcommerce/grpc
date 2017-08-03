module GRPC
  module Spec
    module Helpers
      ##
      # Build an RPC server used for testing
      #
      def build_rpc_server(server_opts: {}, client_opts: {}, channel: nil)
        @server = RpcServer.new({poll_period: 1}.merge(server_opts))
        @port = @server.add_http2_port('0.0.0.0:0', :this_port_is_insecure)
        @host = "0.0.0.0:#{@port}"
        @channel = channel || GRPC::Core::Channel.new(@host, nil, :this_channel_is_insecure)
        @client_opts = client_opts.merge(channel_override: @channel)
        @server
      end

      ##
      # Run services on an RPC server, yielding to allow testing within
      #
      # @param [RpcServer] server
      # @param [Array<Class>] services
      #
      def run_services_on_server(server, services: [])
        services.each do |s|
          server.handle(s)
        end
        t = Thread.new { server.run }
        server.wait_till_running

        yield

        server.stop
        t.join
      end
    end
  end
end
