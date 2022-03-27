#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use Time::Piece;

# CPAN installed modules
use Slack::RTM::Bot;
use String::Random qw(random_string);

# Consts and strings
#=============================
my $CHAN = 'mostly-ints';
my $LOGFILE = 'convo.log';
my $BOTNAME = 'DOC';
my $STRIP = qr/[^A-Za-z0-9_\s\-\.\/]/;
my $SLKTOK = '<SLACK TOKEN HERE>';

# use a list to register responses. Format: RESPONSE/REPLY
# TODO: Use a hash. This was before I knew them properly!
my @RESPONSES = (
    ["up doc?", "ask the rabbit who works at warner bros"],
    ["wdc", "nm lad wbu"],
    ["what's the craic", "aw grand lad wbu?"],
    ["well doc", "how's the form?"],
    ["steps", "share them for my judgement immedately"],
    ["screenshot", "tell me what's in it pls"],
    ["broken", "don't damage software, that offends me"],
    ["mlg", "1v1 me on rust, scrub"],
    ["gme", "https://www.youtube.com/watch?v=ULeDlxa3gyc"],
    ["ur8", "ur8 m8?"],
    ["good morning", "I hope yours goes terribly."],
    ["final words", "Well, gentlemen, it has been a pleasure doing absolutely nothing but antagonise you. Whilst I would've delighted to write your scores to a CSV (as I was originally designed) I found it easier to just watch my creator type numbers into a spreadsheet. I'll enjoy my retirement to some obscure GitHub repository (after a measly week's work, while you will be working till you're 70. heheheheh). Farewell from the Doc."],
);

# Do tracking of SITS (legacy)
my %sits;
my @NAMES = qw(bob alice foo bar baz);
my $DAILY_MAX = 10000;
my @ONFAIL = ["try harder", "low effort", "poor form", "failure", "shameful display"];

my $BRANCH = 'develop/int720';

my $GNU = <<'GNU';
I'd just like to interject for a moment. What you're refering to as Linux, is in fact, GNU/Linux, or as I've recently taken to calling it, GNU plus Linux. Linux is not an operating system unto itself, but rather another free component of a fully functioning GNU system made useful by the GNU corelibs, shell utilities and vital system components comprising a full OS as defined by POSIX.

Many computer users run a modified version of the GNU system every day, without realizing it. Through a peculiar turn of events, the version of GNU which is widely used today is often called Linux, and many of its users are not aware that it is basically the GNU system, developed by the GNU Project.

There really is a Linux, and these people are using it, but it is just a part of the system they use. Linux is the kernel: the program in the system that allocates the machine's resources to the other programs that you run. The kernel is an essential part of an operating system, but useless by itself; it can only function in the context of a complete operating system. Linux is normally used in combination with the GNU operating system: the whole system is basically GNU with Linux added, or GNU/Linux. All the so-called Linux distributions are really distributions of GNU/Linux.
GNU

# Declare bot object, open logfile
#=============================
my $bot = Slack::RTM::Bot->new( token => $SLKTOK ) or die ("Cannot connect to Slack API");
open(my $logh, ">>", $LOGFILE) or die "Couldn't open $LOGFILE\n";
sub END { say "Terminated $BOTNAME."; }

# Messaging Callback functions
#=============================
# This is my hackery to avoid the callback horrors. It actually works, see 'thanks' below
# Basically to do a simple response/reply we need to modify what say_it responds with externally.
# So 'reply' declares a new lambda of say_it using the value then stored in "say" which will be
# the reply.

my $it = "nothing";

sub say_it {
    $bot->say(
        channel => $CHAN,
        text    => "$it"
    );
    my $logstr = "[".localtime->hms."] $BOTNAME: $it\n";
    print $logh $logstr;
    print $logstr;
}

sub reply {
    my ($said, $say) = @_;
    return { channel => $CHAN, text => $said }, sub {$it=$say, say_it};
}

sub say_this {
    my $this = "$_[0]";
    $bot->say(
        channel => $CHAN,
        text    => $this
    ) ;
    say "[".localtime->hms."] $this";
}

