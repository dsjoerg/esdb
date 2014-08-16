# With gem version 2.0, this will work, it outputs to the log but still not
# back to our console.. jesus christ, why?
# shell.status "serverside version?"

# Link away a shared system path that sticks on the EBS volume
# we later want this to be outside of /data, an EBS volume shared between
# esdb and ggtracker environments maybe.
$stderr.puts "[ESDB] Link: #{config.shared_path}/system -> #{config.release_path}/system"
run "ln -nfs #{config.shared_path}/system #{config.release_path}/system"

# Link up redis.yml
$stderr.puts "[ESDB] Link: #{config.shared_path}/config/redis.yml -> #{config.release_path}/config/redis.yml"
run "ln -nfs #{config.shared_path}/config/redis.yml #{config.release_path}/config/redis.yml"

# Update ggpyjobs and install its requirements
$stderr.puts "[ESDB] Running rake py:init on (oops cant current_name anymore)"
sudo! "bundle exec rake py:init"

$stderr.puts "[ESDB] Restarting resque through monit"
sudo! "monit start all -g esdb_resque" 

# Ensure permissions on log/esdb.log are proper, because both workers and
# esdb want to write to it.
$stderr.puts "[ESDB] Ensuring ownership and permissions on esdb.log"

# TODO: the ownership is overridden.. or who knows what's happening, there is
# no debug output. But chmodding works, it seems.
# sudo! "chown -R deploy:deploy #{config.release_path}/log && chmod -R g+w #{config.release_path}/log"
# sudo! "chown -R deploy:deploy #{config.shared_path}/log && chmod -R g+w #{config.shared_path}/log"

# And we'll just 777 it now because I'm annoyed.
sudo! "chmod 777 #{config.shared_path}/log/esdb.log"
