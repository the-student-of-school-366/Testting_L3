FROM golang:1.27-alpine

WORKDIR /app

COPY go.mod ./
COPY internal/ ./internal/
COPY tests/ ./tests/

CMD ["go", "test", "./tests/e2e", "-v", "-count=1"]
