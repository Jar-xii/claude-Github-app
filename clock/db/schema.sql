CREATE TABLE IF NOT EXISTS user_timezones (
    user_id      TEXT    NOT NULL,
    platform     TEXT    NOT NULL CHECK(platform IN ('discord', 'web')),
    iana_zone    TEXT    NOT NULL,
    display_name TEXT,
    updated_at   INTEGER NOT NULL DEFAULT (unixepoch()),
    PRIMARY KEY (user_id, platform)
);

CREATE INDEX IF NOT EXISTS idx_user_timezones_platform
    ON user_timezones(platform);
