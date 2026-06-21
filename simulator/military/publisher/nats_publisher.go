package publisher

import (
	"log"
	bfpb "simulator/proto"

	"github.com/nats-io/nats.go"
	"google.golang.org/protobuf/proto"
)

const SubjectMilitaryPosition = "military.position.updated"

// NatsPublisher publish military events lên NATS dưới dạng protobuf bytes
type NatsPublisher struct {
	nc *nats.Conn
}

func NewNatsPublisher(nc *nats.Conn) *NatsPublisher {
	return &NatsPublisher{nc: nc}
}

// Publish marshal MilitaryEvent thành protobuf và gửi lên NATS
func (p *NatsPublisher) Publish(event *bfpb.MilitaryEvent) {
	data, err := proto.Marshal(event)
	if err != nil {
		log.Printf("[publisher] proto marshal error: %v", err)
		return
	}

	if err := p.nc.Publish(SubjectMilitaryPosition, data); err != nil {
		log.Printf("[publisher] publish error for %s/%s: %v", event.GetType(), event.GetId(), err)
	}
}
