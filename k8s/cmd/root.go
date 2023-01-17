package cmd

import "github.com/spf13/cobra"

var rootCmd = &cobra.Command{Use: "app"}

// init adds all child commands to the root command and sets flags appropriately.
func init() {
	rootCmd.AddCommand(cmdPrint)
}

// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() error {
	err := rootCmd.Execute()
	if err != nil {
		return err
	}
	return nil
}
