package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	ga "google.golang.org/api/analyticsdata/v1beta"
	"google.golang.org/api/option"

	"github.com/gorilla/mux"
)

func main() {

	// Create a new HTTP Router using Gorilla's mux
	router := mux.NewRouter()
	router.HandleFunc("/GetGoogleAnalyticsData", getAnalyticsData).Methods("GET")

	// Start the server on port 6002
	http.ListenAndServe(":6002", router)
}

func getAnalyticsData(res http.ResponseWriter, req *http.Request) {
	// Set up the Google Analytics API client
	ctx := context.Background()
	client, err := ga.NewService(ctx, option.WithCredentialsFile("client.json"))

	if err != nil {
		res.WriteHeader(http.StatusInternalServerError)
		res.Write([]byte(err.Error()))
		return
	}

	runReportRequest := &ga.RunReportRequest{
		DateRanges: []*ga.DateRange{
			{
				StartDate: "28daysAgo",
				EndDate:   "today",
			},
		},
		Dimensions: []*ga.Dimension{
			{
				Name: "pagePath",
			},
		},
		DimensionFilter: &ga.FilterExpression{
			OrGroup: &ga.FilterExpressionList{
				Expressions: []*ga.FilterExpression{
					{
						Filter: &ga.Filter{
							FieldName: "pagePath",
							StringFilter: &ga.StringFilter{
								MatchType: "CONTAINS",
								Value:     "/blog/",
							},
						},
					},
					{
						Filter: &ga.Filter{
							FieldName: "pagePath",
							StringFilter: &ga.StringFilter{
								MatchType: "CONTAINS",
								Value:     "/episode/",
							},
						},
					},
				},
			},
		},
		Metrics: []*ga.Metric{
			{
				Name: "activeUsers",
			},
		},
		Limit: 10,
	}

	// Run the report outlined above.
	report, err := client.Properties.RunReport(fmt.Sprintf("%s/%s", "properties", os.Getenv("GA_PROPERTY")), runReportRequest).Do()
	if err != nil {
		res.WriteHeader(http.StatusInternalServerError)
		res.Write([]byte(err.Error()))
		return
	}

	// Take a value from the Google Analytics report rows, and add it to an array
	// of flattened strings.
	flattenedArray := []string{}
	for _, v := range report.Rows {
		flattenedArray = append(flattenedArray, v.DimensionValues[0].Value)
	}

	// Convert the array of flattened strings to JSON
	response, err := json.Marshal(flattenedArray)
	if err != nil {
		res.WriteHeader(http.StatusInternalServerError)
		res.Write([]byte(err.Error()))
		return
	}

	// Finally, return that JSON to the client
	res.Header().Set("Content-Type", "application/json")
	res.Write(response)
}
