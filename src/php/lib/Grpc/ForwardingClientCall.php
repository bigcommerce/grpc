<?php

namespace Grpc;

abstract class ForwardingClientCall {
    // @var AbstractCall
    protected $delegate;

    public function __construct($delegate) {
        $this->delegate = $delegate;
    }

    /**
     * @return mixed The metadata sent by the server
     */
    public function getMetadata()
    {
        return $this->delegate->getMetadata();
    }

    /**
     * @return mixed The trailing metadata sent by the server
     */
    public function getTrailingMetadata()
    {
        return $this->delegate->getTrailingMetadata();
    }

    /**
     * @return string The URI of the endpoint
     */
    public function getPeer()
    {
        return $this->delegate->getPeer();
    }

    /**
     * Cancels the call.
     */
    public function cancel()
    {
        return $this->delegate->cancel();
    }

    /**
     * Set the CallCredentials for the underlying Call.
     *
     * @param CallCredentials $call_credentials The CallCredentials object
     */
    public function setCallCredentials($call_credentials)
    {
        $this->delegate->setCallCredentials($call_credentials);
    }
}
