CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "stories" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "title" varchar NOT NULL, "description" text, "user_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "prompt" text /*application='Vidmana'*/, CONSTRAINT "fk_rails_c53f5feaac"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_stories_on_user_id" ON "stories" ("user_id") /*application='Vidmana'*/;
CREATE TABLE IF NOT EXISTS "users" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "email" varchar DEFAULT '' NOT NULL, "encrypted_password" varchar DEFAULT '' NOT NULL, "reset_password_token" varchar, "reset_password_sent_at" datetime(6), "remember_created_at" datetime(6), "name" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "provider" varchar /*application='Vidmana'*/, "uid" varchar /*application='Vidmana'*/, "avatar_url" varchar /*application='Vidmana'*/);
CREATE UNIQUE INDEX "index_users_on_email" ON "users" ("email") /*application='Vidmana'*/;
CREATE UNIQUE INDEX "index_users_on_reset_password_token" ON "users" ("reset_password_token") /*application='Vidmana'*/;
CREATE TABLE IF NOT EXISTS "universes" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "user_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "prompt" text /*application='Vidmana'*/, CONSTRAINT "fk_rails_dcb1aabc38"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_universes_on_user_id" ON "universes" ("user_id") /*application='Vidmana'*/;
CREATE TABLE IF NOT EXISTS "chapters" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "description" text, "universe_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_b3a6806c88"
FOREIGN KEY ("universe_id")
  REFERENCES "universes" ("id")
);
CREATE INDEX "index_chapters_on_universe_id" ON "chapters" ("universe_id") /*application='Vidmana'*/;
CREATE TABLE IF NOT EXISTS "scenes" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "description" text, "chapter_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_cd5ff5d11b"
FOREIGN KEY ("chapter_id")
  REFERENCES "chapters" ("id")
);
CREATE INDEX "index_scenes_on_chapter_id" ON "scenes" ("chapter_id") /*application='Vidmana'*/;
CREATE TABLE IF NOT EXISTS "characters" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "description" text, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "role" varchar, "universe_id" integer, CONSTRAINT "fk_rails_e7093ff482"
FOREIGN KEY ("universe_id")
  REFERENCES "universes" ("id")
);
CREATE INDEX "index_characters_on_universe_id" ON "characters" ("universe_id") /*application='Vidmana'*/;
CREATE TABLE IF NOT EXISTS "locations" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "description" text, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "location_type" varchar, "universe_id" integer, CONSTRAINT "fk_rails_d649f80004"
FOREIGN KEY ("universe_id")
  REFERENCES "universes" ("id")
);
CREATE INDEX "index_locations_on_universe_id" ON "locations" ("universe_id") /*application='Vidmana'*/;
CREATE TABLE IF NOT EXISTS "beats" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "title" varchar NOT NULL, "description" text NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "order_index" integer, "scene_id" integer, CONSTRAINT "fk_rails_a9549b15d0"
FOREIGN KEY ("scene_id")
  REFERENCES "scenes" ("id")
);
CREATE INDEX "index_beats_on_scene_id" ON "beats" ("scene_id") /*application='Vidmana'*/;
CREATE TABLE IF NOT EXISTS "sessions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "session_id" varchar NOT NULL, "data" text, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_sessions_on_session_id" ON "sessions" ("session_id") /*application='Vidmana'*/;
CREATE INDEX "index_sessions_on_updated_at" ON "sessions" ("updated_at") /*application='Vidmana'*/;
CREATE TABLE IF NOT EXISTS "mana_prompts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "content" text NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_3d9ebbd959"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE UNIQUE INDEX "index_mana_prompts_on_user_id" ON "mana_prompts" ("user_id") /*application='Vidmana'*/;
CREATE TABLE IF NOT EXISTS "universe_shares" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "universe_id" integer NOT NULL, "user_id" integer NOT NULL, "permission_level" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_fd99c5a90d"
FOREIGN KEY ("universe_id")
  REFERENCES "universes" ("id")
, CONSTRAINT "fk_rails_4b9e6c1d76"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_universe_shares_on_universe_id" ON "universe_shares" ("universe_id") /*application='Vidmana'*/;
CREATE INDEX "index_universe_shares_on_user_id" ON "universe_shares" ("user_id") /*application='Vidmana'*/;
CREATE UNIQUE INDEX "index_universe_shares_on_universe_id_and_user_id" ON "universe_shares" ("universe_id", "user_id") /*application='Vidmana'*/;
INSERT INTO "schema_migrations" (version) VALUES
('20251019125956'),
('20251019124456'),
('20251019122547'),
('20251016092253'),
('20251015125406'),
('20250925094543'),
('20250922004500'),
('20250922002749'),
('20250922001953'),
('20250922000453'),
('20250828124830'),
('20250828124755'),
('20250828124720'),
('20250828124638'),
('20250828124548');

