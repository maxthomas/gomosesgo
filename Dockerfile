FROM golang:1.8

RUN mkdir -p $GOPATH/bin && \
    go get github.com/Masterminds/glide && \
    go get github.com/mitchellh/gox && \
    glide up

RUN gox -osarch "linux/amd64" -output "gomosesgo" .

COPY bin bin/
COPY scripts/run.sh .

EXPOSE 8080

ENTRYPOINT [ "./run.sh" ]
