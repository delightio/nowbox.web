web: bin/unicorn -p $PORT -c config/unicorn.rb
mention_worker: QUEUE=mention bin/rake resque:work
worker: QUEUE='debug,publish_share,youtube_sync,refresh_channel,examine_video,examine_mention,remove_spammer,refresh_info,mention' bin/rake resque:work
scheduler: bin/rake resque:scheduler
console: bin/aji console
