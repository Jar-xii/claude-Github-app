'use strict';

/**
 * Run this script once to register slash commands with Discord.
 * With DISCORD_GUILD_ID set: registers to that guild instantly (for dev/testing).
 * Without DISCORD_GUILD_ID: registers globally (takes up to 1 hour to propagate).
 *
 * Usage:
 *   node clock/bot/deploy-commands.js
 */

require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const { REST, Routes } = require('discord.js');
const fs = require('fs');
const path = require('path');

const { DISCORD_TOKEN, DISCORD_CLIENT_ID, DISCORD_GUILD_ID } = process.env;

if (!DISCORD_TOKEN || !DISCORD_CLIENT_ID) {
  console.error('Missing DISCORD_TOKEN or DISCORD_CLIENT_ID in .env');
  process.exit(1);
}

const commands = [];
const commandsPath = path.join(__dirname, 'commands');

for (const file of fs.readdirSync(commandsPath).filter(f => f.endsWith('.js'))) {
  const command = require(path.join(commandsPath, file));
  if (command.data) {
    commands.push(command.data.toJSON());
  }
}

const rest = new REST().setToken(DISCORD_TOKEN);

(async () => {
  try {
    console.log(`Deploying ${commands.length} slash command(s)…`);

    let route;
    if (DISCORD_GUILD_ID) {
      route = Routes.applicationGuildCommands(DISCORD_CLIENT_ID, DISCORD_GUILD_ID);
      console.log(`Target: guild ${DISCORD_GUILD_ID} (instant)`);
    } else {
      route = Routes.applicationCommands(DISCORD_CLIENT_ID);
      console.log('Target: global (up to 1 hour to propagate)');
    }

    const data = await rest.put(route, { body: commands });
    console.log(`✅ Successfully deployed ${data.length} command(s):`);
    data.forEach(cmd => console.log(`  /${cmd.name}`));
  } catch (err) {
    console.error('Failed to deploy commands:', err);
    process.exit(1);
  }
})();
