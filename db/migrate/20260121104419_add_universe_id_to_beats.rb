class AddUniverseIdToBeats < ActiveRecord::Migration[8.0]
  def up
    # Add universe_id column (nullable first)
    add_reference :beats, :universe, foreign_key: true

    # Backfill existing beats with universe_id from scene -> chapter -> universe
    execute <<-SQL
      UPDATE beats
      SET universe_id = (
        SELECT chapters.universe_id
        FROM scenes
        JOIN chapters ON scenes.chapter_id = chapters.id
        WHERE scenes.id = beats.scene_id
      )
      WHERE scene_id IS NOT NULL
    SQL

    # Make scene_id nullable (beats now belong directly to universe)
    change_column_null :beats, :scene_id, true
  end

  def down
    remove_reference :beats, :universe
    change_column_null :beats, :scene_id, false
  end
end
