
# computes a preconfigured set of stats for a given identity from a dataset of matches

class ESDB::DJStatBuilder

  def initialize(identity_id, matches_dataset)
    @identity_id = identity_id
    @matches_dataset = matches_dataset
  end

  def build!
    mtable = ESDB::Sc2::Match::Replay::Minute.table_name
    colname = 'armystrength'
    qcol = Sequel.qualify(mtable, colname)
    qmin = Sequel.qualify(mtable, 'minute')

    # minutes joined to entity
    dataset_minutes = ESDB::Sc2::Match::Replay::Minute.inner_join(ESDB::Sc2::Match::Entity, :id => :entity_id)

    # but only for the given identity
    dataset_minutes = dataset_minutes.inner_join(ESDB::IdentityEntity, {:entity_id => :id, :identity_id => @identity_id})

    # and only for the given matches
    minutes_matches = dataset_minutes.inner_join(@matches_dataset, {:id=>Sequel.qualify(ESDB::Sc2::Match::Entity.table_name, 'match_id')}, {:table_alias => 'match_inner'})

    # also we want matches from the last two weeks
    lasttwo = @matches_dataset.where("played_at > (now() - interval 14 day)")
    minutes_matches_lasttwo = dataset_minutes.inner_join(lasttwo, {:id=>Sequel.qualify(ESDB::Sc2::Match::Entity.table_name, 'match_id')}, {:table_alias => 'match_inner'})

    # group the desired column by minute
    @dataset_result = minutes_matches.select(:minute, Sequel.function(:avg, qcol).as(colname)).where{qmin > 0}.where{qmin < 31}.order(qmin).group(qmin)
    @dataset_result_lasttwo = minutes_matches_lasttwo.select(:minute, Sequel.function(:avg, qcol).as(colname)).where{qmin > 0}.where{qmin < 31}.order(qmin).group(qmin)
  end

  def to_hash
    if @identity_id.present?
      armystrength = @dataset_result.all.collect{|row| row[:armystrength].to_i}
      armystrength_lasttwo = @dataset_result_lasttwo.all.collect{|row| row[:armystrength].to_i}
      {:armystrength => armystrength,
       :armystrength_lasttwo => armystrength_lasttwo}
    else
      {}
    end
  end
end
