# This job is being run by our python workers!

module ESDB::Jobs
  module Sc2::Replay
    class Parse < ESDB::Job
      @queue = :python

      # This job should never perform in ruby, 
      def perform
        raise "This ain't python brah."
      end
    end
  end
end