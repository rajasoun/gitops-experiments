package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/rajasoun/k8s/client"
)

var cmdCheck = &cobra.Command{
	Use:   "check k8s cluster",
	Short: "check k8s cluster state and health",
	Long:  `check kubernetes cluster state and health and print the result`,
	Args:  cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Print: " + args[0])
		k8s, err := client.NewK8s()
		if err != nil {
			panic(err.Error())
		}
		version, _ := k8s.GetVersion()
		fmt.Printf("Version of running Kubernetes: %s\n", version)
		health, _ := k8s.GetHealthStatus()
		fmt.Printf("Cluster Health: %s\n", health)
	},
}
