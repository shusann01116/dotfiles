/*
Copyright © 2022 shusann01116 26602565+shusann01116@users.noreply.github.com
*/

package cmd

import (
	"fmt"
	"strings"

	"github.com/spf13/cobra"
)

// installCmd represents the install command
var (
	installCmd = &cobra.Command{
		Use:   "install",
		Short: "Installs packages creating symlink to specific locations from `package` directory.",
		Long:  `You can pass a multiple arguments to install multiple packages. This command search packages in packages to install.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			for _, pkg := range args {
				pkg = strings.TrimSpace(pkg)
				err := InstallPackage(pkg)
				if err != nil {
					return err
				}
			}
			return nil
		},
	}
)

func init() {
	rootCmd.AddCommand(installCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// installCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// installCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// InstallPackage installs a package specified by the name argument
func InstallPackage(name string) error {
	fmt.Println(name)
	return nil
}
