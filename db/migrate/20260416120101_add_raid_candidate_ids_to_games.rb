class AddRaidCandidateIdsToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :raid_candidate_ids, :jsonb, default: []
  end
end
