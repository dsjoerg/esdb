api: bundle exec unicorn -c config/unicorn.conf
resque: bundle exec rake resque:work INTERVAL=0.1 QUEUE='scraping-crit,replays-crit,replays-high,scraping-high,summaries-high,summaries,scraping,replays-low,scraping-low' VERBOSE=1
resquestar: bundle exec rake resque:work INTERVAL=0.1 QUEUE='replays*' VERBOSE=1
python: env GGFACTORY_CACHE_DIR=devcache GGFACTORY_CACHE_SIZE=100 python -u vendor/ggpyjobs/worker.py run
log: tail -f -n0 log/esdb.log
