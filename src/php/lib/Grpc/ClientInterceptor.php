<?php 
/*
 *
 * Copyright 2015 gRPC authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

namespace Grpc;

abstract class ClientInterceptor { 
	public function interceptUnaryCall($method, $argument, $metadata, $options, UnaryCall $next) {
	    return $next;
    }

//	public function interceptClientStreamingCall($method, \Grpc\ClientStreamingCall $next) {
//    }
//	public function interceptServerStreamingCall($method, \Grpc\ServerStreamingCall $next);
//	public function interceptBidiStreamingCall($method, \Grpc\BidiStreamingCall $next);
}


class LoggingClientCall extends ForwardingUnaryClientCall {
    private $method;
    private $body;

    public function __construct($delegate, $method, $body) {
        $this->method = $method;
        $this->body = $body;
        parent::__construct($delegate);
    }

    public function start($data, array $metadata = [], array $options = [])
    {
        echo "Sending request ".$this->method." with body".$this->body;
        return parent::start($data, $metadata, $options);
    }

    public function wait()
    {
        $resp = parent::wait();
        echo "Received response ".$resp." for request ".$this->method;
        return $resp;
    }
}

class LoggingClientInterceptor extends ClientInterceptor {
    public function interceptUnaryCall($method, $argument, $metadata, $options, UnaryCall $next)
    {
        return new LoggingClientCall($next, $method, $argument);
    }
}
