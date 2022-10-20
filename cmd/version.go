package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

func init() {
	rootCmd.AddCommand(versionCmd)
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print the version of installer.",
	Long:  "Print the version of installer in semantic versions like `v0.1.0`",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Installer version: v0.1.0")
	},
}
