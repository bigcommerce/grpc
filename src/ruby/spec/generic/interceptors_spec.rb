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
require 'spec_helper'

describe 'Interceptors' do
  describe 'interception' do
    let(:interceptor) { TestServerInterceptor.new }
    let(:request) { EchoMsg.new }
    let(:service) { EchoService }

    before(:each) do
      build_rpc_server
    end

    context 'when an interceptor is added' do
      before(:each) do
        @server.interceptors[:test] = interceptor
      end

      it 'should be called', server: true do
        expect(interceptor).to receive(:call).once.and_call_original

        run_services_on_server(@server, services: [service]) do
          stub = EchoStub.new(@host, :this_channel_is_insecure, **@client_opts)
          expect(stub.an_rpc(request)).to be_a(EchoMsg)
        end
      end
    end

    context 'when multiple interceptors are added' do
      let(:interceptor2) { TestServerInterceptor.new }
      let(:interceptor3) { TestServerInterceptor.new }

      before(:each) do
        @server.interceptors[:test] = interceptor
        @server.interceptors[:test2] = interceptor2
        @server.interceptors[:test3] = interceptor3
      end

      it 'each should be called', server: true do
        expect(interceptor).to receive(:call).once.and_call_original
        expect(interceptor2).to receive(:call).once.and_call_original
        expect(interceptor3).to receive(:call).once.and_call_original

        run_services_on_server(@server, services: [service]) do
          stub = EchoStub.new(@host, :this_channel_is_insecure, **@client_opts)
          expect(stub.an_rpc(request)).to be_a(EchoMsg)
        end
      end
    end

    context 'when an interceptor is not added' do
      it 'should not be called', server: true do
        expect(interceptor).to_not receive(:call)

        run_services_on_server(@server, services: [service]) do
          stub = EchoStub.new(@host, :this_channel_is_insecure, **@client_opts)
          expect(stub.an_rpc(request)).to be_a(EchoMsg)
        end
      end
    end
  end

  describe GRPC::InterceptorRegistry do
    let(:server) { RpcServer.new }
    let(:interceptor) { TestServerInterceptor.new }
    let(:registry) { described_class.new }
    let(:key) { :test }

    describe '.[]=' do
      subject { registry[key] = interceptor }

      context 'with an interceptor extending GRPC::ServerInterceptor' do
        it 'should add the interceptor to the registry' do
          subject
          is = registry.to_h
          expect(is.count).to eq 1
          expect(is.keys.first).to eq key
          expect(is.values.first).to eq interceptor
        end
      end

      context 'with an interceptor not extending GRPC::ServerInterceptor' do
        let(:interceptor) { Class }
        let(:err) { GRPC::InterceptorRegistry::DescendantError }

        it 'should raise an InvalidArgument exception' do
          expect { subject }.to raise_error(err)
        end
      end
    end

    describe '.[]' do
      subject { registry[key] }

      context 'when the interceptor exists with the given key' do
        before do
          registry[key] = interceptor
        end

        it 'should return the interceptor' do
          expect(subject).to eq interceptor
        end
      end

      context 'when the interceptor does not exist with the given key' do
        it 'should return nil' do
          expect(subject).to be_nil
        end
      end
    end

    describe '.each' do
      context 'with an interceptor added' do
        before do
          registry[key] = interceptor
        end

        it 'should yield with the name/value pair' do
          expect { |b| registry.each(&b) }.to yield_with_args(key, interceptor)
        end
      end

      context 'with no interceptors added' do
        it 'should not yield' do
          expect { |b| registry.each(&b) }.to_not yield_control
        end
      end
    end

    describe '.count' do
      subject { registry.count }

      context 'with n interceptors added' do
        it 'should equal n' do
          tot = rand(1..10)
          tot.times do |n|
            registry["test#{n}".to_sym] = interceptor
          end
          expect(subject).to eq tot
        end
      end

      context 'with no interceptors added' do
        it 'should return zero' do
          expect(subject).to eq 0
        end
      end
    end

    describe '.any?' do
      subject { registry.any? }

      context 'with n interceptors added' do
        it 'should return true' do
          tot = rand(1..10)
          tot.times do |n|
            registry["test#{n}".to_sym] = interceptor
          end
          expect(subject).to eq true
        end
      end

      context 'with no interceptors added' do
        it 'should return false' do
          expect(subject).to be_falsey
        end
      end
    end

    describe '.clear' do
      subject { registry.clear }

      it 'should clear the interceptor registry' do
        registry[:one] = interceptor
        registry[:two] = interceptor
        expect(registry.count).to eq 2
        subject
        expect(registry.count).to eq 0
      end
    end

    describe '.all' do
      subject { registry.all }

      it 'should return all the interceptors without their keys' do
        one = TestServerInterceptor.new
        two = TestServerInterceptor.new
        registry[:one] = one
        registry[:two] = two

        expect(subject).to eq [one, two]
      end
    end

    describe '.to_h' do
      subject { registry.to_h }

      it 'should return the registry as a hash' do
        one = TestServerInterceptor.new
        two = TestServerInterceptor.new
        registry[:one] = one
        registry[:two] = two

        expected = { one: one, two: two }
        expect(subject).to eq expected
      end
    end
  end
end
