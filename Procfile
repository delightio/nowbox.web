web: bin/rackup -s thin -p $PORT
mention_worker: QUEUE=mention bin/rake resque:work
worker: QUEUE='debug,publish_share,youtube_sync,update_account_info,refresh_channel,examine_video,examine_mention,remove_spammer,refresh_channel_info,mention' bin/rake resque:work
scheduler: bin/rake resque:scheduler
console: bin/aji console
