'use strict';

const { SlashCommandBuilder } = require('discord.js');
const { getAllTimezones } = require('../database');
const { formatForDisplay, formatUtcOffset } = require('../../shared/timeParser');
const { DateTime } = require('luxon');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('listtz')
    .setDescription('List all registered timezones and current local times'),

  async execute(interaction) {
    const users = getAllTimezones('discord');

    if (users.length === 0) {
      return interaction.reply({
        content:
          'No timezones registered yet.\n' +
          'Use `/settz <timezone>` to register yours — e.g. `/settz UK` or `/settz America/New_York`.',
        ephemeral: true,
      });
    }

    const lines = users.map(u => {
      const now = DateTime.now().setZone(u.iana_zone);
      const timeStr = formatForDisplay(now, true);
      const offset = formatUtcOffset(now);
      const name = u.display_name || u.user_id;
      return `**${name}** — \`${u.iana_zone}\` (${offset})\n  Now: ${timeStr}`;
    });

    await interaction.reply({
      content: `**Registered Timezones (${users.length})**\n\n${lines.join('\n\n')}`,
      ephemeral: true,
    });
  },
};
