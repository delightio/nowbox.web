web: bin/rackup -s thin -p $PORT
worker: QUEUE=* bin/rake resque:work
graph_walker: QUEUE='graph_channel' bin/rake resque:work
scheduler: bin/rake resque:scheduler
console: bin/aji console
