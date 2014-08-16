# Test configuration
# We need to get STDERR, too!
esdb_test = %x[cd #{config.release_path} && RACK_ENV=#{config.environment} bundle exec rake esdb:ok 2>&1]
raise "esdb:ok failed because memcached was unreachable." if esdb_test.match(/testing-memcached-connectivity/)
raise "esdb:ok failed for another reason: #{esdb_test.inspect}" if esdb_test.match(/rake aborted/)
raise "esdb:ok failed for unknown reasons, check logs." unless $? == 0 # just in case..

# Stop workers
run "sudo monit stop all -g esdb_resque" 
$stderr.puts "waiting ~60s for Resque workers to die.."
resque_up = false
worker_ps = 'ps axo command|grep "res.*[-]"|grep -v grep|grep -v resin'

60.times do
  workers = %x[#{worker_ps}|grep -c res]
  if workers.to_i > 0 
    resque_up = true
  else
    resque_up = false
    break
  end
  
  sleep(1)
end

raise "Workers still up on node: #{node['name']} (#{%x[#{worker_ps}]}), stopping deployment." if resque_up

# Purge the resque:workers set because the ruby workers are unable to prune
# the python job from it.

run "echo 'DEL resque:workers' | redis-cli"
