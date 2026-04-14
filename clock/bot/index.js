'use strict';

require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const { Client, GatewayIntentBits, Collection, Events } = require('discord.js');
const fs = require('fs');
const path = require('path');
const { getDb } = require('./database');

// Initialise DB on startup
getDb();

const client = new Client({
  intents: [GatewayIntentBits.Guilds],
});

// Load commands
client.commands = new Collection();
const commandsPath = path.join(__dirname, 'commands');
const commandFiles = fs.readdirSync(commandsPath).filter(f => f.endsWith('.js'));

for (const file of commandFiles) {
  const command = require(path.join(commandsPath, file));
  if (command.data && command.execute) {
    client.commands.set(command.data.name, command);
    console.log(`Loaded command: /${command.data.name}`);
  }
}

// Handle slash commands and autocomplete
client.on(Events.InteractionCreate, async interaction => {
  if (interaction.isChatInputCommand()) {
    const command = client.commands.get(interaction.commandName);
    if (!command) {
      console.error(`Unknown command: ${interaction.commandName}`);
      return;
    }

    try {
      await command.execute(interaction);
    } catch (err) {
      console.error(`Error executing /${interaction.commandName}:`, err);
      const msg = { content: '❌ An error occurred running this command.', ephemeral: true };
      if (interaction.replied || interaction.deferred) {
        await interaction.followUp(msg).catch(() => {});
      } else {
        await interaction.reply(msg).catch(() => {});
      }
    }
  } else if (interaction.isAutocomplete()) {
    const command = client.commands.get(interaction.commandName);
    if (command && command.autocomplete) {
      try {
        await command.autocomplete(interaction);
      } catch (err) {
        console.error(`Autocomplete error for /${interaction.commandName}:`, err);
      }
    }
  }
});

client.once(Events.ClientReady, c => {
  console.log(`✅ Universal Clock Bot ready — logged in as ${c.user.tag}`);
});

client.login(process.env.DISCORD_TOKEN);
