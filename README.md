# make

A base project using make to quickly configure the following capabilities in an Azarc project.

- make lint
  - Run golangci linters
- make test
  - Run unit tests without coverage
- make cover
  - Run unit tests with coverage
- make build
  - If available runs go releaser
- make bufgenerate
  - Generate protobuf files using buf
- make buflint
  - Lint protobuf files using buf
- make bufbreaking
  - Check for breaking changes using buf
- make build
  - Runs build using go releaser
  - You can copy the example `.goreleaser.yaml` file and modify to suit your needs
- make release
  - Runs release using go releaser
  - You can copy the example `.goreleaser.yaml` file and modify to suit your needs

- make copyfrommakego
  - Copy changes from this project to your project
- make copytomakego
  - Copy local changes back to this repo from your project

# installation

Copy the make directory from this project into your own project, do not rename the folder.

If you require the `make build` and `make release` features then you can copy the `.goreleaser.yaml` 
and modify it to suit your needs.

Copy the `.golangci.yml` to the root of your project.

Create a new `Makefile` in the root of your project and add the following to it:

```shell
MAKEGO := make/go
MAKEGO_REMOTE := https://github.com/azarc-io/make.git
PROJECT := <YOUR PROJECT NAME NO SPACES OR DASHES>
GO_MODULE := <YOUR PROJECTS GO MODULE EG. github.com/azarc-io/project>

include make/<SAME AS WHATEVER YOU RENAME FOO TO>/all.mk
```

Next rename the `foo` directory to your projects name and update the settings to
suit your projects needs, 
