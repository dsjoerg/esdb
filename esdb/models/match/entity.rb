# A quick superclass for game-specific entity classes with
# common/shared functions.
#
# We specify the table name here to keep sequel quiet at startup.
# Would rather do this in ESDB::Sc2::Match::Entity if I could figure
# out how.
#
class ESDB::Match::Entity < Sequel::Model(:esdb_sc2_match_entities)

  def name
    identity ? identity.name : ''
  end

  def sc2_identity
    # DRY up the evil so it can be fixed in one place
    identities.first

    # FIXME: The identity is provided here only so that in the
    #  frontend, player#show can figure out which entity is for the
    #  identity it cares about, and display wpm, apm, etc accordingly.
    #
    # Two ways to fix this:
    #
    # 1) Always provide the SC2 identity, since that's the one the
    #  frontend is currently using.
    # 2) Change the frontend player#show to specifically request entities for a given
    #  identity.  Then we can limit the entities to the ones for that identity,
    #  and then there's no need to include the identity details in this response.
  end

  # Serialize to Jbuilder
  def to_builder(options = {})
    builder = options[:builder] || jbuilder(options)
    builder.(self, :id, :wpm, :apm, :spending_skill, :win, :race, :team, :color, :race_macro,
             :sat_1_skill, :sat_2_skill, :sat_3_skill, :saturation_skill, :max_creep_spread)
    builder.identity sc2_identity.to_builder.attributes! if sc2_identity
    builder.spending_quotient summary.spending_quotient if summary
    
    # TODO add SQ to the entity table, compute it, return it here, and
    #  add it to the matches index for player#show

    # too much crap coming over the wire? could compact this by
    # putting an apm list and a wpm list here instead of a hash
    _minutes = minutes.inject({}) do |hash, minute|
      hash[minute.minute] = {:apm => minute.apm, :wpm => minute.wpm, :creep_spread => minute.creep_spread}
      hash
    end
    # ^ the above can not be passed as an argument directly to the
    # function call below. A good example of why parentheses are a good thing.
    # if passing to the function below, I'd use {} instead of do;end and
    # wrap the entire thing in parantheses.

    builder.minutes _minutes if builder.filter.entity.minutes?
    
    builder
  end
end

