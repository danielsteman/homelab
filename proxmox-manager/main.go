package main

import (
	"fmt"
	"log"
	"os"
)

func main() {
	fmt.Println("Proxmox Manager")

	if len(os.Args) < 2 {
		fmt.Println("Usage: proxmox-manager <command>")
		fmt.Println("Commands:")
		fmt.Println("  version  - Show version information")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "version":
		fmt.Println("Version: 0.1.0")
	default:
		log.Printf("Unknown command: %s", os.Args[1])
		os.Exit(1)
	}
}
