# Copyright 2015 gRPC authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Test stubs for various scenarios
require 'grpc'

# A test message
class EchoMsg
  def self.marshal(_o)
    ''
  end

  def self.unmarshal(_o)
    EchoMsg.new
  end
end

# A test service with an echo implementation.
class EchoService
  include GRPC::GenericService
  rpc :an_rpc, EchoMsg, EchoMsg
  attr_reader :received_md

  def initialize(**kw)
    @trailing_metadata = kw
    @received_md = []
  end

  def an_rpc(req, call)
    GRPC.logger.info('echo service received a request')
    call.output_metadata.update(@trailing_metadata)
    @received_md << call.metadata unless call.metadata.nil?
    req
  end
end

EchoStub = EchoService.rpc_stub_class

# For testing server interceptors
class TestServerInterceptor < GRPC::ServerInterceptor
  def call(_call, method, _desc, &_block)
    GRPC.logger.info "Received intercept at method #{method}"
    yield
  end
end
