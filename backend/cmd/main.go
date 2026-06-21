package main

import (
	"battlefiled-sys/config"
	"battlefiled-sys/db"
	grpcserver "battlefiled-sys/internal/grpcserver"
	inats "battlefiled-sys/internal/nats"
	"battlefiled-sys/internal/tracking/repository"
	"battlefiled-sys/internal/tracking/service"
	bfpb "battlefiled-sys/proto"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"

	natsgo "github.com/nats-io/nats.go"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

func main() {
	// ─── Config & Database ───────────────────────────────────────
	cfg := config.Load()
	dbConn, err := db.Connect(cfg.DSN())
	if err != nil {
		log.Fatalf("[main] Database connection failed: %v", err)
	}
	defer dbConn.Close()
	log.Println("[main] Database connected")

	// ─── NATS Connection ─────────────────────────────────────────
	natsURL := getEnv("NATS_URL", natsgo.DefaultURL)
	nc, err := natsgo.Connect(natsURL)
	if err != nil {
		log.Fatalf("[main] NATS connection failed: %v", err)
	}
	defer nc.Close()
	log.Printf("[main] Connected to NATS at %s", natsURL)

	// ─── DI: Repository → Service ────────────────────────────────
	trackingRepo := repository.NewPostgresRepository(dbConn)
	trackingService := service.NewTrackingService(trackingRepo)

	// ─── gRPC Radar Server ───────────────────────────────────────
	radarServer := grpcserver.NewRadarServer()

	// ─── NATS Subscriptions ──────────────────────────────────────
	civilHandler := inats.NewTrackingHandler(trackingService, radarServer)
	if err := inats.SubscribeTracking(nc, civilHandler); err != nil {
		log.Fatalf("[main] Civil NATS subscription failed: %v", err)
	}

	militaryHandler := inats.NewMilitaryHandler(trackingService, radarServer)
	if err := inats.SubscribeMilitary(nc, militaryHandler); err != nil {
		log.Fatalf("[main] Military NATS subscription failed: %v", err)
	}

	// ─── gRPC Server ─────────────────────────────────────────────
	grpcPort := getEnv("GRPC_PORT", "50051")
	lis, err := net.Listen("tcp", ":"+grpcPort)
	if err != nil {
		log.Fatalf("[main] Failed to listen on :%s: %v", grpcPort, err)
	}

	grpcSrv := grpc.NewServer()
	bfpb.RegisterRadarServiceServer(grpcSrv, radarServer)

	// Bật gRPC reflection để test bằng grpcurl / Postman
	reflection.Register(grpcSrv)

	go func() {
		log.Printf("[main] gRPC server listening on :%s", grpcPort)
		log.Printf("[main] Service: battlefield.RadarService/StreamRadar")
		if err := grpcSrv.Serve(lis); err != nil {
			log.Fatalf("[main] gRPC server error: %v", err)
		}
	}()

	// ─── Graceful Shutdown ───────────────────────────────────────
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("[main] Shutdown signal received")
	grpcSrv.GracefulStop()
	log.Println("[main] Backend stopped")
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
