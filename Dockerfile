FROM alpine:3.7 as builder

MAINTAINER Chris Fordham <chris@fordham-nagy.id.au>

LABEL maintainer "Chris Fordham <chris@fordham-nagy.id.au>"

ENV GOPATH=/usr/src/go

RUN apk add --update --no-cache musl-dev go git make && \
    mkdir -p /usr/src && \
    cd /usr/src && \
    git clone https://github.com/prometheus/prometheus.git && \
    mkdir -p "$GOPATH/src/github.com/prometheus" && \
    ln -sv /usr/src/prometheus "$GOPATH/src/github.com/prometheus/prometheus" && \
    cd "$GOPATH/src/github.com/prometheus/prometheus" && \
    make build

FROM quay.io/prometheus/busybox:latest

COPY --from=builder /usr/src/prometheus/prometheus                            /bin/prometheus
COPY --from=builder /usr/src/prometheus/promtool                              /bin/promtool
COPY --from=builder /usr/src/prometheus/documentation/examples/prometheus.yml /etc/prometheus/prometheus.yml
COPY --from=builder /usr/src/prometheus/console_libraries                     /usr/share/prometheus/console_libraries
COPY --from=builder /usr/src/prometheus/consoles                              /usr/share/prometheus/consoles

RUN ln -s /usr/share/prometheus/console_libraries /usr/share/prometheus/consoles/ /etc/prometheus/ && \
    mkdir -p /prometheus && \
    chown -R nobody:nogroup etc/prometheus /prometheus

USER nobody

EXPOSE 9090

WORKDIR /prometheus

ENTRYPOINT ["/bin/prometheus"]

CMD        ["--config.file=/etc/prometheus/prometheus.yml", \
            "--storage.tsdb.path=/prometheus", \
            "--web.console.libraries=/usr/share/prometheus/console_libraries", \
            "--web.console.templates=/usr/share/prometheus/consoles"]
