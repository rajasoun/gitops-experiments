package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var cmdCheck = &cobra.Command{
	Use:   "check k8s cluster",
	Short: "check k8s cluster state and health",
	Long:  `check kubernetes cluster state and health and print the result`,
	Args:  cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Print: " + args[0])
	},
}
