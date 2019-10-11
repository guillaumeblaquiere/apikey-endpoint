# Use the offical Golang image to create a build artifact.
# This is based on Debian and sets the GOPATH to /go.
# https://hub.docker.com/_/golang
FROM golang:1.12 as builder

# Copy local code to the container image.
WORKDIR /go/src/endpoint/
COPY go.mod .
ENV GO111MODULE=on
RUN CGO_ENABLED=1 GOOS=linux go mod download

COPY . .
# Perform test for building a clean package
#RUN go test -v ./...
RUN CGO_ENABLED=1 GOOS=linux go build -v -o server

# Use a Docker multi-stage build to create a lean production image.
# https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds

# Now copy it into our base image.
FROM gcr.io/distroless/base
#RUN apk add --no-cache ca-certificates
ENV ENV="Cloud Run"
COPY --from=builder /go/src/endpoint/server /server
CMD ["/server"]

