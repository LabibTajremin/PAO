//go:build integration

package jobs_test

import (
	"context"
	"testing"
	"time"

	"github.com/riverqueue/river"

	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/jobs"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

type pingArgs struct{ N int }

func (pingArgs) Kind() string { return "test.ping" }

type pingWorker struct {
	river.WorkerDefaults[pingArgs]
	done chan int
}

func (w *pingWorker) Work(_ context.Context, j *river.Job[pingArgs]) error {
	w.done <- j.Args.N
	return nil
}

func TestJobs_EnqueueAndRun(t *testing.T) {
	ctx := context.Background()
	pool, err := db.Connect(ctx, testkit.MigratedDatabase(t))
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	if err := jobs.Migrate(ctx, pool); err != nil {
		t.Fatal(err)
	}
	reg := jobs.NewRegistry()
	w := &pingWorker{done: make(chan int, 1)}
	jobs.Register(reg, w)
	reg.Every(time.Hour, pingArgs{N: 0})
	reg.Daily(2, 0, pingArgs{N: 0})
	worker, err := jobs.NewClient(pool, reg, 2, logx.Discard())
	if err != nil {
		t.Fatal(err)
	}
	if err := worker.Start(ctx); err != nil {
		t.Fatal(err)
	}
	defer func() { _ = worker.Stop(ctx) }()
	inserter, err := jobs.NewClient(pool, nil, 0, logx.Discard())
	if err != nil {
		t.Fatal(err)
	}
	if _, err := inserter.Insert(ctx, pingArgs{N: 42}, nil); err != nil {
		t.Fatal(err)
	}
	deadline := time.After(10 * time.Second)
	for {
		select {
		case n := <-w.done:
			if n == 42 {
				return
			}
		case <-deadline:
			t.Fatal("job did not run within 10 s")
		}
	}
}

func TestJobs_Errors(t *testing.T) {
	ctx := context.Background()
	pool, err := db.Connect(ctx, testkit.EmptyDatabase(t))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := jobs.NewClient(pool, jobs.NewRegistry(), 0, logx.Discard()); err == nil {
		t.Fatal("zero workers accepted")
	}
	pool.Close()
	if err := jobs.Migrate(ctx, pool); err == nil {
		t.Fatal("migrate on a closed pool succeeded")
	}
}
