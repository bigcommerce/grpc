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

require_relative 'interceptors'

# GRPC contains the General RPC module.
module GRPC
  ##
  # Represents a registry of added interceptors available for enumeration.
  # The registry can be used for both server and client interceptors.
  #
  class InterceptorRegistry
    ##
    # An error raised when an interceptor is attempted to be added
    # that does not extend GRPC::Interceptor
    #
    class DescendantError < StandardError; end

    ##
    # Initialize the registry with an empty interceptor list
    #
    def initialize
      @interceptors = {}
    end

    ##
    # @param [Symbol] name The key to identify the interceptor in the
    #   registry as
    # @param [GRPC::Interceptor] interceptor The interceptor instance
    #
    def []=(name, interceptor)
      base = GRPC::Interceptor
      unless interceptor.class.ancestors.include?(base)
        fail DescendantError, "Interceptors must descend from #{base}"
      end

      @interceptors[name.to_sym] = interceptor
    end

    ##
    # Return an interceptor from the registry via a hash accessor syntax
    #
    # @return [GRPC::ServerInterceptor|NilClass] The requested interceptor
    #   if it exists in the registry
    #
    def [](name)
      @interceptors[name.to_sym]
    end

    ##
    # Iterate over each interceptor in the registry
    #
    def each
      @interceptors.each do |name, i|
        yield name, i
      end
    end

    ##
    # @return [Integer] The number of interceptors currently in the registry
    #
    def count
      @interceptors.keys.count
    end

    ##
    # @return [Boolean] True if there are any interceptors
    #
    def any?
      count > 0
    end

    ##
    # Clear the registry
    #
    def clear
      @interceptors = {}
    end

    ##
    # @return [Array<GRPC::Interceptor>]
    #
    def all
      @interceptors.values
    end

    ##
    # @return [Hash]
    #
    def to_h
      @interceptors.dup
    end
    alias_method :to_hash, :to_h
  end
end
