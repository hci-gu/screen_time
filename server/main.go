package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
)

type ScreenTimeEntry struct {
	Hour    string `json:"hour"`
	Seconds int    `json:"seconds"`
}

var data struct {
	ScreenTimeEntries []ScreenTimeEntry `json:"screenTimeEntries"`
}

func createJobRecord(app *pocketbase.PocketBase, userId string) error {
	print("Creating job record for user: ", userId)
	collection, err := app.FindCollectionByNameOrId("backgroundjobs")
	if err != nil {
		print("Error finding collection: ", err)
		return err
	}
	record := core.NewRecord(collection)
	record.Set("user", userId)
	app.Save(record)
	return nil
}

func main() {
	app := pocketbase.New()

	app.OnServe().BindFunc(func(se *core.ServeEvent) error {

		se.Router.POST("/users/{id}/upload", func(e *core.RequestEvent) error {
			id := e.Request.PathValue("id")
			log.Println("Received upload request", id)

			// Bind parsed JSON to struct
			if err := e.BindBody(&data); err != nil {
				return e.BadRequestError("Failed to parse JSON", err)
			}

			createJobRecord(app, id)

			log.Printf("Parsed %d screenTimeEntries", len(data.ScreenTimeEntries))
			collection, err := app.FindCollectionByNameOrId("screentime")
			if err != nil {
				return err
			}

			for _, entry := range data.ScreenTimeEntries {
				// Build a filter to check if a record exists with the same user and hour
				filter := fmt.Sprintf("user = '%s' && hour = '%s'", id, entry.Hour)
				existingRecords, err := app.FindRecordsByFilter("screentime", filter, "", 5, 0)
				if err != nil {
					log.Printf("Error querying existing records: %v", err)
					continue // skip this entry on error
				}

				if len(existingRecords) > 0 {
					// There is an existing record, check if we should update
					existing := existingRecords[0]
					existingSeconds := existing.GetInt("seconds")

					if entry.Seconds > existingSeconds {
						existing.Set("seconds", entry.Seconds)
						err := app.Save(existing)
						if err != nil {
							log.Printf("Error updating record: %v", err)
						} else {
							log.Printf("Updated record: %s with %d seconds", entry.Hour, entry.Seconds)
						}
					} else {
						log.Printf("Skipping record for %s: existing seconds %d >= new seconds %d", entry.Hour, existingSeconds, entry.Seconds)
					}
				} else {
					// No existing record, create a new one
					record := core.NewRecord(collection)
					record.Set("user", id)
					record.Set("hour", entry.Hour)
					record.Set("seconds", entry.Seconds)

					err := app.Save(record)
					if err != nil {
						log.Printf("Error saving new record: %v", err)
					} else {
						log.Printf("Saved new record: %s with %d seconds", entry.Hour, entry.Seconds)
					}
				}
			}

			return e.JSON(http.StatusOK, map[string]bool{"success": true})
		})

		se.Router.GET("/users/{id}", func(e *core.RequestEvent) error {
			id := e.Request.PathValue("id")
			log.Printf("Received request for user %s", id)

			user, err := app.FindRecordById("users", id)

			if err != nil {
				log.Printf("Error finding user: %v", err)
				return e.NotFoundError("User not found", err)
			}

			log.Printf("Found user: %s", user.GetString("username"))

			return e.JSON(http.StatusOK, data)
		})

		// serves static files from the provided public dir (if exists)
		se.Router.GET("/{path...}", apis.Static(os.DirFS("./pb_public"), false))

		return se.Next()
	})

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}
