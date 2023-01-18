package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/rajasoun/k8s/client"
	"github.com/rajasoun/k8s/logger"
)

var log = logger.New()

var cmdCheck = &cobra.Command{
	Use:   "check k8s cluster",
	Short: "check k8s cluster state and health",
	Long:  `check kubernetes cluster state and health and print the result`,
	Args:  cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		//fmt.Println("Print: " + args[0])
		k8s, err := client.NewK8s()
		if err != nil {
			// replace with log.Fatal
			log.Fatalf("Error while creating k8s client: %s", err.Error())
		}
		version, _ := k8s.GetVersion()
		fmt.Printf("K8s Cluster Version : %s\n", version)
		health, _ := k8s.GetHealthStatus()
		fmt.Printf("K8s Cluster Health : %s\n", health)
	},
}
