'use strict';

const { SlashCommandBuilder, EmbedBuilder } = require('discord.js');
const { parseTimeInput, convertTo, formatForDisplay, formatUtcOffset } = require('../../shared/timeParser');
const { getAllTimezones } = require('../database');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('convert')
    .setDescription("Convert a time to everyone's local timezone")
    .addStringOption(opt =>
      opt
        .setName('time')
        .setDescription('Time to convert — e.g. "8pm UK", "15:00 Tokyo", "3:30pm EST"')
        .setRequired(true)
    ),

  async execute(interaction) {
    // Defer so we have time to query the DB and build the embed
    await interaction.deferReply();

    const raw = interaction.options.getString('time', true);
    const parsed = parseTimeInput(raw);

    if (!parsed.ok) {
      return interaction.editReply(
        `❌ Could not parse \`${raw}\`\n` +
        `**Reason:** ${parsed.error}\n` +
        `**Examples:** \`8pm UK\`, \`20:00 BST\`, \`3:30pm Eastern\`, \`1430 PST\`, \`noon UTC\``
      );
    }

    const { result } = parsed;
    const allUsers = getAllTimezones('discord');

    if (allUsers.length === 0) {
      return interaction.editReply(
        'No users have registered their timezones yet.\n' +
        'Have everyone run `/settz <timezone>` first — e.g. `/settz UK` or `/settz EST`.'
      );
    }

    const sourceTime   = formatForDisplay(result.luxonDateTime, true);
    const sourceOffset = formatUtcOffset(result.luxonDateTime);

    const embed = new EmbedBuilder()
      .setColor(0x5865F2)
      .setTitle(`🕐  ${formatForDisplay(result.luxonDateTime)} — ${result.ianaZone}`)
      .setDescription(
        `**Original:** ${sourceTime} (${sourceOffset})\n` +
        `**Requested by:** <@${interaction.user.id}>`
      )
      .setFooter({ text: `Input: ${result.originalInput}` })
      .setTimestamp();

    // Sort: requesting user first, then alphabetically
    const sorted = [...allUsers].sort((a, b) => {
      if (a.user_id === interaction.user.id) return -1;
      if (b.user_id === interaction.user.id) return 1;
      const na = (a.display_name || a.user_id).toLowerCase();
      const nb = (b.display_name || b.user_id).toLowerCase();
      return na.localeCompare(nb);
    });

    for (const user of sorted) {
      // Guard against a corrupted or removed zone in the database
      let timeStr, offset;
      try {
        const converted = convertTo(result, user.iana_zone);
        timeStr = formatForDisplay(converted, false);
        offset  = formatUtcOffset(converted);
      } catch {
        timeStr = '(invalid timezone)';
        offset  = '';
      }

      const label  = user.display_name || `User ${user.user_id}`;
      const isSelf = user.user_id === interaction.user.id;

      embed.addFields({
        name:   isSelf ? `${label} (you)` : label,
        value:  `**${timeStr}** ${offset}\n\`${user.iana_zone}\``,
        inline: true,
      });
    }

    await interaction.editReply({ embeds: [embed] });
  },
};
