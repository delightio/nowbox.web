web: bin/rackup -s thin -p $PORT
resque: QUEUE=* bin/rake resque:work
scheduler: bin/rake resque:scheduler
console: bin/aji console
