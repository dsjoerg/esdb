$stderr.puts "[ESDB] restarting memcached to clear the garner cache"
sudo! "monit restart all -g memcached" 

# runs the innodb warmup!
# 20121128 DJ: hrm, we dont want to do this on every deploy
#run "bundle exec rake db:warmup"
