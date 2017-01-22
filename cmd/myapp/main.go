/*
Copyright 2016 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"fmt"
	"github.com/rfay/go-build-template/pkg/version"
	"github.com/spf13/cobra"
	"github.com/spf13/hugo/utils"
)

var versionCommand = &cobra.Command{
	Use:   "version",
	Short: "Print the version number",
	Long:  `Print the version number.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println(version.VERSION)
	},
}

var myapp = &cobra.Command{
	Use:   "myapp",
	Short: "myapp",
	Long:  `Simple test command`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println(HelloWorldOutput())
	},
}

func main() {
	myapp.AddCommand(versionCommand)
	utils.StopOnErr(myapp.Execute())
}

func HelloWorldOutput() string {
	return "hello, world!"
}
