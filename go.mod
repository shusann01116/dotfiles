module github.com/shusann01116/dotfiles

go 1.19

require (
	github.com/shusann01116/dotfiles/dotfiles v0.0.0-00010101000000-000000000000
	github.com/spf13/cobra v1.6.0
)

require (
	github.com/inconshreveable/mousetrap v1.0.1 // indirect
	github.com/spf13/pflag v1.0.5 // indirect
)

replace github.com/shusann01116/dotfiles/dotfiles => ./pkg/dotfiles
