web: bin/rackup -s thin -p $PORT
worker: QUEUE=populate_content,refresh_channel,examine_video,examine_mention,graph_channel,mention bin/rake resque:work
graph_walker: QUEUE='graph_channel' bin/rake resque:work
scheduler: bin/rake resque:scheduler
console: bin/aji console
