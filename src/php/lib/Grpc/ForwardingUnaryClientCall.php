<?php

namespace Grpc;

abstract class ForwardingUnaryClientCall extends ForwardingClientCall {
	public function start($data, array $metadata = [], array $options = [])
	{ 
		return $this->delegate->start($data, $metadata, $options); 
	}

	public function wait() 
	{ 
		return $this->delegate->wait(); 
	}
}
