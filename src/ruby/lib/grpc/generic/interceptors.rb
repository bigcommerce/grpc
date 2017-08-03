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

# GRPC contains the General RPC module.
module GRPC
  ##
  # Base class for interception in GRPC
  #
  class Interceptor
    ##
    # @param [Hash] options A hash of options that will be used
    #   by the interceptor
    #
    def initialize(options = {})
      @options = options || {}
    end
  end

  ##
  # ServerInterceptor allows for wrapping gRPC server execution handling
  #
  class ServerInterceptor < Interceptor
    ##
    # @param [GRPC::ActiveCall] _call
    # @param [Symbol] _method
    # @param [GRPC::RpcDesc] _desc
    # @abstract
    #
    def call(_call, _method, _desc, &_block)
      fail NotImplementedError, 'Extend call in inherited class'
    end
  end
end
