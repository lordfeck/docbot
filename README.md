DOCBOT
=========

Your friendly Slack assistant. Written in very neat Perl!

Everything said so far has been a lie. The bot isn't even a doctor, despite preferring to be called Dr. Octobotapus.

Requires the following CPAN modules:

- Slack::RTM::Bot
- String::Random
- Time::Piece

Edit the "consts and strings" section at the top of `docbot.pl` to configure the DOCBOT.

$CHAN: The slack channel DOCBOT will join.

$LOGFILE: Where the bot will log write a log of its conversations.

$BOTNAME: How the bot identifies itself.

$STRIP: Regex of characters to exclude in log files (avoid Perl injections)

$SLKTOK: Very important! Your slack API token should be set here.

@RESPONSES: Set the responses in the following format: RESPONSE, REPLY inside a Perl list. (TODO: make this a hash)
