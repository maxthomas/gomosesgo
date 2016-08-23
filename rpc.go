package main

import "github.com/kolo/xmlrpc"

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
	result := RPCTranslateMessage{}
	send := RPCTranslateMessage{Text: in}
	err := client.Call("translate", send, &result)
	if err != nil {
		return "", err
	}
	return result.Text, nil
}

// Health calls the translate rpc server to see if it's alive. Returns
// true if ok, and false/error otherwise
func (client *RPCTranslate) Health() (bool, error) {
	send := RPCTranslateMessage{}
	err := client.Call("translate", send, nil)
	if err != nil {
		return false, err
	}
	return true, nil
}
