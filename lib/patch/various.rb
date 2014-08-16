# Various patches, some very ugly and/or unnecessary. Please revise often.

class TrueClass
  def to_i
    1
  end
end

class FalseClass
  def to_i
    0
  end
end


# I'm done with this.. the only thing it's good for, is display on the web
# UI and our deployment flushes the workers anyway. So.. 
#
# Also, in case anyone's stepping in here wondering: it dies silently when
# trying to prune for example our python workers, which it can't identify.
#
# Also, random other year-long discussions on it: 
# https://github.com/defunkt/resque/issues/319
require 'resque/worker'
module Resque
  class Worker
    def prune_dead_workers
    end
  end
end