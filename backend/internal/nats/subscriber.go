package nats

import (
	"log"

	natsgo "github.com/nats-io/nats.go"
)

func SubscribeTracking(natsgo *natsgo.Conn, hanlder *TrackingHandler) error {
	_, err := natsgo.Subscribe("flight.position.updated", hanlder.HandlePositionUpdate)
	if err != nil {
		log.Printf("Error subscribing to NATS subject: %v", err)
		return err
	}

	return nil
}
