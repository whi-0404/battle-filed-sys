package service

import (
	"net/http"
	"time"

	"github.com/nats-io/nats.go"
)

type OpenSkyClient struct {
	client   *http.Client
	username string
	password string
	nc       *nats.Conn
}

func NewOpenSkyClient(username, password string, nc *nats.Conn) *OpenSkyClient {
	return &OpenSkyClient{
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
		username: username,
		password: password,
		nc:       nc,
	}
}
