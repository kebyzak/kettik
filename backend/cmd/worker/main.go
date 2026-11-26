// worker saves what time does to rooms: expired holds, missed deadlines with
// their refunds, and replacements that ran out. Reads settle rooms in memory
// too, so the worker only has to keep the stored state and the calendar right.
package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"kettik/internal/booking"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	url := os.Getenv("DATABASE_URL")
	if url == "" {
		url = "postgres://kettik:kettik@localhost:5432/kettik"
	}
	db, err := pgxpool.New(ctx, url)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	tick := time.NewTicker(5 * time.Second)
	defer tick.Stop()
	for {
		ids, err := booking.Due(ctx, db)
		if err != nil && ctx.Err() == nil {
			log.Printf("due: %v", err)
		}
		for _, id := range ids {
			if err := booking.Settle(ctx, db, id); err != nil {
				log.Printf("settle %s: %v", id, err)
			}
		}
		select {
		case <-ctx.Done():
			return
		case <-tick.C:
		}
	}
}
