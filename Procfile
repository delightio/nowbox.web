web: bin/rackup -s thin -p $PORT
worker: QUEUE='update_account_info,graph_channel,refresh_channel,examine_video,examine_mention,remove_spammer,mention' bin/rake resque:work
graph_walker: QUEUE='graph_channel' bin/rake resque:work
scheduler: bin/rake resque:scheduler
console: bin/aji console
