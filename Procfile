web: bin/rackup -s thin -p $PORT
worker: QUEUE='invalidate_tokens,kill_bill,publish_share,update_account_info,graph_channel,refresh_channel,examine_video,examine_mention,remove_spammer,refresh_channel_info,mention' bin/rake resque:work
scheduler: bin/rake resque:scheduler
console: bin/aji console
