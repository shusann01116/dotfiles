/*
Copyright © 2022 shusann01116 <26602565+shusann01116@users.noreply.github.com>
*/
package cmd

import (
	"os"

	"github.com/spf13/cobra"
)

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "dotfiles",
	Short: "A tool install dotfiles in elegant way.",
	Long: `This tool dedicates to installing packages and dotfiles.
Each dotfile is separated into packages and configurable to choose whether a package to install or not.
Also, this tool supports installing additional packages in plugin style.`,

	Run: func(cmd *cobra.Command, args []string) { },
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {
	rootCmd.PersistentFlags().BoolP("verbose", "v", false, "Show verbose message")
	rootCmd.PersistentFlags().BoolP("deubug", "d", false, "Debug mode")
	rootCmd.PersistentFlags().Bool("dry-run", false, "Dry-run")

	// rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.dotfiles.yaml)")

	// Cobra also supports local flags, which will only run
	// when this action is called directly.
	rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
