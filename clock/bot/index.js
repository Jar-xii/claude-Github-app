'use strict';

require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const { DISCORD_TOKEN } = process.env;
if (!DISCORD_TOKEN) {
  console.error(
    'ERROR: DISCORD_TOKEN is not set.\n' +
    'Copy clock/.env.example to clock/.env and fill in your bot token.\n' +
    'See clock/README.md for Discord setup instructions.'
  );
  process.exit(1);
}

const { Client, GatewayIntentBits, Collection, Events } = require('discord.js');
const fs   = require('fs');
const path = require('path');
const { getDb } = require('./database');

// Initialise DB on startup (creates tables if needed)
getDb();

const client = new Client({ intents: [GatewayIntentBits.Guilds] });

// ── Load commands ─────────────────────────────────────────────────────────────
client.commands = new Collection();
const commandsPath = path.join(__dirname, 'commands');

for (const file of fs.readdirSync(commandsPath).filter(f => f.endsWith('.js'))) {
  const command = require(path.join(commandsPath, file));
  if (command.data && command.execute) {
    client.commands.set(command.data.name, command);
    console.log(`Loaded command: /${command.data.name}`);
  }
}

// ── Interaction handler ───────────────────────────────────────────────────────
client.on(Events.InteractionCreate, async interaction => {
  if (interaction.isChatInputCommand()) {
    const command = client.commands.get(interaction.commandName);
    if (!command) {
      console.error(`Unknown command received: ${interaction.commandName}`);
      return;
    }

    try {
      await command.execute(interaction);
    } catch (err) {
      console.error(`Error in /${interaction.commandName}:`, err);
      const msg = { content: '❌ Something went wrong running this command.', ephemeral: true };
      if (interaction.replied || interaction.deferred) {
        await interaction.followUp(msg).catch(() => {});
      } else {
        await interaction.reply(msg).catch(() => {});
      }
    }

  } else if (interaction.isAutocomplete()) {
    const command = client.commands.get(interaction.commandName);
    if (command?.autocomplete) {
      try {
        await command.autocomplete(interaction);
      } catch (err) {
        console.error(`Autocomplete error in /${interaction.commandName}:`, err);
      }
    }
  }
});

client.once(Events.ClientReady, c => {
  console.log(`✅ Universal Clock Bot ready — logged in as ${c.user.tag}`);
});

client.login(DISCORD_TOKEN);
