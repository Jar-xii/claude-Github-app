'use strict';

const { SlashCommandBuilder } = require('discord.js');
const { resolveAlias, searchAliases } = require('../../shared/timezoneAliases');
const { setTimezone } = require('../database');
const { formatForDisplay, formatUtcOffset } = require('../../shared/timeParser');
const { DateTime } = require('luxon');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('settz')
    .setDescription('Set your personal timezone for time conversions')
    .addStringOption(opt =>
      opt
        .setName('timezone')
        .setDescription('Your timezone — e.g. UK, EST, Tokyo, Europe/London')
        .setRequired(true)
        .setAutocomplete(true)
    ),

  async autocomplete(interaction) {
    const focused = interaction.options.getFocused();
    const results = searchAliases(focused);

    await interaction.respond(
      results.map(({ alias, ianaZone }) => ({
        name: `${alias} — ${ianaZone}`,
        value: alias,
      }))
    );
  },

  async execute(interaction) {
    const raw = interaction.options.getString('timezone', true);
    const resolved = resolveAlias(raw);

    if (!resolved) {
      return interaction.reply({
        content:
          `❌ Unknown timezone: \`${raw}\`\n` +
          `Use an alias like \`UK\`, \`EST\`, \`Tokyo\` or a full IANA name like \`Europe/London\`.\n` +
          `Run \`/listtz\` to see all registered users.`,
        ephemeral: true,
      });
    }

    setTimezone(interaction.user.id, 'discord', resolved, interaction.user.username);

    const now = DateTime.now().setZone(resolved);
    const timeStr = formatForDisplay(now, true);
    const offset = formatUtcOffset(now);

    await interaction.reply({
      content:
        `✅ Timezone set to **${resolved}** (${offset})\n` +
        `Your current local time: **${timeStr}**`,
      ephemeral: true,
    });
  },
};
