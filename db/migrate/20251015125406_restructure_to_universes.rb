class RestructureToUniverses < ActiveRecord::Migration[8.0]
  def up
    # Step 1: Create new tables
    create_table :universes do |t|
      t.string :name, null: false
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    create_table :chapters do |t|
      t.string :name, null: false
      t.text :description
      t.references :universe, null: false, foreign_key: true
      t.timestamps
    end

    create_table :scenes do |t|
      t.string :name, null: false
      t.text :description
      t.references :chapter, null: false, foreign_key: true
      t.timestamps
    end

    # Step 2: Add new foreign keys to existing tables (nullable for migration)
    add_reference :characters, :universe, foreign_key: true
    add_reference :locations, :universe, foreign_key: true
    add_reference :beats, :scene, foreign_key: true

    # Step 3: Migrate data from stories to universes
    execute <<-SQL
      INSERT INTO universes (name, user_id, created_at, updated_at)
      SELECT title, user_id, created_at, updated_at FROM stories;
    SQL

    # Step 4: Create default chapters for each universe
    execute <<-SQL
      INSERT INTO chapters (name, universe_id, created_at, updated_at)
      SELECT 'Chapter 1', u.id, u.created_at, u.updated_at
      FROM universes u;
    SQL

    # Step 5: Create default scenes for each chapter
    execute <<-SQL
      INSERT INTO scenes (name, chapter_id, created_at, updated_at)
      SELECT 'Scene 1', c.id, c.created_at, c.updated_at
      FROM chapters c;
    SQL

    # Step 6: Update characters to reference universes
    execute <<-SQL
      UPDATE characters
      SET universe_id = (
        SELECT u.id FROM universes u
        INNER JOIN stories s ON s.user_id = u.user_id AND s.title = u.name AND s.created_at = u.created_at
        WHERE characters.story_id = s.id
        LIMIT 1
      )
      WHERE story_id IS NOT NULL;
    SQL

    # Step 7: Update locations to reference universes
    execute <<-SQL
      UPDATE locations
      SET universe_id = (
        SELECT u.id FROM universes u
        INNER JOIN stories s ON s.user_id = u.user_id AND s.title = u.name AND s.created_at = u.created_at
        WHERE locations.story_id = s.id
        LIMIT 1
      )
      WHERE story_id IS NOT NULL;
    SQL

    # Step 8: Update beats to reference scenes
    execute <<-SQL
      UPDATE beats
      SET scene_id = (
        SELECT sc.id FROM scenes sc
        INNER JOIN chapters ch ON sc.chapter_id = ch.id
        INNER JOIN universes u ON ch.universe_id = u.id
        INNER JOIN stories s ON s.user_id = u.user_id AND s.title = u.name AND s.created_at = u.created_at
        WHERE beats.story_id = s.id
        LIMIT 1
      )
      WHERE story_id IS NOT NULL;
    SQL

    # Step 9: Remove old foreign keys
    remove_reference :characters, :story, foreign_key: true
    remove_reference :locations, :story, foreign_key: true
    remove_reference :beats, :story, foreign_key: true
  end

  def down
    # Add back the old references
    add_reference :characters, :story, foreign_key: true
    add_reference :locations, :story, foreign_key: true
    add_reference :beats, :story, foreign_key: true

    # Restore characters to stories
    execute <<-SQL
      UPDATE characters
      SET story_id = (
        SELECT s.id FROM stories s
        INNER JOIN universes u ON s.user_id = u.user_id AND s.title = u.name AND s.created_at = u.created_at
        WHERE characters.universe_id = u.id
        LIMIT 1
      )
      WHERE universe_id IS NOT NULL;
    SQL

    # Restore locations to stories
    execute <<-SQL
      UPDATE locations
      SET story_id = (
        SELECT s.id FROM stories s
        INNER JOIN universes u ON s.user_id = u.user_id AND s.title = u.name AND s.created_at = u.created_at
        WHERE locations.universe_id = u.id
        LIMIT 1
      )
      WHERE universe_id IS NOT NULL;
    SQL

    # Restore beats to stories
    execute <<-SQL
      UPDATE beats
      SET story_id = (
        SELECT s.id FROM stories s
        INNER JOIN universes u ON s.user_id = u.user_id AND s.title = u.name AND s.created_at = u.created_at
        INNER JOIN chapters ch ON ch.universe_id = u.id
        INNER JOIN scenes sc ON sc.chapter_id = ch.id
        WHERE beats.scene_id = sc.id
        LIMIT 1
      )
      WHERE scene_id IS NOT NULL;
    SQL

    # Remove new references
    remove_reference :characters, :universe, foreign_key: true
    remove_reference :locations, :universe, foreign_key: true
    remove_reference :beats, :scene, foreign_key: true

    # Drop new tables
    drop_table :scenes
    drop_table :chapters
    drop_table :universes
  end
end