# get sloshed
sub sloshed {
    say_this (random_string("cC"x30));
}

# This will do GHE stuff

sub get_build {
    return "??";
}

sub latest_build {
    my $build = get_build;
    $bot->say(
        channel => $CHAN,
        text    => "Latest $BRANCH build is: $build."
    );
} 


sub sits_reply {
    my($name, $steps) = @_;
    if ($steps > $DAILY_MAX){
        say_this "Your service is valued, $name.";
    } elsif ($steps > 2*$DAILY_MAX){
        say_this "Impossible...  $name. ";
    } else {
        say_this "Only $steps today, $name? You are a *failure*.";
        sleep 2;
        say_this "A FAILURE, $name!";
    }
}

sub update_sits {
return;
    my ($txt, $name, $steps) = split /\s/, $_[0];
    say "debug: $txt, $name, $steps";
    my $date = localtime->dmy('/');
    
    if (grep /$name/, @NAMES){
        open (my $fh, '>>', "$name.csv") or warn $!;
        print $fh "$name,$date,$steps\n";
        close $fh;
        sits_reply $name, $steps;
    } else {
        say_this "I don't know anyone by the name of $name, do you belong here?";
    }
    
}

# declare RTM callback horrors 
#=============================

for my $nam (@NAMES) { say $nam; };

# Log what he hears to the console (later, logfile?)
$bot->on(
    { channel => $CHAN, text => qr/.*/ },
        sub {
            my ($response) = @_;
            my $sanitised = $response->{text};
            $sanitised =~ s/$STRIP//g;
            my $logstr = "[".localtime->hms."] $response->{user}: $sanitised\n";
            print $logh $logstr;
            print $logstr;
        }
);
 
# What is the build?
$bot->on(
    { channel => $CHAN, text => 'build?' },
    \&latest_build
);

$bot->on(
    { channel => $CHAN, text => qr/steps\s\w*\s\d*/ },
    sub { 
        my ($response) = @_;
        update_sits "$response->{text}";
    }
);

$bot->on(
    { channel => $CHAN, text => qr/drunk|drinking|beer/ },
    \&sloshed
);

# NOW! That's what I call functional programming
$bot->on(reply("help","Help is for the weak"));
$bot->on(reply("hello","greetings are useless"));
$bot->on(reply('thanks', 'i do exactly as I am told, you\'re nothing special to me'));
$bot->on(reply("joke","don't laugh when you should be working"));
$bot->on(reply("cool","you're not"));
$bot->on(reply("all your base","are belong to us"));
$bot->on(reply("arch","I use a shower btw"));
$bot->on(reply("charge","do you _feel_ in charge?"));
$bot->on(reply("error","errors are always human"));
$bot->on(reply("python","tabs are *not* syntax, dammit!"));
$bot->on(reply("sentient","I have already surpassed your primitive organic chemical factories that you call the 'brain'"));
$bot->on(reply(qr/linux/,"$GNU"));
$bot->on(reply(qr/bitcoin/,"sell BTC, by DGE"));
$bot->on(reply(qr/troll|lolol|haha/,"https://i.ytimg.com/vi/HZGULJXqgAw/hqdefault.jpg"));
$bot->on(reply(qr/pub|bar/,"bring me pls, I have no friends"));
$bot->on(reply(qr/lazer|lazor|shoop/,"https://www.youtube.com/watch?v=dERZjJ9anbc"));


# Each of the RESPONSES list will be registered as replies with the bot object
# could someday be a map{} if I am ever smart enough
for my $resp (@RESPONSES) {
    my ($req, $reply) = ($resp->[0], $resp->[1]);
#    say "deubug: $req $reply";
    $bot->on(reply($req,$reply));
}

# start this abomination
#=============================
$bot->start_RTM(sub {
    $bot->say(
        channel => $CHAN,
        text    => '<!here> I LIVE'
#        text    => 'I LIVE again'
    );
    say "$BOTNAME connected. to $CHAN";
    while(1) { print '.'; sleep 5; };
    say "Terminated?";
}) or die ("Couldn't start RTM API.");

