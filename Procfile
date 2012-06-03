web: bin/rackup -s thin -p $PORT
worker: QUEUE='debug,youtube_sync,refresh_channel,examine_video,refresh_info,background_youtube_request' bin/rake resque:work
scheduler: bin/rake resque:scheduler
console: bin/aji console
