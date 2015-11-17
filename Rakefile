# Taken straight from dblock before going all out fancy docs on this.
# http://code.dblock.org/grape-describing-and-documenting-an-api
#
# $ rake api:routes

require './esdb'
require 'resque/tasks'

namespace :esdb do
  # This is run by the deploy/before_symlink to test for configuration errors
  # and other problems. Currently, it does nothing, but it will explode upon 
  # loading ./esdb when memcached is unavailable in production/staging.
  task :ok do
  end

  desc 'Recalculate aggregate stats in Stat, to be cronned'
  task :aggregate do
    AggregateStat.recalc!
  end

  desc 'Clears empty resque queues'
  task :clear_empty_resque do
    queues = Resque.queues
    queues.each do |queue_name|
      if /replays([0-9a-f])+/.match(queue_name).present? && Resque.size("#{queue_name}") == 0
        puts "Clearing #{queue_name}..."
        Resque.remove_queue(queue_name)
      end
    end
  end
end

namespace :db do
  # The additional time it'll take this rake task to run is still less than
  # grepping and copying from README every time.
  desc "Runs sequel migration command"
  task :migrate do
    %x[bundle exec sequel -m db/migrations -e #{ESDB.env} config/database.yml]
  end

  desc "warm up the innodb buffer pool"
  task :warmup do
    queries = {
      ident: "SELECT achievement_points FROM esdb_identities WHERE achievement_points = 666",
      ie: "SELECT id FROM esdb_identity_entities WHERE id IS NOT NULL",
      m: "SELECT average_league FROM esdb_matches WHERE duration_seconds = 1234567",
      me: "SELECT apm FROM esdb_sc2_match_entities WHERE u0 = 12345",
      rm: "SELECT apm FROM esdb_sc2_match_replay_minutes WHERE apm = 12345",
      mu: "SELECT matchup FROM esdb_sc2_match_matchups WHERE matchup = 7"
    }

    ESDB.log('Warming up the InnoDB buffer pool:')

    queries.each do |k, query|
      ESDB.log("\t #{k}: %s ('#{query}')" % DB.fetch(query).all.count)
    end

    ESDB.log('Afterburners engage')

    # http://philipzhong.blogspot.com/2011/06/how-to-preload-innodb-table-and-index.html
    stmts = [
    "SET SESSION group_concat_max_len=100*1024*1024",
"""
SELECT GROUP_CONCAT(CONCAT('SELECT COUNT(`',column_name,'`) FROM `',table_schema,'`.`',table_name,'` FORCE INDEX (`',index_name,'`)') SEPARATOR ' UNION ALL ')
INTO @sql FROM information_schema.statistics
WHERE table_schema NOT IN ('information_schema','mysql', 'cr_debug') AND seq_in_index = 1 AND
table_name NOT IN ('esdb_sc2_match_summary_buildorderitem', 'esdb_sc2_match_summary_graphpoint', 'BLACKHOLE_FOO')
""",
    "PREPARE stmt FROM @sql",
    "EXECUTE stmt",
    "DEALLOCATE PREPARE stmt",
    "SET SESSION group_concat_max_len=@@group_concat_max_len"
    ]
    stmts.each{|stmt| DB.fetch(stmt).all}

    ESDB.log('Boiling hot')

  end

  desc "compute aggregate player stats"
  task :playerstats do
    stmts = [
"DROP TABLE IF EXISTS replays_econ_stat",
"""
CREATE TABLE replays_econ_stat
select ees.highest_league, e1.race as race, e2.race as vs_race,
  avg(base_2) as base_2, avg(miningbase_2) as miningbase_2,
  avg(base_3) as base_3, avg(miningbase_3) as miningbase_3,
  avg(saturation_1) as saturation_1,   avg(saturation_2) as saturation_2,  avg(saturation_3) as saturation_3,
  avg(mineral_saturation_1) as mineral_saturation_1,   avg(mineral_saturation_2) as mineral_saturation_2,  avg(mineral_saturation_3) as mineral_saturation_3,
  avg(greatest(0,saturation_2 - miningbase_2)) as delta2,
  avg(greatest(0,saturation_3 - miningbase_3)) as delta3,
  avg(greatest(0,mineral_saturation_2 - miningbase_2)) as mdelta2,
  avg(greatest(0,mineral_saturation_3 - miningbase_3)) as mdelta3,
  avg(worker22x_1) as worker22x_1, avg(worker22x_2) as worker22x_2, avg(worker22x_3) as worker22x_3,
  now() as retrieval_time, count(*)
from esdb_entity_stats ees,
     esdb_matches m,
	 esdb_sc2_match_entities e1,
     esdb_sc2_match_entities e2
where m.category = 'Ladder'
  and m.game_type = '1v1'
  and m.gateway != 'xx'
  and m.vs_ai = 0
  and m.expansion = 2
  and e1.id != e2.id
  and m.played_at > '2015-11-09'
  and e1.match_id = m.id
  and e2.match_id = m.id
  and e1.id = ees.entity_id
  and ees.highest_league >= 0
  and ees.highest_league <= 6
group by ees.highest_league, e1.race, e2.race
order by e1.race, e2.race, ees.highest_league
""",
"DROP TABLE IF EXISTS replays_sq_skill_stat",
"""
CREATE TABLE replays_sq_skill_stat
select highest_league as league,
       m.gateway,
       e.race,
       floor(m.duration_seconds/60.0) as mins,
       avg(35.0 * (0.00137 * resource_collection_rate - ln(average_unspent_resources)) + 240) as SQ,
       count(*)
from esdb_sc2_match_summary_playersummary ps,
     esdb_sc2_match_entities e, esdb_matches m
where ps.entity_id = e.id and
      e.match_id = m.id and
      highest_league is not null and
      m.gateway is not null and
      m.game_type = '1v1' and
      m.category = 'Ladder' and
      m.expansion = 2 and
      resource_collection_rate > 100 and
      average_unspent_resources > 0 and
      duration_seconds >= 270 and
      duration_seconds < 1800 and
      m.played_at > '2015-11-09'
group by m.gateway, highest_league, mins, race
order by m.gateway, highest_league, mins asc, race
""",
    ]
    stmts.each{|stmt| DB.fetch(stmt).all}
    Resque.redis.del('econ_stats')
    Resque.redis.del('econ_staircase')
    Resque.redis.set('sq_should_nuke', 'YES')

    # preheat the cache by retrieving the URL
    Curl.get('http://api.ggtracker.com/api/v1/econ_stats/staircase')
    Curl.get('http://api.ggtracker.com/api/v1/spending_skill/am/p')
  end
end

def check_s2gs_pop
  last_pop = Time.at(Resque.redis.get('mon:queue:pop').to_i)

  # ERROR
  # The windows task runs every hour, if you get two of these, there's a 
  # problem.
  if (Time.now - last_pop) > 30.minutes
    warnstr = "THE WORLD IS ENDING"
    ESDB.error(warnstr)
    return
  end

  # WARN
  if (Time.now - last_pop) > 5.minutes
    warnstr = "5 minutes since last s2gs pop - s2gs_client might be dead"
    ESDB.warn(warnstr)
    return
  end
end

# Various monitoring tasks
namespace :mon do
  desc "Notifies humans about no queue/pop happening, suggesting the s2gs_client being down"
  task :s2gspop do
    check_s2gs_pop
  end

  desc "Runs all monitoring tasks"
  task :all do
    tasks = [:s2gspop]
    tasks.each do |t|
      Rake::Task["mon:#{t.to_s}"].execute
    end
  end
end

namespace :api do
  desc "Displays all API methods."
  task :routes do
    ESDB::API.routes.each do |route|
      route_path = route.route_path.gsub('(.:format)', '').gsub(':version', route.route_version)
      puts "#{route.route_method} #{route_path}"
      puts " #{route.route_description}" if route.route_description
      if route.route_params.is_a?(Hash)
        params = route.route_params.map do |name, desc|
          required = desc.is_a?(Hash) ? desc[:required] : false
          description = desc.is_a?(Hash) ? desc[:description] : desc.to_s
          [ name, required, "   * #{name}: #{description} #{required ? '(required)' : ''}" ]
        end
        puts "  parameters:"
        params.each { |p| puts p[2] }
      end
    end
  end
end

namespace :py do
  desc "Clean up ggpyjobs (remove compile bytecode)"
  task :clean do
    # Clear out all pyc files
    Dir.glob('vendor/ggpyjobs/**/*pyc').each{|f| File.unlink(f)}
  end

  # This will initialize the submodule for deployment
  desc "Init ggpyjobs"
  task :init => :clean do
    puts "$ git submodule update --init"
    puts %x{git submodule update --init}

    pip_install_cmd = "pip install -r requirements.txt --allow-external pil --allow-unverified pil"
    puts "vendor/ggpyjobs$ echo \"w\" | #{ pip_install_cmd }"
    puts %x{cd vendor/ggpyjobs; echo "w" | #{ pip_install_cmd }; cd ../..}
  end

  # IMPORTANT: this is for development, not for deployment.
  # make sure our submodule ref is up to date for the version of ggpyjobs that
  # esdb needs.
  desc "Update ggpyjobs"
  task :update => :clean do
    # Run pip to update requirements - Note: one "s" might not be enough.
    # It is here to answer a single "switch" prompt if we change the sc2reader
    # git ref.

    # I can not for the life of me get it to flush stdout during %x .. TODO 
    # (not really, it's not a breaker, but it annoys me)
    # STDOUT.sync = true
    puts "vendor/ggpyjobs$ git checkout master && git pull"
    puts %x{cd vendor/ggpyjobs; git checkout master && git pull; cd ../..}

    pip_install_cmd = "pip install -r requirements.txt --allow-external pil --allow-unverified pil"
    puts "vendor/ggpyjobs$ echo \"w\" | #{ pip_install_cmd }"
    puts %x{cd vendor/ggpyjobs; echo "w" | #{ pip_install_cmd }; cd ../..}
  end
end
