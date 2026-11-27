package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"

	"kettik/internal/auth"
	"kettik/internal/booking"
	"kettik/internal/business"
	"kettik/migrations"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	secret := os.Getenv("AUTH_SECRET")
	if len(secret) < 32 {
		log.Fatal("AUTH_SECRET must be at least 32 characters")
	}
	db, err := pgxpool.New(ctx, env("DATABASE_URL", "postgres://kettik:kettik@localhost:5432/kettik"))
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()
	if err := migrate(db); err != nil {
		log.Fatalf("migrate: %v", err)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		if err := db.Ping(r.Context()); err != nil {
			http.Error(w, "db down", http.StatusServiceUnavailable)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	})
	a := auth.New(db, []byte(secret), codeSender())
	a.Routes(mux)
	booking.New(db, a).Routes(mux, os.Getenv("DEV") == "1")
	business.New(db, a).Routes(mux)

	srv := &http.Server{
		Addr:              env("ADDR", "127.0.0.1:8080"),
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      15 * time.Second,
	}
	go func() {
		<-ctx.Done()
		shutdown, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		_ = srv.Shutdown(shutdown)
	}()
	log.Printf("listening on %s", srv.Addr)
	if err := srv.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
		log.Fatal(err)
	}
}

func migrate(db *pgxpool.Pool) error {
	sqlDB := stdlib.OpenDBFromPool(db)
	defer sqlDB.Close()
	goose.SetBaseFS(migrations.FS)
	if err := goose.SetDialect("postgres"); err != nil {
		return err
	}
	return goose.Up(sqlDB, ".")
}

// logCode prints the code instead of mailing it, for local dev without SMTP.
func logCode(_ context.Context, email, code string) error {
	log.Printf("code for %s: %s", email, code)
	return nil
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
