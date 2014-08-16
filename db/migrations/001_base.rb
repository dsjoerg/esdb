Sequel.migration do
  change do
    create_table(:esdb_identities) do
      primary_key :id, :type=>Bignum
      String :type, :size=>50, :null=>false
      String :name, :size=>50
      Integer :provider_id
      Integer :provider_ident
      String :gateway, :size=>50
      String :region, :size=>50
      Integer :subregion
      Integer :bnet_id
      Integer :character_code
    end
    
    create_table(:esdb_identity_entities, :ignore_index_errors=>true) do
      Integer :entity_id, :null=>false
      Integer :identity_id, :null=>false
      
      primary_key [:entity_id, :identity_id]
      
      index [:entity_id], :name=>:entity_id
      index [:identity_id], :name=>:identity_id
    end
    
    create_table(:esdb_matches) do
      primary_key :id, :type=>Bignum
    end
    
    create_table(:esdb_player_identities, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      Bignum :player_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:player_id), 0)
      
      index [:player_id], :name=>:index_esdb_player_identities_player
    end
    
    create_table(:esdb_players) do
      primary_key :id, :type=>Bignum
    end
    
    create_table(:esdb_providers) do
      primary_key :id, :type=>Bignum
      String :name, :size=>50, :null=>false
    end
    
    create_table(:esdb_sc2_identities) do
      primary_key :id
      String :name, :size=>255
      String :gateway, :size=>5, :null=>false
      String :region, :size=>5
      Integer :subregion, :null=>false
      Integer :bnet_id, :null=>false
      Integer :character_code
      String :sc2ranks_info, :text=>true
      DateTime :sc2ranks_retrieved, :null=>false
      Integer :avg_wpmx10
      Integer :best_league
      Integer :num_games
      Integer :best_rank
      String :best_race, :size=>1
      Integer :best_num_players
      TrueClass :best_is_random
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :s2gs_last_retrieved_at, :null=>false
      Bignum :player_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:player_id), 0)
    end
    
    create_table(:esdb_sc2_match_entities, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      Float :apm
      Float :wpm
      TrueClass :win
      String :race, :size=>1
      Integer :u0
      Integer :u1
      Integer :u2
      Integer :u3
      Integer :u4
      Integer :u5
      Integer :u6
      Integer :u7
      Integer :u8
      Integer :u9
      Integer :u10
      Integer :u11
      Integer :u12
      Integer :u13
      Integer :u14
      Integer :u15
      Integer :u16
      Integer :u17
      Integer :u18
      Integer :u19
      Integer :identity_id
      Bignum :replay_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u0), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u1), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u2), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u3), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u4), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u5), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u6), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u7), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u8), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u9), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u10), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u11), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u12), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u13), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u14), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u15), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u16), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u17), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u18), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u19), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:replay_id), 0)
      
      index [:replay_id], :name=>:index_esdb_sc2_match_entities_replay
      index [:race], :name=>:race
      index [:win], :name=>:win
    end
    
    create_table(:esdb_sc2_match_replay_minutes, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      Integer :minute
      Integer :apm
      Integer :wpm
      Integer :u0
      Integer :u1
      Integer :u2
      Integer :u3
      Integer :u4
      Integer :u5
      Integer :u6
      Integer :u7
      Integer :u8
      Integer :u9
      Integer :u10
      Integer :u11
      Integer :u12
      Integer :u13
      Integer :u14
      Integer :u15
      Integer :u16
      Integer :u17
      Integer :u18
      Integer :u19
      Bignum :entity_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u0), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u1), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u2), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u3), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u4), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u5), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u6), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u7), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u8), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u9), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u10), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u11), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u12), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u13), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u14), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u15), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u16), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u17), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u18), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:u19), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:entity_id), 0)
      
      index [:entity_id], :name=>:index_esdb_sc2_match_replay_minutes_entity
      index [:minute], :name=>:minute
    end
    
    create_table(:esdb_sc2_match_replays, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      String :release_string, :size=>50
      String :md5, :size=>32
      DateTime :uploaded_at
      DateTime :played_at
      DateTime :processed_at
      Integer :duration
      Bignum :provider_id
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:provider_id), 0)
      
      index [:duration], :name=>:duration
      index [:provider_id], :name=>:index_esdb_sc2_match_replays_provider
      index [:md5], :name=>:md5
    end
    
    create_table(:esdb_sc2_match_summaries, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      Integer :resources
      Integer :units
      Integer :structures
      Integer :overview
      Integer :average_unspent_resources
      Integer :resource_collection_rate
      Integer :workers_created
      Integer :units_trained
      Integer :killed_unit_count
      Integer :structures_built
      Integer :structures_razed_count
      Bignum :replay_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:replay_id), 0)
      
      index [:replay_id], :name=>:index_esdb_sc2_match_summaries_replay
    end
  end
end
