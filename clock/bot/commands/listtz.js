'use strict';

const { SlashCommandBuilder, EmbedBuilder } = require('discord.js');
const { getAllTimezones } = require('../database');
const { formatForDisplay, formatUtcOffset } = require('../../shared/timeParser');
const { DateTime } = require('luxon');

// Discord embed field limit is 25; value limit is 1024 chars.
// We use an embed with one field per user — safe for up to 25 users.
// Beyond that we paginate with multiple embeds.
const MAX_FIELDS_PER_EMBED = 25;

module.exports = {
  data: new SlashCommandBuilder()
    .setName('listtz')
    .setDescription('List all registered timezones and their current local times'),

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

    // Build one embed per page of 25 users
    const embeds = [];
    for (let i = 0; i < users.length; i += MAX_FIELDS_PER_EMBED) {
      const page     = users.slice(i, i + MAX_FIELDS_PER_EMBED);
      const pageNum  = Math.floor(i / MAX_FIELDS_PER_EMBED) + 1;
      const total    = Math.ceil(users.length / MAX_FIELDS_PER_EMBED);
      const title    = total > 1
        ? `🌍  Registered Timezones (page ${pageNum}/${total})`
        : `🌍  Registered Timezones (${users.length})`;

      const embed = new EmbedBuilder()
        .setColor(0x5865F2)
        .setTitle(title)
        .setTimestamp();

      for (const user of page) {
        let nowStr = '(invalid timezone)';
        let offset = '';
        try {
          const now = DateTime.now().setZone(user.iana_zone);
          nowStr = formatForDisplay(now, true);
          offset = formatUtcOffset(now);
        } catch { /* skip invalid stored zone */ }

        const name = user.display_name || `User ${user.user_id}`;
        embed.addFields({
          name,
          value: `${nowStr} ${offset}\n\`${user.iana_zone}\``,
          inline: true,
        });
      }

      embeds.push(embed);
    }

    await interaction.reply({ embeds, ephemeral: true });
  },
};
