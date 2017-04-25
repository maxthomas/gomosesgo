package main

import (
	"sync"

	"go.uber.org/zap"

	"github.com/kolo/xmlrpc"
)

func createPool(endpoint string) sync.Pool {
	return sync.Pool{New: func() interface{} {
		cli, err := xmlrpc.NewClient(endpoint, nil)
		if err != nil {
			panic("Failed to connect to URI while creating client")
		}

		return &RPCTranslate{Client: cli}
	}}
}

// RPCPool is a goroutine-safe wrapper around
// RPCTranslate objects. These are not thread safe
// because the underlying xmlrpc lib uses some non-thread
// safe behaviors.
type RPCPool struct {
	Endpoint string
	pool     sync.Pool
}

// NewRPCPool creates a new RPCPool object and sets up a pool for it
// given an endpoint
func NewRPCPool(endpoint string) *RPCPool {
	client, clientErr := xmlrpc.NewClient(endpoint, nil)
	if clientErr != nil {
		panic("couldn't connect to RPC endpoint")
	}
	client.Close()

	return &RPCPool{Endpoint: endpoint, pool: createPool(endpoint)}
}

// Translate is a thread-safe wrapper around Translate
// from the RPCTranslate object
func (p *RPCPool) Translate(text string) (string, error) {
	cli := p.pool.Get().(*RPCTranslate)
	defer p.pool.Put(cli)

	return cli.Translate(text)
}

// Health is a thread-safe wrapper around Health from
// the RPCTranslate endpoint
func (p *RPCPool) Health() (bool, error) {
	cli := p.pool.Get().(*RPCTranslate)
	defer p.pool.Put(cli)

	return cli.Health()
}

// RPCTranslate wraps the XMLRPC client
type RPCTranslate struct {
	*xmlrpc.Client
}

// RPCTranslateMessage wraps
type RPCTranslateMessage struct {
	Text string `xmlrpc:"text"`
}

// Translate calls the translate rpc server
func (client *RPCTranslate) Translate(in string) (string, error) {
	result := &RPCTranslateMessage{}
	send := RPCTranslateMessage{Text: in}

	translateCall := client.Go("translate", send, result, nil)
	resultCall := <-translateCall.Done
	if resultCall.Error != nil {
		log.Error("Error from RPC call", zap.Error(resultCall.Error))
		return "", resultCall.Error
	}

	return result.Text, nil
}

// Health calls the translate rpc server to see if it's alive. Returns
// true if ok, and false/error otherwise
func (client *RPCTranslate) Health() (bool, error) {
	send := RPCTranslateMessage{}
	res := new(RPCTranslateMessage)
	healthCall := client.Go("translate", send, res, nil)
	finishedCall := <-healthCall.Done
	if finishedCall.Error != nil {
		return false, finishedCall.Error
	}

	return true, nil
}
