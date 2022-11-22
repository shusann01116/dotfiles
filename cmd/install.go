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
}

// InstallPackage installs a package specified by the name argument
func InstallPackage(name string) error {
	fmt.Println(name)
	return nil
}
