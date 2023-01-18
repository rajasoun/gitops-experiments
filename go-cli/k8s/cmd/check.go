package cmd

import (
	"context"
	"fmt"

	"github.com/spf13/cobra"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"github.com/rajasoun/k8s/client"
)

var cmdCheck = &cobra.Command{
	Use:   "check k8s cluster",
	Short: "check k8s cluster state and health",
	Long:  `check kubernetes cluster state and health and print the result`,
	Args:  cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Print: " + args[0])
		clientset, err := client.New()
		if err != nil {
			panic(err.Error())
		}

		// get pods in all the namespaces by omitting namespace
		// Or specify namespace to get pods in particular namespace
		pods, err := clientset.CoreV1().Pods("").List(context.TODO(), metav1.ListOptions{})
		if err != nil {
			panic(err.Error())
		}
		fmt.Printf("There are %d pods in the cluster\n", len(pods.Items))
		for _, pod := range pods.Items {
			fmt.Printf("pod name %s namespace %s status %s \n", pod.Name, pod.Namespace, pod.Status.Phase)
		}
	},
}
