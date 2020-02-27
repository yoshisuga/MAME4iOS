#!/usr/bin/env perl

#
# Markdown -- A text-to-HTML conversion tool for web writers
#
# Copyright (C) 2004 John Gruber
# Copyright (C) 2015,2016,2017,2018,2019 Kyle J. McKay
# All rights reserved.
# License is Modified BSD (aka 3-clause BSD) License\n";
# See LICENSE file (or <https://opensource.org/licenses/BSD-3-Clause>)
#

package Markdown;

require 5.008;
use strict;
use warnings;

use Encode;

use vars qw($COPYRIGHT $VERSION @ISA @EXPORT_OK);

BEGIN {*COPYRIGHT =
\"Copyright (C) 2004 John Gruber
Copyright (C) 2015,2016,2017,2018,2019 Kyle J. McKay
All rights reserved.
";
*VERSION = \"1.1.9"
}

require Exporter;
use Digest::MD5 qw(md5 md5_hex);
use File::Basename qw(basename);
use Scalar::Util qw(refaddr looks_like_number);
my ($hasxml, $hasxml_err); BEGIN { ($hasxml, $hasxml_err) = (0, "") }
my ($hasxmlp, $hasxmlp_err); BEGIN { ($hasxmlp, $hasxmlp_err) = (0, "") }
@ISA = qw(Exporter);
@EXPORT_OK = qw(Markdown);
$INC{__PACKAGE__.'.pm'} = $INC{basename(__FILE__)} unless exists $INC{__PACKAGE__.'.pm'};

close(DATA) if fileno(DATA);
exit(&_main(@ARGV)||0) unless caller;

sub fauxdie($) {
    my $msg = join(" ", @_);
    $msg =~ s/\s+$//os;
    printf STDERR "%s: fatal: %s\n", basename($0), $msg;
    exit 1;
}

my $encoder;
BEGIN {
	$encoder = Encode::find_encoding('Windows-1252') ||
		   Encode::find_encoding('ISO-8859-1') or
		   die "failed to load ISO-8859-1 encoder\n";
}

#
# Global default settings:
#
my ($g_style_prefix, $g_empty_element_suffix, $g_indent_width, $g_tab_width);
BEGIN {
    $g_style_prefix = "_markdown-";	# Prefix for markdown css class styles
    $g_empty_element_suffix = " />";	# Change to ">" for HTML output
    $g_indent_width = 4;		# Number of spaces considered new level
    $g_tab_width = 4;			# Legacy even though it's wrong
}


#
# Globals:
#

# Style sheet template
my $g_style_sheet;

# Permanent block id table
my %g_perm_block_ids;

# Global hashes, used by various utility routines
my %g_urls;
my %g_titles;
my %g_anchors;
my %g_anchors_id;
my %g_block_ids;
my %g_code_block_ids;
my %g_html_blocks;
my %g_code_blocks;
my %opt;

# Return a "block id" to use to identify the block that does not contain
# any characters that could be misinterpreted by the rest of the code
# Originally this used md5_hex but that's unnecessarily slow
# Instead just use the refaddr of the scalar ref of the entry for that
# key in either the global or, if the optional second argument is true,
# permanent table.  To avoid the result being confused with anything
# else, it's prefixed with a control character and suffixed with another
# both of which are not allowed by the XML standard or Unicode.
sub block_id {
    $_[1] or return "\5".refaddr(\$g_block_ids{$_[0]})."\6";
    $_[1] == 1 and return "\2".refaddr(\$g_perm_block_ids{$_[0]})."\3";
    $_[1] == 2 and return "\25".refaddr(\$g_code_block_ids{$_[0]})."\26";
    die "programmer error: bad block_id type $_[1]";
}

# Regex to match balanced [brackets]. See Friedl's
# "Mastering Regular Expressions", 2nd Ed., pp. 328-331.
my $g_nested_brackets;
BEGIN {
    $g_nested_brackets = qr{
    (?>					# Atomic matching
	[^\[\]]+			# Anything other than brackets
     |
	\[
	    (??{ $g_nested_brackets })	# Recursive set of nested brackets
	\]
    )*
    }ox
}

# Regex to match balanced (parentheses)
my $g_nested_parens;
BEGIN {
    $g_nested_parens = qr{
    (?>					# Atomic matching
	[^\(\)]+			# Anything other than parentheses
     |
	\(
	    (??{ $g_nested_parens })	# Recursive set of nested parentheses
	\)
    )*
    }ox
}

# Table of hash values for escaped characters:
my %g_escape_table;
BEGIN {
    $g_escape_table{""} = "\2\3";
    foreach my $char (split //, "\\\`*_~{}[]()>#+-.!|:<") {
	$g_escape_table{$char} = block_id($char,1);
    }
}

# Used to track when we're inside an ordered or unordered list
# (see _ProcessListItems() for details):
my $g_list_level;
BEGIN {
    $g_list_level = 0;
}


#### Blosxom plug-in interface ##########################################
my $_haveBX;
BEGIN {
    no warnings 'once';
    $_haveBX = defined($blosxom::version);
}

# Set $g_blosxom_use_meta to 1 to use Blosxom's meta plug-in to determine
# which posts Markdown should process, using a "meta-markup: markdown"
# header. If it's set to 0 (the default), Markdown will process all
# entries.
my $g_blosxom_use_meta;
BEGIN {
    $g_blosxom_use_meta = 0;
}

sub start { 1; }
sub story {
    my($pkg, $path, $filename, $story_ref, $title_ref, $body_ref) = @_;

    if ((! $g_blosxom_use_meta) or
	(defined($meta::markup) and ($meta::markup =~ /^\s*markdown\s*$/i))
	 ) {
	    $$body_ref = Markdown($$body_ref);
    }
    1;
}


#### Movable Type plug-in interface #####################################
my $_haveMT = eval {require MT; 1;}; # Test to see if we're running in MT
my $_haveMT3 = $_haveMT && eval {require MT::Plugin; 1;}; # and MT >= MT 3.0.

if ($_haveMT) {
    require MT;
    import  MT;
    require MT::Template::Context;
    import  MT::Template::Context;

    if ($_haveMT3) {
	require MT::Plugin;
	import  MT::Plugin;
	my $plugin = new MT::Plugin({
	    name => "Markdown",
	    description => "A plain-text-to-HTML formatting plugin. (Version: $VERSION)",
	    doc_link => 'http://daringfireball.net/projects/markdown/'
	});
	MT->add_plugin( $plugin );
    }

    MT::Template::Context->add_container_tag(MarkdownOptions => sub {
	my $ctx  = shift;
	my $args = shift;
	my $builder = $ctx->stash('builder');
	my $tokens = $ctx->stash('tokens');

	if (defined ($args->{'output'}) ) {
	    $ctx->stash('markdown_output', lc $args->{'output'});
	}

	defined (my $str = $builder->build($ctx, $tokens) )
	    or return $ctx->error($builder->errstr);
	$str; # return value
    });

    MT->add_text_filter('markdown' => {
	label     => 'Markdown',
	docs      => 'http://daringfireball.net/projects/markdown/',
	on_format => sub {
	    my $text = shift;
	    my $ctx  = shift;
	    my $raw  = 0;
	    if (defined $ctx) {
	    my $output = $ctx->stash('markdown_output');
		if (defined $output && $output =~ m/^html/i) {
		    $g_empty_element_suffix = ">";
		    $ctx->stash('markdown_output', '');
		}
		elsif (defined $output && $output eq 'raw') {
		    $raw = 1;
		    $ctx->stash('markdown_output', '');
		}
		else {
		    $raw = 0;
		    $g_empty_element_suffix = " />";
		}
	    }
	    $text = $raw ? $text : Markdown($text);
	    $text;
	},
    });

    # If SmartyPants is loaded, add a combo Markdown/SmartyPants text filter:
    my $smartypants;

    {
	no warnings "once";
	$smartypants = $MT::Template::Context::Global_filters{'smarty_pants'};
    }

    if ($smartypants) {
	MT->add_text_filter('markdown_with_smartypants' => {
	    label     => 'Markdown With SmartyPants',
	    docs      => 'http://daringfireball.net/projects/markdown/',
	    on_format => sub {
		my $text = shift;
		my $ctx  = shift;
		if (defined $ctx) {
		    my $output = $ctx->stash('markdown_output');
		    if (defined $output && $output eq 'html') {
			$g_empty_element_suffix = ">";
		    }
		    else {
			$g_empty_element_suffix = " />";
		    }
		}
		$text = Markdown($text);
		$text = $smartypants->($text, '1');
	    },
	});
    }
}

sub _strip {
	my $str = shift;
	defined($str) or return undef;
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	$str =~ s/\s+/ /g;
	$str;
}

#### BBEdit/command-line text filter interface ##########################
sub _main {
    local *ARGV = \@_;


    #### Check for command-line switches: #################
    my %options = ();
    my %cli_opts;
    my $raw = 0;
    use Getopt::Long;
    Getopt::Long::Configure(qw(bundling require_order pass_through));
    GetOptions(\%cli_opts,
	'help','h',
	'version|V',
	'shortversion|short-version|s',
	'html4tags',
	'deprecated',
	'sanitize',
	'no-sanitize',
	'validate-xml',
	'validate-xml-internal',
	'no-validate-xml',
	'base|b=s',
	'htmlroot|r=s',
	'imageroot|i=s',
	'wiki|w:s',
	'tabwidth|tab-width=s',
	'raw',
	'stylesheet|style-sheet',
	'no-stylesheet|no-style-sheet',
	'stub',
    );
    if ($cli_opts{'help'}) {
	require Pod::Usage;
	Pod::Usage::pod2usage(-verbose => 2, -exitval => 0);
    }
    if ($cli_opts{'h'}) {
	require Pod::Usage;
	Pod::Usage::pod2usage(-verbose => 0, -exitval => 0);
    }
    if ($cli_opts{'version'}) { # Version info
	print "\nThis is Markdown, version $VERSION.\n", $COPYRIGHT;
	print "License is Modified BSD (aka 3-clause BSD) License\n";
	print "<https://opensource.org/licenses/BSD-3-Clause>\n";
	exit 0;
    }
    if ($cli_opts{'shortversion'}) { # Just the version number string.
	print $VERSION;
	exit 0;
    }
    my $stub = 0;
    if ($cli_opts{'stub'}) {
	$stub = 1;
    }
    if ($cli_opts{'html4tags'}) {	 # Use HTML tag style instead of XHTML
	$options{empty_element_suffix} = ">";
	$stub = -$stub;
    }
    if ($cli_opts{'deprecated'}) {	 # Allow <dir> and <menu> tags to pass through
	_SetAllowedTag("dir");
	_SetAllowedTag("menu");
    }
    $options{sanitize} = 1; # sanitize by default
    if ($cli_opts{'no-sanitize'}) {  # Do not sanitize
	$options{sanitize} = 0;
    }
    if ($cli_opts{'sanitize'}) {  # --sanitize always wins
	$options{sanitize} = 1;
    }
    $options{xmlcheck} = $options{sanitize} ? 2 : 0;
    if ($cli_opts{'no-validate-xml'}) {  # Do not validate XML
	$options{xmlcheck} = 0;
    }
    if ($cli_opts{'validate-xml'}) {  # Validate XML output
	$options{xmlcheck} = 1;
    }
    if ($cli_opts{'validate-xml-internal'}) {  # Validate XML output internally
	$options{xmlcheck} = 2;
    }
    die "--html4tags and --validate-xml are incompatible\n"
	if $cli_opts{'html4tags'} && $options{xmlcheck} == 1;
    die "--no-sanitize and --validate-xml-internal are incompatible\n"
	if !$options{'sanitize'} && $options{xmlcheck} == 2;
    if ($options{xmlcheck} == 1) {
	eval { require XML::Simple; 1 } and $hasxml = 1 or $hasxml_err = $@;
	eval { require XML::Parser; 1 } and $hasxmlp = 1 or $hasxmlp_err = $@ unless $hasxml;
	die "$hasxml_err$hasxmlp_err" unless $hasxml || $hasxmlp;
    }
    if ($cli_opts{'tabwidth'}) {
	my $tw = $cli_opts{'tabwidth'};
	die "invalid tab width (must be integer)\n" unless looks_like_number $tw;
	die "invalid tab width (must be >= 2 and <= 32)\n" unless $tw >= 2 && $tw <= 32;
	$options{tab_width} = int(0+$tw);
    }
    $options{base_prefix} = ""; 	# no base prefix by default
    if ($cli_opts{'base'}) {		# Use base prefix for fragment URLs
	$options{base_prefix} = $cli_opts{'base'};
    }
    if ($cli_opts{'htmlroot'}) {	 # Use URL prefix
	$options{url_prefix} = $cli_opts{'htmlroot'};
    }
    if ($cli_opts{'imageroot'}) {	 # Use image URL prefix
	$options{img_prefix} = $cli_opts{'imageroot'};
    }
    if (exists $cli_opts{'wiki'}) {	 # Enable wiki links
	my $wpat = $cli_opts{'wiki'};
	defined($wpat) or $wpat = "";
	my $wopt = "s";
	if ($wpat =~ /^(.*?)%\{([0-9A-Za-z]*)\}(.*)$/) {
	    $options{wikipat} = $1 . "%{}" . $3;
	    $wopt = $2;
	} else {
	    $options{wikipat} = $wpat . "%{}.html";
	}
	$options{wikiopt} = { map({$_ => 1} split(//,lc($wopt))) };
    }
    if ($cli_opts{'raw'}) {
	$raw = 1;
    }
    if ($cli_opts{'stylesheet'}) {  # Display the style sheet
	$options{show_styles} = 1;
    }
    if ($cli_opts{'no-stylesheet'}) {  # Do not display the style sheet
	$options{show_styles} = 0;
    }
    $options{show_styles} = 1 if $stub && !defined($options{show_styles});
    $options{tab_width} = 8 unless defined($options{tab_width});

    my $hdrf = sub {
	my $out = "";
	if ($stub > 0) {
	    $out .= <<'HTML5';
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta charset="utf-8" />
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
HTML5
	} elsif ($stub < 0) {
	    $out .= <<'HTML4';
<html>
<head>
<meta charset="utf-8">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
HTML4
	}
	if ($stub && ($options{title} || $options{h1})) {
	    my $title = $options{title};
	    defined($title) && $title ne "" or $title = $options{h1};
	    if (defined($title) && $title ne "") {
		$title =~ s/&/&amp;/g;
		$title =~ s/</&lt;/g;
		$out .= "<title>$title</title>\n";
	    }
	}
	if ($options{show_styles}) {
	    my $stylesheet = $g_style_sheet;
	    $stylesheet =~ s/%\(base\)/$g_style_prefix/g;
	    $out .= $stylesheet;
	}
	if ($stub) {
	    $out .= "</head>\n<body style=\"text-align:center\">\n" .
		"<div style=\"display:inline-block;text-align:left;max-width:42pc\">\n";
	}
	$out;
    };

    #### Process incoming text: ###########################
    my ($didhdr, $hdr, $result, $ftr) = (0, "", "", "");
    @ARGV or push(@ARGV, "-");
    foreach (@ARGV) {
	my ($fh, $contents, $oneresult);
	$_ eq "-" or open $fh, '<', $_ or fauxdie "could not open \"$_\": $!\n";
	{
	    local $/; # Slurp the whole file
	    $_ eq "-" and $contents = <STDIN>;
	    $_ ne "-" and $contents = <$fh>;
	}
	defined($contents) or fauxdie "could not read \"$_\": $!\n";
	$_ eq "-" or close($fh);
	$oneresult = $raw ? ProcessRaw($contents, \%options) : Markdown($contents, \%options);
	$oneresult =~ s/\s+$//os;
	if ($oneresult ne "") {
	    if (!$didhdr && !$raw) {
		$hdr = &$hdrf();
		$didhdr = 1;
	    }
	    $result .= $oneresult . "\n";
	}
    }
    $hdr = &$hdrf() unless $didhdr || $raw;
    $ftr = "</div>\n</body>\n</html>\n" if $stub && !$raw;
    if ($options{xmlcheck} == 1) {
	my ($good, $errs);
	if ($stub && !$raw) {
	    ($good, $errs) = _xmlcheck($hdr.$result.$ftr);
	} else {
	    ($good, $errs) = _xmlcheck("<div>".$result."</div>");
	}
	$good or die $errs;
    }
    print $hdr, $result, $ftr;

    exit 0;
}


sub _xmlcheck {
	my $text = shift;
	my ($good, $errs);
	($hasxml ? eval { XML::Simple::XMLin($text, KeepRoot => 1) && 1 } :
	 eval {
		my $p = XML::Parser->new(Style => 'Tree', ErrorContext => 1);
		$p->parse($text) && 1;
	}) and $good = 1 or $errs = _trimerr($@);
	($good, $errs);
}


sub _trimerr {
	my $err = shift;
	1 while $err =~ s{\s+at\s+\.?/[^,\s\n]+\sline\s+[0-9]+\.?(\n|$)}{$1}is;
	$err =~ s/\s+$//os;
	$err . "\n";
}


sub _PrepareInput {
    my $input = shift;
    defined $input or $input = "";
    {
	use bytes;
	$input =~ s/[\x00-\x08\x0B\x0E-\x1F\x7F]+//gso;
    }
    my $output;
    if (Encode::is_utf8($input) || utf8::decode($input)) {
	$output = $input;
    } else {
	$output = $encoder->decode($input, Encode::FB_DEFAULT);
    }
    # Standardize line endings:
    $output =~ s{\r\n}{\n}g;  # DOS to Unix
    $output =~ s{\r}{\n}g;    # Mac to Unix
    return $output;
}


sub ProcessRaw {
    my $text = _PrepareInput(shift);

    %opt = (
	empty_element_suffix	=> $g_empty_element_suffix,
    );
    my %args = ();
    if (ref($_[0]) eq "HASH") {
	%args = %{$_[0]};
    } else {
	%args = @_;
    }
    while (my ($k,$v) = each %args) {
	$opt{$k} = $v;
    }
    $opt{xmlcheck} = 0 unless looks_like_number($opt{xmlcheck});

    # Sanitize all '<'...'>' tags if requested
    $text = _SanitizeTags($text, $opt{xmlcheck} == 2) if $opt{sanitize};

    utf8::encode($text);
    return $text;
}


sub Markdown {
#
# Primary function. The order in which other subs are called here is
# essential. Link and image substitutions need to happen before
# _EscapeSpecialChars(), so that any *'s or _'s in the <a>
# and <img> tags get encoded.
#
    my $text = _PrepareInput(shift);

    # Any remaining arguments after the first are options; either a single
    # hashref or a list of name, value paurs.
    %opt = (
	# set initial defaults
	style_prefix		=> $g_style_prefix,
	empty_element_suffix	=> $g_empty_element_suffix,
	tab_width		=> $g_tab_width,
	indent_width		=> $g_indent_width,
	url_prefix		=> "", # Prefixed to non-absolute URLs
	img_prefix		=> "", # Prefixed to non-absolute image URLs
    );
    my %args = ();
    if (ref($_[0]) eq "HASH") {
	%args = %{$_[0]};
    } else {
	%args = @_;
    }
    while (my ($k,$v) = each %args) {
	$opt{$k} = $v;
    }
    $opt{xmlcheck} = 0 unless looks_like_number($opt{xmlcheck});

    # Clear the globals. If we don't clear these, you get conflicts
    # from other articles when generating a page which contains more than
    # one article (e.g. an index page that shows the N most recent
    # articles):
    %g_urls = ();
    %g_titles = ();
    %g_anchors = ();
    %g_block_ids = ();
    %g_code_block_ids = ();
    %g_html_blocks = ();
    %g_code_blocks = ();
    $g_list_level = 0;

    # Make sure $text ends with a couple of newlines:
    $text .= "\n\n";

    # Handle backticks-delimited code blocks
    $text = _HashBTCodeBlocks($text);

    # Convert all tabs to spaces.
    $text = _DeTab($text);

    # Strip any lines consisting only of spaces.
    # This makes subsequent regexen easier to write, because we can
    # match consecutive blank lines with /\n+/ instead of something
    # contorted like / *\n+/ .
    $text =~ s/^ +$//mg;

    # Turn block-level HTML blocks into hash entries
    $text = _HashHTMLBlocks($text);

    # Strip link definitions, store in hashes.
    $text = _StripLinkDefinitions($text);

    $text = _RunBlockGamut($text, 1);

    # Remove indentation markers
    $text =~ s/\027+//gs;

    # Unhashify code blocks
    $text =~ s/(\025\d+\026)/$g_code_blocks{$1}/g;

    $text = _UnescapeSpecialChars($text);

    $text .= "\n" unless $text eq "";

    # Sanitize all '<'...'>' tags if requested
    $text = _SanitizeTags($text, $opt{xmlcheck} == 2) if $opt{sanitize};

    utf8::encode($text);
    if (defined($opt{h1}) && $opt{h1} ne "" && ref($_[0]) eq "HASH") {
	utf8::encode($opt{h1});
	${$_[0]}{h1} = $opt{h1}
    }
    return $text;
}


sub _HashBTCodeBlocks {
#
#   Process Markdown backticks (```) delimited code blocks
#
    my $text = shift;
    my $less_than_indent = $opt{indent_width} - 1;

    $text =~ s{
	    (?:(?<=\n)|\A)
		([ ]{0,$less_than_indent})``(`+)[ \t]*(?:([\w.+-]+[#]?)[ \t]*)?\n
	     ( # $4 = the code block -- one or more lines, starting with ```
	      (?:
		.*\n+
	      )+?
	     )
	    # and ending with ``` or end of document
	    (?:(?:[ ]{0,$less_than_indent}``\2[ \t]*(?:\n|\Z))|\Z)
	}{
	    # $2 contains syntax highlighting to use if defined
	    my $leadsp = length($1);
	    my $codeblock = $4;
	    $codeblock =~ s/[ \t]+$//mg; # trim trailing spaces on lines
	    $codeblock = _DeTab($codeblock, 8, $leadsp); # physical tab stops are always 8
	    $codeblock =~ s/\A\n+//; # trim leading newlines
	    $codeblock =~ s/\s+\z//; # trim trailing whitespace
	    $codeblock = _EncodeCode($codeblock); # or run highlighter here
	    $codeblock = "<div class=\"$opt{style_prefix}code-bt\"><pre style=\"display:none\"></pre><pre><code>"
		. $codeblock . "\n</code></pre></div>";

	    my $key = block_id($codeblock);
	    $g_html_blocks{$key} = $codeblock;
	    "\n\n" . $key . "\n\n";
	}egmx;

    return $text;
}


sub _StripLinkDefinitions {
#
# Strips link definitions from text, stores the URLs and titles in
# hash references.
#
    my $text = shift;
    my $less_than_indent = $opt{indent_width} - 1;

    # Link defs are in the form: ^[id]: url "optional title"
    while ($text =~ s{
			^[ ]{0,$less_than_indent}\[(.+)\]: # id = $1
			  [ ]*
			  \n?		    # maybe *one* newline
			  [ ]*
			<?((?:\S(?:\\\n\s*[^\s"(])?)+?)>? # url = $2
			  [ ]*
			  \n?		    # maybe one newline
			  [ ]*
			(?:
			    (?<=\s)	    # lookbehind for whitespace
			    (?:(['"])|(\()) # title quote char
			    (.+?)	    # title = $5
			    (?(4)\)|\3)	    # match same quote
			    [ ]*
			)?  # title is optional
			(?:\n+|\Z)
		    }
		    {}mx) {
	my $id = _strip(lc $1); # Link IDs are case-insensitive
	my $url = $2;
	my $title = _strip($5);
	$url =~ s/\\\n\s*//gs;
	if ($id ne "") {
		# These values always get passed through _MakeATag or _MakeIMGTag later
		$g_urls{$id} = $url;
		if (defined($title) && $title ne "") {
		    $g_titles{$id} = $title;
		}
	}
    }

    return $text;
}

my ($block_tags_a, $block_tags_b);
BEGIN {
    $block_tags_a = qr/p|div|h[1-6]|blockquote|pre|table|dl|ol|ul|script|noscript|form|fieldset|iframe|math|ins|del/io;
    $block_tags_b = qr/p|div|h[1-6]|blockquote|pre|table|dl|ol|ul|script|noscript|form|fieldset|iframe|math/io;
}

sub _HashHTMLBlocks {
    my $text = shift;
    my $less_than_indent = $opt{indent_width} - 1;
    my $idt = "\027" x $g_list_level;

    # Hashify HTML blocks:
    # We only want to do this for block-level HTML tags, such as headers,
    # lists, and tables. That's because we still want to wrap <p>s around
    # "paragraphs" that are wrapped in non-block-level tags, such as anchors,
    # phrase emphasis, and spans. The list of tags we're looking for is
    # hard-coded:

    # First, look for nested blocks, e.g.:
    #   <div>
    #       <div>
    #       tags for inner block must be indented.
    #       </div>
    #   </div>
    #
    # The outermost tags must start at the left margin for this to match, and
    # the inner nested divs must be indented.
    # We need to do this before the next, more liberal match, because the next
    # match will start at the first `<div>` and stop at the first `</div>`.
    $text =~ s{
		(			# save in $1
		    ^			# start of line (with /m)
		    ((?:\Q$idt\E)?)	# optional lead in = $2
		    <($block_tags_a)	# start tag = $3
		    \b			# word break
		    (?:.*\n)*?		# any number of lines, minimally matching
		    \2</\3>		# the matching end tag
		    [ ]*		# trailing spaces
		    (?=\n+|\Z) # followed by a newline or end of document
		)
	    }{
		my $key = block_id($1);
		$g_html_blocks{$key} = $1;
		"\n\n" . $key . "\n\n";
	    }eigmx;


    #
    # Now match more liberally, simply from `\n<tag>` to `</tag>\n`
    #
    $text =~ s{
		(			# save in $1
		    ^			# start of line (with /m)
		    (?:\Q$idt\E)?	# optional lead in
		    <($block_tags_b)	# start tag = $2
		    \b			# word break
		    (?:.*\n)*?		# any number of lines, minimally matching
		    .*</\2>		# the matching end tag
		    [ ]*		# trailing spaces
		    (?=\n+|\Z) # followed by a newline or end of document
		)
	    }{
		my $key = block_id($1);
		$g_html_blocks{$key} = $1;
		"\n\n" . $key . "\n\n";
	    }eigmx;
    # Special case just for <hr />. It was easier to make a special case than
    # to make the other regex more complicated.
    $text =~ s{
		(?:
		    (?<=\n)	    # Starting after end of line
		    |		    # or
		    \A		    # the beginning of the doc
		)
		(			# save in $1
		    [ ]{0,$less_than_indent}
		    <(?:hr)		# start tag
		    \b			# word break
		    (?:[^<>])*?		#
		    /?>			# the matching end tag
		    [ ]*
		    (?=\n{1,}|\Z)	# followed by end of line or end of document
		)
	    }{
		my $key = block_id($1);
		$g_html_blocks{$key} = $1;
		"\n\n" . $key . "\n\n";
	    }eigx;

    # Special case for standalone HTML comments:
    $text =~ s{
		(?:
		    (?<=\n\n)	    # Starting after a blank line
		    |		    # or
		    \A\n?	    # the beginning of the doc
		)
		(		    # save in $1
		    [ ]{0,$less_than_indent}
		    (?s:
			<!--
			(?:[^-]|(?:-(?!-)))*
			-->
		    )
		    [ ]*
		    (?=\n{1,}|\Z)   # followed by end of line or end of document
		)
	    }{
		my $key = block_id($1);
		$g_html_blocks{$key} = $1;
		"\n\n" . $key . "\n\n";
	    }egx;


    return $text;
}


sub _RunBlockGamut {
#
# These are all the transformations that form block-level
# tags like paragraphs, headers, and list items.
#
    my ($text, $anchors) = @_;

    $text = _DoHeaders($text, $anchors);

    # Do Horizontal Rules:
    $text =~ s{^ {0,3}\*(?: {0,2}\*){2,}[ ]*$}{\n<hr$opt{empty_element_suffix}\n}gm;
    $text =~ s{^ {0,3}\_(?: {0,2}\_){2,}[ ]*$}{\n<hr$opt{empty_element_suffix}\n}gm;
    $text =~ s{^ {0,3}\-(?: {0,2}\-){2,}[ ]*$}{\n<hr$opt{empty_element_suffix}\n}gm;

    $text = _DoListsAndBlocks($text);

    $text = _DoTables($text);

    # We already ran _HashHTMLBlocks() before, in Markdown(), but that
    # was to escape raw HTML in the original Markdown source. This time,
    # we're escaping the markup we've just created, so that we don't wrap
    # <p> tags around block-level tags.
    $text = _HashHTMLBlocks($text);

    $text = _FormParagraphs($text);

    return $text;
}


sub _DoListBlocks {
    return _DoBlockQuotes(_DoCodeBlocks($_[0])) if $_[0] ne "";
}


sub _RunSpanGamut {
#
# These are all the transformations that occur *within* block-level
# tags like paragraphs, headers, and list items.
#
    my $text = shift;

    $text = _DoCodeSpans($text);

    $text = _EscapeSpecialChars($text);

    # Process anchor and image tags. Images must come first,
    # because ![foo][f] looks like an anchor.
    $text = _DoImages($text);
    $text = _DoAnchors($text);

    # Make links out of things like `<http://example.com/>`
    # Must come after _DoAnchors(), because you can use < and >
    # delimiters in inline links like [this](<url>).
    $text = _DoAutoLinks($text);

    $text = _EncodeAmpsAndAngles($text);

    $text = _DoItalicsAndBoldAndStrike($text);

    # Do hard breaks:
    $text =~ s/ {2,}\n/<br$opt{empty_element_suffix}\n/g;

    return $text;
}


sub _EscapeSpecialChars {
    my $text = shift;
    my $tokens ||= _TokenizeHTML($text);

    $text = ''; # rebuild $text from the tokens
#   my $in_pre = 0;  # Keep track of when we're inside <pre> or <code> tags.
#   my $tags_to_skip = qr!<(/?)(?:pre|code|kbd|script|math)[\s>]!;

    foreach my $cur_token (@$tokens) {
	if ($cur_token->[0] eq "tag") {
	    # Within tags, encode *, _ and ~ so they don't conflict
	    # with their use in Markdown for italics and strong.
	    # We're replacing each such character with its
	    # corresponding block id value; this is likely
	    # overkill, but it should prevent us from colliding
	    # with the escape values by accident.
	    $cur_token->[1] =~ s!([*_~])!$g_escape_table{$1}!g;
	    $text .= $cur_token->[1];
	} else {
	    my $t = $cur_token->[1];
	    $t = _EncodeBackslashEscapes($t);
	    $text .= $t;
	}
    }
    return $text;
}


sub _ProcessWikiLink {
    my ($link_text, $link_loc) = @_;
    if (defined($link_loc) &&
	($link_loc =~ m{^#\S*$} || $link_loc =~ m{^(?:http|ftp)s?://\S+$}i)) {
	# Return the new link
	return _MakeATag(_FindFragmentMatch($link_loc), $link_text);
    }
    if (!defined($link_loc) &&
	($link_loc = _strip($link_text)) =~ m{^(?:http|ftp)s?://\S+$}i) {
	# Return the new link
	return _MakeATag($link_loc, $link_text);
    }
    return undef if $link_loc eq "" || $link_text eq "";
    if ($link_loc =~ /^[A-Za-z][A-Za-z0-9+.-]*:/os) {
	# Unrecognized scheme
	return undef;
    }
    if ($opt{wikipat}) {
	my $o = $opt{wikiopt};
	my $qsfrag = "";
	my $base = $link_loc;
	if ($link_loc =~ /^(.*?)([?#].*)$/os) {
	    ($base, $qsfrag) = ($1, $2);
	}
	$base = _wxform($base);
	my $result = $opt{wikipat};
	$result =~ s/%\{\}/$base/;
	if ($qsfrag =~ /^([^#]*)(#.+)$/os) {
	    my ($q,$f) = ($1,$2);
	    #$f = _wxform($f) if $f =~ / /;
	    $qsfrag = $q . $f;
	}
	$result .= $qsfrag;
	{
	    use bytes;
	    $result =~ s/%(?![0-9A-Fa-f]{2})/%25/sog;
	    if ($o->{r}) {
		$result =~
		s/([\x00-\x1F <>"{}|\\^`x7F])/sprintf("%%%02X",ord($1))/soge;
	    } else {
		$result =~
		s/([\x00-\x1F <>"{}|\\^`\x7F-\xFF])/sprintf("%%%02X",ord($1))/soge;
	    }
	    $result =~ s/(%(?![0-9A-F]{2})[0-9A-Fa-f]{2})/uc($1)/soge;
	}
	# Return the new link
	return _MakeATag($result, $link_text);
    }
    # leave it alone
    return undef;
}


sub _wxform {
    my $w = shift;
    my $o = $opt{wikiopt};
    $w =~ s{[.][^./]*$}{} if $o->{s};
    $w =~ tr{/}{ } if $o->{f};
    $w =~ s{/+}{/}gos if !$o->{f} && !$o->{v};
    if ($o->{d}) {
	$w =~ tr{ }{-};
	$w =~ s/-+/-/gos unless $o->{v};
    } else {
	$w =~ tr{ }{_};
	$w =~ s/_+/_/gos unless $o->{v};
    }
    $w = uc($w) if $o->{u};
    $w = lc($w) if $o->{l};
    return $w;
}


# Return a suitably encoded <a...> tag string
# On input NONE of $url, $text or $title should be xmlencoded
# but $url should already be url-encoded if needed, but NOT g_escape_table'd
sub _MakeATag {
    my ($url, $text, $title) = @_;
    defined($url) or $url="";
    defined($text) or $text="";
    defined($title) or $title="";

    $url =~ m"^#" and $url = $opt{base_prefix} . $url;
    my $result = $g_escape_table{'<'}."a href=\"" . _EncodeAttText($url) . "\"";
    $title = _strip($title);
    $text =~ s{<(/?a)}{&lt;$1}sogi;
    $text = _DoItalicsAndBoldAndStrike($text);
    # We've got to encode any of these remaining to avoid
    # conflicting with other italics, bold and strike through.
    $text =~ s!([*_~])!$g_escape_table{$1}!g;
    $result .= " title=\"" . _EncodeAttText($title) . "\"" if $title ne "";
    return $result . $g_escape_table{'>'} .
	$text . $g_escape_table{'<'}."/a".$g_escape_table{'>'};
}


sub _DoAnchors {
#
# Turn Markdown link shortcuts into XHTML <a> tags.
#
    my $text = shift;

    #
    # First, handle wiki-style links: [[wiki style link]]
    #
    $text =~ s{
	(		    # wrap whole match in $1
	  \[\[
	    ($g_nested_brackets) # link text and id = $2
	  \]\]
	)
    }{
	my $result;
	my $whole_match = $1;
	my $link_text	= $2;
	my $link_loc    = undef;

	if ($link_text =~ /^(.*)\|(.*)$/s) {
	    $link_text = $1;
	    $link_loc = _strip($2);
	}

	$result = _ProcessWikiLink($link_text, $link_loc);
	defined($result) or $result = $whole_match;
	$result;
    }xsge;

    #
    # Next, handle reference-style links: [link text] [id]
    #
    $text =~ s{
	(		    # wrap whole match in $1
	  \[
	    ($g_nested_brackets) # link text = $2
	  \]

	  [ ]?		    # one optional space
	  (?:\n[ ]*)?	    # one optional newline followed by spaces

	  \[
	    ($g_nested_brackets) # id = $3
	  \]
	)
    }{
	my $result;
	my $whole_match = $1;
	my $link_text	= $2;
	my $link_id	= $3;

	$link_id ne "" or $link_id = $link_text; # for shortcut links like [this][].
	$link_id = _strip(lc $link_id);

	if (defined($g_urls{$link_id}) || defined($g_anchors{$link_id})) {
	    my $url = $g_urls{$link_id};
	    $url = defined($url) ? _PrefixURL($url) : $g_anchors{$link_id};
	    $link_text = '[' . $link_text . ']' if $link_text =~ /^\d{1,3}$/;
	    $result = _MakeATag($url, $link_text, $g_titles{$link_id});
	}
	else {
	    $result = $whole_match;
	}
	$result;
    }xsge;

    #
    # Subsequently, inline-style links: [link text](url "optional title")
    #
    $text =~ s{
	(		# wrap whole match in $1
	  \[
	    ($g_nested_brackets) # link text = $2
	  \]
	  \(		# literal paren
	    ($g_nested_parens) # href and optional title = $3
	  \)
	)
    }{
	#my $result;
	my $whole_match = $1;
	my $link_text	= $2;
	my ($url, $title) = _SplitUrlTitlePart($3);

	if (defined($url)) {
	    $url = _FindFragmentMatch($url);
	    $link_text = '[' . $link_text . ']' if $link_text =~ /^\d{1,3}$/;
	    _MakeATag(_PrefixURL($url), $link_text, $title);
	} else {
	    # The href/title part didn't match the pattern
	    $whole_match;
	}
    }xsge;

    #
    # Finally, handle reference-style implicit shortcut links: [link text]
    #
    $text =~ s{
	(		    # wrap whole match in $1
	  \[
	    ($g_nested_brackets) # link text = $2
	  \]
	)
    }{
	my $result;
	my $whole_match = $1;
	my $link_text	= $2;
	my $link_id	= _strip(lc $2);

	if (defined($g_urls{$link_id}) || defined($g_anchors{$link_id})) {
	    my $url = $g_urls{$link_id};
	    $url = defined($url) ? _PrefixURL($url) : $g_anchors{$link_id};
	    $link_text = '[' . $link_text . ']' if $link_text =~ /^\d{1,3}$/;
	    $result = _MakeATag($url, $link_text, $g_titles{$link_id});
	}
	else {
	    $result = $whole_match;
	}
	$result;
    }xsge;

    return $text;
}


sub _PeelWrapped {
    defined($_[0]) or return undef;
    if (substr($_[0],0,1) eq "(") {
	return substr($_[0], 1, length($_[0]) - (substr($_[0], -1, 1) eq ")" ? 2 : 1));
    }
    return $_[0];
}


sub _SplitUrlTitlePart {
    return ("", undef) if $_[0] =~ m{^\s*$}; # explicitly allowed
    my $u = $_[0];
    $u =~ s/^\s*(['\042])/# $1/;
    if ($u =~ m{
	^		# match beginning
	\s*?
	<?([^\s'\042]\S*?)>? # URL = $1
	(?:		# optional grouping
	  \s+		# must be distinct from URL
	  (['\042]?)	# quote char = $2
	  (.*?)		# Title = $3
	  \2?		# matching quote
	)?		# title is optional
	\s*
	\z		# match end
    }osx) {
	return (undef, undef) if $_[1] && ($1 eq "" || $1 eq "#");
	return (_PeelWrapped($1), $2 ? $3 : _PeelWrapped($3));
    } else {
	return (undef, undef);
    }
}


sub _FindFragmentMatch {
    my $url = shift;
    if (defined($url) && $url =~ /^#\S/) {
	# try very hard to find a match
	my $idbase = _strip(lc(substr($url, 1)));
	my $idbase0 = $idbase;
	my $id = _MakeAnchorId($idbase);
	if (defined($g_anchors_id{$id})) {
	    $url = $g_anchors_id{$id};
	} else {
	    $idbase =~ s/-/_/gs;
	    $id = _MakeAnchorId($idbase);
	    if (defined($g_anchors_id{$id})) {
		$url = $g_anchors_id{$id};
	    } else {
		$id = _MakeAnchorId($idbase0, 1);
		if (defined($g_anchors_id{$id})) {
		    $url = $g_anchors_id{$id};
		} else {
		    $id = _MakeAnchorId($idbase, 1);
		    if (defined($g_anchors_id{$id})) {
			$url = $g_anchors_id{$id};
		    }
		}
	    }
	}
    }
    return $url;
}


# Return a suitably encoded <img...> tag string
# On input NONE of $url, $alt or $title should be xmlencoded
# but $url should already be url-encoded if needed, but NOT g_escape_table'd
sub _MakeIMGTag {
    my ($url, $alt, $title) = @_;
    defined($url) or $url="";
    defined($alt) or $alt="";
    defined($title) or $title="";
    return "" unless $url ne "";

    my $result = $g_escape_table{'<'}."img src=\"" . _EncodeAttText($url) . "\"";
    my ($w, $h) = (0, 0);
    ($alt, $title) = (_strip($alt), _strip($title));
    if ($title =~ /^(.*)\(([1-9][0-9]*)[xX]([1-9][0-9]*)\)$/os) {
	($title, $w, $h) = (_strip($1), $2, $3);
    } elsif ($title =~ /^(.*)\(\?[xX]([1-9][0-9]*)\)$/os) {
	($title, $h) = (_strip($1), $2);
    } elsif ($title =~ /^(.*)\(([1-9][0-9]*)[xX]\?\)$/os) {
	($title, $w) = (_strip($1), $2);
    }
    $result .= " alt=\"" . _EncodeAttText($alt) . "\"" if $alt ne "";
    $result .= " width=\"$w\"" if $w != 0;
    $result .= " height=\"$h\"" if $h != 0;
    $result .= " title=\"" . _EncodeAttText($title) . "\"" if $title ne "";
    $result .= " /" unless $opt{empty_element_suffix} eq ">";
    $result .= $g_escape_table{'>'};
    return $result;
}


sub _DoImages {
#
# Turn Markdown image shortcuts into <img> tags.
#
    my $text = shift;

    #
    # First, handle reference-style labeled images: ![alt text][id]
    #
    $text =~ s{
	(		# wrap whole match in $1
	  !\[
	    ($g_nested_brackets) # alt text = $2
	  \]

	  [ ]?		# one optional space
	  (?:\n[ ]*)?	# one optional newline followed by spaces

	  \[
	    ($g_nested_brackets) # id = $3
	  \]

	)
    }{
	my $result;
	my $whole_match = $1;
	my $alt_text	= $2;
	my $link_id	= $3;

	$link_id ne "" or $link_id = $alt_text; # for shortcut links like ![this][].
	$link_id = _strip(lc $link_id);

	if (defined $g_urls{$link_id}) {
	    $result = _MakeIMGTag(
		_PrefixURL($g_urls{$link_id}), $alt_text, $g_titles{$link_id});
	}
	else {
	    # If there's no such link ID, leave intact:
	    $result = $whole_match;
	}

	$result;
    }xsge;

    #
    # Next, handle inline images:  ![alt text](url "optional title")
    # Don't forget: encode * and _

    $text =~ s{
	(		# wrap whole match in $1
	  !\[
	    ($g_nested_brackets) # alt text = $2
	  \]
	  \(		# literal paren
	    ($g_nested_parens) # src and optional title = $3
	  \)
	)
    }{
	my $whole_match = $1;
	my $alt_text	= $2;
	my ($url, $title) = _SplitUrlTitlePart($3, 1);
	defined($url) ?  _MakeIMGTag(_PrefixURL($url), $alt_text, $title) : $whole_match;
    }xsge;

    #
    # Finally, handle reference-style implicitly labeled links: ![alt text]
    #
    $text =~ s{
	(		# wrap whole match in $1
	  !\[
	    ($g_nested_brackets) # alt text = $2
	  \]
	)
    }{
	my $result;
	my $whole_match = $1;
	my $alt_text	= $2;
	my $link_id	= lc(_strip($alt_text));

	if (defined $g_urls{$link_id}) {
	    $result = _MakeIMGTag(
		_PrefixURL($g_urls{$link_id}), $alt_text, $g_titles{$link_id});
	}
	else {
	    # If there's no such link ID, leave intact:
	    $result = $whole_match;
	}

	$result;
    }xsge;

    return $text;
}

sub _EncodeAttText {
    my $text = shift;
    defined($text) or return undef;
    $text = _HTMLEncode(_strip($text));
    # We've got to encode these to avoid conflicting
    # with italics, bold and strike through.
    $text =~ s!([*_~:])!$g_escape_table{$1}!g;
    return $text;
}


sub _MakeAnchorId {
    use bytes;
    my ($link, $strip) = @_;
    $link = lc($link);
    if ($strip) {
	$link =~ s/\s+/_/gs;
	$link =~ tr/-a-z0-9_//cd;
    } else {
	$link =~ tr/-a-z0-9_/_/cs;
    }
    return '' unless $link ne '';
    $link = "_".$link."_";
    $link =~ s/__+/_/gs;
    $link = "_".md5_hex($link)."_" if length($link) > 66;
    return $link;
}


sub _GetNewAnchorId {
    my $link = _strip(lc(shift));
    return '' if $link eq "" || defined($g_anchors{$link});
    my $id = _MakeAnchorId($link);
    return '' unless $id;
    $g_anchors{$link} = '#'.$id;
    $g_anchors_id{$id} = $g_anchors{$link};
    if ($id =~ /-/) {
	my $id2 = $id;
	$id2 =~ s/-/_/gs;
	$id2 =~ s/__+/_/gs;
	defined($g_anchors_id{$id2}) or $g_anchors_id{$id2} = $g_anchors{$link};
    }
    my $idd = _MakeAnchorId($link, 1);
    if ($idd) {
	defined($g_anchors_id{$idd}) or $g_anchors_id{$idd} = $g_anchors{$link};
	if ($idd =~ /-/) {
	    my $idd2 = $idd;
	    $idd2 =~ s/-/_/gs;
	    $idd2 =~ s/__+/_/gs;
	    defined($g_anchors_id{$idd2}) or $g_anchors_id{$idd2} = $g_anchors{$link};
	}
    }
    $id;
}


sub _DoHeaders {
    my ($text, $anchors) = @_;
    my $h1;
    my $geth1 = $anchors && !defined($opt{h1}) ? sub {
	return unless !defined($h1);
	my $h = shift;
	$h =~ s/^\s+//;
	$h =~ s/\s+$//;
	$h =~ s/\s+/ /g;
	$h1 = $h if $h ne "";
    } : sub {};

    # atx-style headers:
    #   # Header 1
    #   ## Header 2
    #   ## Header 2 with closing hashes ##
    #   ...
    #   ###### Header 6
    #
    $text =~ s{
	    ^(\#{1,6})	# $1 = string of #'s
	    [ ]*
	    ((?:(?:(?<![#])[^\s]|[^#\s]).*?)?) # $2 = Header text
	    [ ]*
	    \n+
	}{
	    my $h_level = length($1);
	    my $h = $2;
	    $h =~ s/#+$//;
	    $h =~ s/\s+$//;
	    my $id = $h eq "" ? "" : _GetNewAnchorId($h);
	    &$geth1($h) if $h_level == 1 && $h ne "";
	    $id = " id=\"$id\"" if $id ne "";
	    "<h$h_level$id>" . _RunSpanGamut($h) . "</h$h_level>\n\n";
	}egmx;

    # Setext-style headers:
    #     Header 1
    #     ========
    #
    #     Header 2
    #     --------
    #
    #     Header 3
    #     ~~~~~~~~
    #
    $text =~ s{ ^(?:=+[ ]*\n)?[ ]*(.+?)[ ]*\n=+[ ]*\n+ }{
	my $h = $1;
	my $id = _GetNewAnchorId($h);
	&$geth1($h);
	$id = " id=\"$id\"" if $id ne "";
	"<h1$id>" . _RunSpanGamut($h) . "</h1>\n\n";
    }egmx;

    $text =~ s{ ^(?:-+[ ]*\n)?[ ]*(.+?)[ ]*\n-+[ ]*\n+ }{
	my $h = $1;
	my $id = _GetNewAnchorId($h);
	$id = " id=\"$id\"" if $id ne "";
	"<h2$id>" . _RunSpanGamut($h) . "</h2>\n\n";
    }egmx;

    $text =~ s{ ^(?:~+[ ]*\n)?[ ]*(.+?)[ ]*\n~+[ ]*\n+ }{
	my $h = $1;
	my $id = _GetNewAnchorId($h);
	$id = " id=\"$id\"" if $id ne "";
	"<h3$id>" . _RunSpanGamut($h) . "</h3>\n\n";
    }egmx;

    $opt{h1} = $h1 if defined($h1) && $h1 ne "";
    return $text;
}


my ($marker_ul, $marker_ol, $marker_any, $roman_numeral, $greek_lower);
BEGIN {
    # Re-usable patterns to match list item bullets and number markers:
    $roman_numeral = qr/(?:
	[IiVvXx]|[Ii]{2,3}|[Ii][VvXx]|[VvXx][Ii]{1,3}|[Xx][Vv][Ii]{0,3}|
	[Xx][Ii][VvXx]|[Xx]{2}[Ii]{0,3}|[Xx]{2}[Ii]?[Vv]|[Xx]{2}[Vv][Ii]{1,2})/ox;
    $greek_lower = qr/(?:[\x{03b1}-\x{03c9}])/o;
    $marker_ul  = qr/[*+-]/o;
    $marker_ol  = qr/(?:\d+|[A-Za-z]|$roman_numeral|$greek_lower)[.\)]/o;
    $marker_any = qr/(?:$marker_ul|$marker_ol)/o;
}


sub _GetListMarkerType {
    my ($list_type, $list_marker, $last_marker) = @_;
    return "" unless $list_type && $list_marker && lc($list_type) eq "ol";
    my $last_marker_type = '';
    $last_marker_type = _GetListMarkerType($list_type, $last_marker)
	if defined($last_marker) &&
	    # these are roman unless $last_marker type case matches and is 'a' or 'A'
	    $list_marker =~ /^[IiVvXx][.\)]?$/;
    return "I" if $list_marker =~ /^[IVX]/ && $last_marker_type ne 'A';
    return "i" if $list_marker =~ /^[ivx]/ && $last_marker_type ne 'a';
    return "A" if $list_marker =~ /^[A-Z]/;
    return "a" if $list_marker =~ /^[a-z]/ || $list_marker =~ /^$greek_lower/o;
    return "1";
}


sub _GetListItemTypeClass {
    my ($list_type, $list_marker, $last_marker) = @_;
    my $list_marker_type = _GetListMarkerType($list_type, $list_marker, $last_marker);
    my $ans = &{sub{
	return "" unless length($list_marker) >= 2 && $list_marker_type =~ /^[IiAa1]$/;
	return "lower-greek" if $list_marker_type eq "a" && $list_marker =~ /^$greek_lower/o;
	return "" unless $list_marker =~ /\)$/;
	return "upper-roman" if $list_marker_type eq "I";
	return "lower-roman" if $list_marker_type eq "i";
	return "upper-alpha" if $list_marker_type eq "A";
	return "lower-alpha" if $list_marker_type eq "a";
	return "decimal";
    }};
    return ($list_marker_type, $ans);
}


my %_roman_number_table;
BEGIN {
    %_roman_number_table = (
	i	=>  1,
	ii	=>  2,
	iii	=>  3,
	iv	=>  4,
	v	=>  5,
	vi	=>  6,
	vii	=>  7,
	viii	=>  8,
	ix	=>  9,
	x	=> 10,
	xi	=> 11,
	xii	=> 12,
	xiii	=> 13,
	xiv	=> 14,
	xv	=> 15,
	xvi	=> 16,
	xvii	=> 17,
	xviii	=> 18,
	xix	=> 19,
	xx	=> 20,
	xxi	=> 21,
	xxii	=> 22,
	xxiii	=> 23,
	xxiv	=> 24,
	xxv	=> 25,
	xxvi	=> 26,
	xxvii	=> 27
    );
}


# Necessary because ς and σ are the same value grrr
my %_greek_number_table;
BEGIN {
    %_greek_number_table = (
	"\x{03b1}" =>  1, # α
	"\x{03b2}" =>  2, # β
	"\x{03b3}" =>  3, # γ
	"\x{03b4}" =>  4, # δ
	"\x{03b5}" =>  5, # ε
	"\x{03b6}" =>  6, # ζ
	"\x{03b7}" =>  7, # η
	"\x{03b8}" =>  8, # θ
	"\x{03b9}" =>  9, # ι
	"\x{03ba}" => 10, # κ
	"\x{03bb}" => 11, # λ
	#"\x{00b5}"=> 12, # µ is "micro" not "mu"
	"\x{03bc}" => 12, # μ
	"\x{03bd}" => 13, # ν
	"\x{03be}" => 14, # ξ
	"\x{03bf}" => 15, # ο
	"\x{03c0}" => 16, # π
	"\x{03c1}" => 17, # ρ
	"\x{03c2}" => 18, # ς
	"\x{03c3}" => 18, # σ
	"\x{03c4}" => 19, # τ
	"\x{03c5}" => 20, # υ
	"\x{03c6}" => 21, # φ
	"\x{03c7}" => 22, # χ
	"\x{03c8}" => 23, # ψ
	"\x{03c9}" => 24  # ω
    );
}


sub _GetMarkerIntegerNum {
    my ($list_marker_type, $marker_val) = @_;
    my $ans = &{sub{
	return 0 + $marker_val if $list_marker_type eq "1";
	$list_marker_type = lc($list_marker_type);
	return $_greek_number_table{$marker_val}
	    if $list_marker_type eq "a" &&
	    defined($_greek_number_table{$marker_val});
	$marker_val = lc($marker_val);
	return ord($marker_val) - ord("a") + 1 if $list_marker_type eq "a";
	return 1 unless $list_marker_type eq "i";
	defined($_roman_number_table{$marker_val}) and
	    return $_roman_number_table{$marker_val};
	return 1;
    }};
    return $ans if $ans == 0 && $list_marker_type eq "1";
    return $ans >= 1 ? $ans : 1;
}


sub _IncrList {
    my ($from, $to, $extra) = @_;
    $extra = defined($extra) ? " $extra" : "";
    my $result = "";
    while ($from + 10 <= $to) {
	$result .= "<span$extra class=\"$opt{style_prefix}ol-incr-10\"></span>\n";
	$from += 10;
    }
    while ($from + 5 <= $to) {
	$result .= "<span$extra class=\"$opt{style_prefix}ol-incr-5\"></span>\n";
	$from += 5;
    }
    while ($from + 2 <= $to) {
	$result .= "<span$extra class=\"$opt{style_prefix}ol-incr-2\"></span>\n";
	$from += 2;
    }
    while ($from < $to) {
	$result .= "<span$extra class=\"$opt{style_prefix}ol-incr\"></span>\n";
	++$from;
    }
    return $result;
}


sub _DoListsAndBlocks {
#
# Form HTML ordered (numbered) and unordered (bulleted) lists.
#
    my $text = shift;
    my $indent = $opt{indent_width};
    my $less_than_indent = $indent - 1;
    my $less_than_double_indent = 2 * $indent - 1;

    # Re-usable pattern to match any entire ul or ol list:
    my $whole_list = qr{
	(			    # $1 (or $_[0]) = whole list
	  (			    # $2 (or $_[1])
	    (?:(?<=\n)|\A)
	    [ ]{0,$less_than_indent}
	    (${marker_any})	    # $3 (or $_[2]) = first list item marker
	    [ ]+
	  )
	  (?s:.+?)
	  (			    # $4 (or $_[3])
	      \z
	    |
	      \n{2,}
	      (?=\S)
	      (?!		    # Negative lookahead for another list item marker
		${marker_any}[ ]
	      )
	  )
	)
    }mx;

    my $list_item_sub = sub {
	my $list = $_[0];
	my $list_type = ($_[2] =~ m/$marker_ul/) ? "ul" : "ol";
	my $list_att = "";
	my $list_class = "";
	my $list_incr = "";
	# Turn double returns into triple returns, so that we can make a
	# paragraph for the last item in a list, if necessary:
	$list =~ s/\n\n/\n\n\n/g;
	my ($result, $first_marker, $fancy) = _ProcessListItems($list_type, $list);
	defined($first_marker) or return $list;
	my $list_marker_type = _GetListMarkerType($list_type, $first_marker);
	if ($list_marker_type) {
		$first_marker =~ s/[.\)]$//;
		my $first_marker_num = _GetMarkerIntegerNum($list_marker_type, $first_marker);
		$list_att = $list_marker_type eq "1" ? "" : " type=\"$list_marker_type\"";
		if ($fancy) {
		    $list_class = " class=\"$opt{style_prefix}ol\"";
		    my $start = $first_marker_num;
		    $start = 10 if $start > 10;
		    $start = 5 if $start > 5 && $start < 10;
		    $start = 1 if $start > 1 && $start < 5;
		    $list_att .= " start=\"$start\"" unless $start == 1;
		    $list_incr = _IncrList($start, $first_marker_num);
		} else {
		    $list_class = " class=\"$opt{style_prefix}lc-greek\""
			if $list_marker_type eq "a" && $first_marker =~ /^$greek_lower/o;
		    $list_att .= " start=\"$first_marker_num\"" unless $first_marker_num == 1;
		}
	}
	my $idt = "\027" x $g_list_level;
	$result = "$idt<$list_type$list_att$list_class>\n$list_incr" . $result . "$idt</$list_type>\n\n";
	$result;
    };

    # We use a different prefix before nested lists than top-level lists.
    # See extended comment in _ProcessListItems().
    #
    # Note: (jg) There's a bit of duplication here. My original implementation
    # created a scalar regex pattern as the conditional result of the test on
    # $g_list_level, and then only ran the $text =~ s{...}{...}egmx
    # substitution once, using the scalar as the pattern. This worked,
    # everywhere except when running under MT on my hosting account at Pair
    # Networks. There, this caused all rebuilds to be killed by the reaper (or
    # perhaps they crashed, but that seems incredibly unlikely given that the
    # same script on the same server ran fine *except* under MT. I've spent
    # more time trying to figure out why this is happening than I'd like to
    # admit. My only guess, backed up by the fact that this workaround works,
    # is that Perl optimizes the substition when it can figure out that the
    # pattern will never change, and when this optimization isn't on, we run
    # afoul of the reaper. Thus, the slightly redundant code to that uses two
    # static s/// patterns rather than one conditional pattern.
    #
    # Note: (kjm) With the addition of the two-of-the-same-kind-in-a-row-
    # starts-a-list-at-the-top-level rule the two patterns really are somewhat
    # different now, but the duplication has pretty much been eliminated via
    # use of a separate sub which has the side-effect of making the below
    # two cases much easier to grok all at once.

    if ($g_list_level) {
	my $parse = $text;
	$text = "";
	pos($parse) = 0;
	while ($parse =~ /\G(?s:.)*?^$whole_list/gmc) {
	    my @captures = ($1, $2, $3, $4);
	    if ($-[1] > $-[0]) {
		$text .= _DoListBlocks(substr($parse, $-[0], $-[1] - $-[0]));
	    }
	    $text .= &$list_item_sub(@captures);
	}
	$text .= _DoListBlocks(substr($parse, pos($parse))) if pos($parse) < length($parse);
    }
    else {
	my $parse = $text;
	$text = "";
	pos($parse) = 0;
	while ($parse =~ m{\G(?s:.)*?
		(?: (?<=\n\n) |
		    \A\n? |
		    (?<=:\n) |
		    (?:(?<=\n) # a list starts with one unordered marker line
		       (?=[ ]{0,$less_than_indent}$marker_ul[ ])) |
		    (?:(?<=\n) # or two ordered marker lines in a row
		       (?=[ ]{0,$less_than_indent}$marker_ol[ ].*\n\n?
		          [ ]{0,$less_than_indent}$marker_ol[ ])) |
		    (?:(?<=\n) # or any marker and a sublist marker
		       (?=[ ]{0,$less_than_indent}$marker_any[ ].*\n\n?
		          [ ]{$indent,$less_than_double_indent}$marker_any[ ]))
		)
		$whole_list
	    }gmcx) {
	    my @captures = ($1, $2, $3, $4);
	    if ($-[1] > $-[0]) {
		$text .= _DoListBlocks(substr($parse, $-[0], $-[1] - $-[0]));
	    }
	    $text .= &$list_item_sub(@captures);
	}
	$text .= _DoListBlocks(substr($parse, pos($parse))) if pos($parse) < length($parse);
    }

    return $text;
}


sub _ProcessListItems {
#
#   Process the contents of a single ordered or unordered list, splitting it
#   into individual list items.
#

    my $list_type = shift;
    my $list_str = shift;

    # The $g_list_level global keeps track of when we're inside a list.
    # Each time we enter a list, we increment it; when we leave a list,
    # we decrement. If it's zero, we're not in a list anymore.
    #
    # We do this because when we're not inside a list, we want to treat
    # something like this:
    #
    #	I recommend upgrading to version
    #	8. Oops, now this line is treated
    #	as a sub-list.
    #
    # As a single paragraph, despite the fact that the second line starts
    # with a digit-period-space sequence.
    #
    # Whereas when we're inside a list (or sub-list), that line will be
    # treated as the start of a sub-list. What a kludge, huh? This is
    # an aspect of Markdown's syntax that's hard to parse perfectly
    # without resorting to mind-reading. Perhaps the solution is to
    # change the syntax rules such that sub-lists must start with a
    # starting cardinal number; e.g. "1." or "a.".

    $g_list_level++;
    my $idt = "\027" x $g_list_level;
    my $marker_kind = $list_type eq "ul" ? $marker_ul : $marker_ol;
    my $first_marker;
    my $first_marker_type;
    my $first_marker_num;
    my $last_marker;
    my $fancy;
    my $skipped;
    my $typechanged;
    my $next_num = 1;

    # trim trailing blank lines:
    $list_str =~ s/\n{2,}\z/\n/;

    my $result = "";
    my $oldpos = 0;
    pos($list_str) = 0;
    while ($list_str =~ m{\G		# start where we left off
	(\n+)?				# leading line = $1
	(^[ ]*)				# leading whitespace = $2
	($marker_any) [ ] ([ ]*)	# list marker = $3 leading item space = $4
    }cgmx) {
	my $leading_line = $1;
	my $leading_space = $2;
	my $list_marker = $3;
	my $list_marker_len = length($list_marker);
	my $leading_item_space = $4;
	if ($-[0] > $oldpos) {
	    $result .= substr($list_str, $oldpos, $-[0] - $oldpos); # Sort-of $`
	    $oldpos = $-[0]; # point at start of this entire match
	}
	if (!defined($first_marker)) {
	    $first_marker = $list_marker;
	    $first_marker_type = _GetListMarkerType($list_type, $first_marker);
	    if ($first_marker_type) {
		(my $marker_val = $first_marker) =~ s/[.\)]$//;
		$first_marker_num = _GetMarkerIntegerNum($first_marker_type, $marker_val);
		$next_num = $first_marker_num;
		$skipped = 1 if $next_num != 1;
	    }
	} elsif ($list_marker !~ /$marker_kind/) {
	    # Wrong marker kind, "fix up" the marker to a correct "lazy" marker
	    # But keep the old length in $list_marker_len
	    $list_marker = $last_marker;
	}

	# Now grab the rest of this item's data upto but excluding the next
	# list marker at the SAME indent level, but sublists must be INCLUDED

	my $item = "";
	while ($list_str =~ m{\G
	    ((?:.+?)(?:\n{1,2}))	# list item text = $1
	    (?= \n* (?: \z |		# end of string OR
		    (^[ ]*)		# leading whitespace = $2
		    ($marker_any)	# next list marker = $3
		    ([ ]+) ))		# one or more spaces after marker = $4
	}cgmxs) {

	    # If $3 has a left edge that is at the left edge of the previous
	    # marker OR $3 has a right edge that is at the right edge of the
	    # previous marker then we stop; otherwise we go on

	    $item .= substr($list_str, $-[0], $+[0] - $-[0]); # $&
	    last if !defined($4) || length($2) == length($leading_space) ||
		length($2) + length($3) == length($leading_space) + $list_marker_len;
	    # move along, you're not the marker droid we're looking for...
	    $item .= substr($list_str, $+[0], $+[4] - $+[0]);
	    pos($list_str) = $+[4]; # ...move along over the marker droid
	}
	# Remember where we parked
	$oldpos = pos($list_str);

	# Process the $list_marker $item

	my $liatt = '';
	my $checkbox = '';
	my $incr = '';

	if ($list_type eq "ul" && !$leading_item_space && $item =~ /^\[([ xX])\] +(.*)$/s) {
	    my $checkmark = lc $1;
	    $item = $2;
	    my ($checkbox_class, $checkbox_val);
	    if ($checkmark eq "x") {
		($checkbox_class, $checkbox_val) = ("checkbox-on", "x");
	    } else {
		($checkbox_class, $checkbox_val) = ("checkbox-off", "&#160;");
	    }
	    $liatt = " class=\"$opt{style_prefix}$checkbox_class\"";
	    $checkbox = "<span><span></span></span><span></span><span>[<tt>$checkbox_val</tt>]&#160;</span>";
	} else {
	    my $list_marker_type;
	    ($list_marker_type, $liatt) = _GetListItemTypeClass($list_type, $list_marker, $last_marker);
	    if ($list_type eq "ol" && defined($first_marker)) {
		my $styled = $fancy = 1 if $liatt && $list_marker =~ /\)$/;
		my ($sfx, $dash) = ("", "");
		($sfx, $dash) = ("li", "-") if $styled;
		if ($liatt =~ /lower/) {
		    $sfx .= "${dash}lc";
		} elsif ($liatt =~ /upper/) {
		    $sfx .= "${dash}uc";
		}
		$sfx .= "-greek" if $liatt =~ /greek/;
		$liatt = " class=\"$opt{style_prefix}$sfx\"" if $sfx;
		$typechanged = 1 if $list_marker_type ne $first_marker_type;
		(my $marker_val = $list_marker) =~ s/[.\)]$//;
		my $marker_num = _GetMarkerIntegerNum($list_marker_type, $marker_val);
		$marker_num = $next_num if $marker_num < $next_num;
		$skipped = 1 if $next_num < $marker_num;
		$incr = _IncrList($next_num, $marker_num, "incrlevel=$g_list_level");
		$liatt = " value=\"$marker_num\"$liatt" if $fancy || $skipped;
		$liatt = " type=\"$list_marker_type\"$liatt" if $styled || $typechanged;
		$next_num = $marker_num + 1;
	    }
	}
	$last_marker = $list_marker;

	if ($leading_line or ($item =~ m/\n{2,}/)) {
	    $item = _RunBlockGamut(_Outdent($item));
	    $item =~ s{(</[OUou][Ll]>)\s*\z}{$1} and $item .= "\n$idt<span style=\"display:none\">&#160;</span>";
	}
	else {
	    # Recursion for sub-lists:
	    $item = _DoListsAndBlocks(_Outdent($item));
	    chomp $item;
	    $item = _RunSpanGamut($item);
	}

	# Append to $result
	$result .= "$incr$idt<li$liatt>" . $checkbox . $item . "$idt</li>\n";
    }
    if ($fancy) {
	# remove "incrlevel=$g_list_level " parts
	$result =~ s{<span incrlevel=$g_list_level class="$opt{style_prefix}ol-incr((?:-\d{1,2})?)">}
	    {$idt<span class="$opt{style_prefix}ol-incr$1">}g;
    } else {
	# remove the $g_list_level incr spans entirely
	$result =~ s{<span incrlevel=$g_list_level class="$opt{style_prefix}ol-incr(?:-\d{1,2})?"></span>\n}{}g;
	# remove the class="$opt{style_prefix}lc-greek" if first_marker is greek
	$result =~ s{(<li[^>]*?) class="$opt{style_prefix}lc-greek">}{$1>}g
	    if defined($first_marker_type) && $first_marker_type eq "a" && $first_marker =~ /^$greek_lower/o;
    }

    # Anything left over (similar to $') goes into result, but this should always be empty
    $result .= _RunBlockGamut(substr($list_str, pos($list_str))) if pos($list_str) < length($list_str);

    $g_list_level--;

    # After all that, if we only got an ordered list with a single item
    # and its first marker is a four-digit number >= 1492 and <= 2999
    # or an UPPERCASE letter, then pretend we didn't see any list at all.

    if ($first_marker_type && $first_marker_num + 1 == $next_num) {
	if (($first_marker_type eq "1" && $first_marker_num >= 1492 && $first_marker_num <= 2999) ||
	    ($first_marker_type eq "A" && !$fancy)) {
	    return (undef, undef, undef);
	}
    }

    return ($result, $first_marker, $fancy);
}


sub _DoCodeBlocks {
#
#   Process Markdown `<pre><code>` blocks.
#

    my $text = shift;

    $text =~ s{
	    (?:\n\n|\A\n?)
	    (		# $1 = the code block -- one or more lines, starting with indent_width spaces
	      (?:
		(?:[ ]{$opt{indent_width}})  # Lines must start with indent_width of spaces
		.*\n+
	      )+
	    )
	    ((?=^[ ]{0,$opt{indent_width}}\S)|\Z) # Lookahead for non-space at line-start, or end of doc
	}{
	    my $codeblock = $1;

	    $codeblock =~ s/\n\n\n/\n\n/g; # undo "paragraph for last list item" change
	    $codeblock = _EncodeCode(_Outdent($codeblock));
	    $codeblock =~ s/\A\n+//; # trim leading newlines
	    $codeblock =~ s/\s+\z//; # trim trailing whitespace

	    my $result = "<div class=\"$opt{style_prefix}code\"><pre style=\"display:none\"></pre><pre><code>"
		. $codeblock . "\n</code></pre></div>";
	    my $key = block_id($result, 2);
	    $g_code_blocks{$key} = $result;
	    "\n\n" . $key . "\n\n";
	}egmx;

    return $text;
}


sub _DoCodeSpans {
#
# * Backtick quotes are used for <code></code> spans.
#
# * You can use multiple backticks as the delimiters if you want to
#   include literal backticks in the code span. So, this input:
#
#     Just type ``foo `bar` baz`` at the prompt.
#
#   Will translate to:
#
#     <p>Just type <code>foo `bar` baz</code> at the prompt.</p>
#
#   There's no arbitrary limit to the number of backticks you
#   can use as delimters. If you need three consecutive backticks
#   in your code, use four for delimiters, etc.
#
# * You can use spaces to get literal backticks at the edges:
#
#     ... type `` `bar` `` ...
#
#   Turns to:
#
#     ... type <code>`bar`</code> ...
#

    my $text = shift;

    $text =~ s@
	    (`+)	# $1 = Opening run of `
	    (.+?)	# $2 = The code block
	    (?<!`)
	    \1		# Matching closer
	    (?!`)
	@
	    my $c = "$2";
	    $c =~ s/^[ ]+//g; # leading whitespace
	    $c =~ s/[ ]+$//g; # trailing whitespace
	    $c = _EncodeCode($c);
	    "<code>$c</code>";
	@egsx;

    return $text;
}


sub _EncodeCode {
#
# Encode/escape certain characters inside Markdown code runs.
# The point is that in code, these characters are literals,
# and lose their special Markdown meanings.
#
    local $_ = shift;

    # Encode all ampersands; HTML entities are not
    # entities within a Markdown code span.
    s/&/&amp;/g;

    # Encode $'s, but only if we're running under Blosxom.
    # (Blosxom interpolates Perl variables in article bodies.)
    s/\$/&#036;/g if $_haveBX;

    # Do the angle bracket song and dance:
    s! <  !&lt;!gx;
    s! >  !&gt;!gx;

    # Now, escape characters that are magic in Markdown:
    s!([*_~{}\[\]\\])!$g_escape_table{$1}!g;

    return $_;
}


sub _DoItalicsAndBoldAndStrike {
    my $text = shift;

    my $doital1 = sub {
	my $text = shift;
	$text =~ s{ \* (?=\S) (.+?) (?<=\S) \* }
	    {<em>$1</em>}gsx;
	# We've got to encode any of these remaining to
	# avoid conflicting with other italics and bold.
	$text =~ s!([*])!$g_escape_table{$1}!g;
	$text;
    };
    my $doital2 = sub {
	my $text = shift;
	$text =~ s{ (?<!\w) _ (?=\S) (.+?) (?<=\S) _ (?!\w) }
	    {<em>$1</em>}gsx;
	# We've got to encode any of these remaining to
	# avoid conflicting with other italics and bold.
	$text =~ s!([_])!$g_escape_table{$1}!g;
	$text;
    };

    # <strong> must go first:
    $text =~ s{ \*\* (?=\S) (.+?[*_]*) (?<=\S) \*\* }
	{"<strong>".&$doital1($1)."</strong>"}gsex;
    $text =~ s{ (?<!\w) __ (?=\S) (.+?[*_]*) (?<=\S) __ (?!\w) }
	{"<strong>".&$doital2($1)."</strong>"}gsex;

    $text =~ s{ ~~ (?=\S) (.+?[*_]*) (?<=\S) ~~ }
	{<strike>$1</strike>}gsx;

    $text =~ s{ \* (?=\S) (.+?) (?<=\S) \* }
	{<em>$1</em>}gsx;
    $text =~ s{ (?<!\w) _ (?=\S) (.+?) (?<=\S) _ (?!\w) }
	{<em>$1</em>}gsx;

    return $text;
}


sub _DoBlockQuotes {
    my $text = shift;

    $text =~ s{
	  (			# Wrap whole match in $1
	    (
	      ^[ ]*>[ ]?	# '>' at the start of a line
		.*\n		# rest of the first line
	      (.+\n)*		# subsequent consecutive lines
	      \n*		# blanks
	    )+
	  )
	}{
	    my $bq = $1;
	    $bq =~ s/^[ ]*>[ ]?//gm; # trim one level of quoting
	    $bq =~ s/^[ ]+$//mg;	 # trim whitespace-only lines
	    $bq = _RunBlockGamut($bq);	 # recurse

	    $bq =~ s/^/\027/mg;
	    "<blockquote>\n$bq\n</blockquote>\n\n";
	}egmx;


    return $text;
}


my ($LEAD, $TRAIL, $LEADBAR, $LEADSP, $COLPL, $SEP);
BEGIN {
    $LEAD = qr/(?>[ ]*(?:\|[ ]*)?)/o;
    $TRAIL = qr/[ ]*(?<!\\)\|[ ]*/o;
    $LEADBAR = qr/(?>[ ]*\|[ ]*)/o;
    $LEADSP = qr/(?>[ ]*)/o;
    $COLPL = qr/(?:[^\n|\\]|\\(?:(?>[^\n])|(?=\n|$)))+/o;
    $SEP = qr/[ ]*:?-+:?[ ]*/o;
}

sub _DoTables {
    my $text = shift;

    $text =~ s{
	(				# Wrap whole thing to avoid $&
	 (?: (?<=\n\n) | \A\n? )	# Preceded by blank line or beginning of string
	 ^(				# Header line
	    $LEADBAR \| [^\n]* |
	    $LEADBAR $COLPL [^\n]* |
	    $LEADSP $COLPL \| [^\n]*
	  )\n
	  (				# Separator line
	    $LEADBAR $SEP (?: \| $SEP )* (?: \| [ ]*)? |
	    $SEP (?: \| $SEP )+ (?: \| [ ]*)? |
	    $SEP \| [ ]*
	  )\n
	  ((?:				# Rows (0+)
	    $LEADBAR \| [^\n]* \n |
	    $LEADBAR $COLPL [^\n]* \n |
	    $LEADSP $COLPL \| [^\n]* \n
	  )*)
	)
    } {
	my ($w, $h, $s, $rows) = ($1, $2, $3, $4);
	my @heads = _SplitTableRow($h);
	my @seps = _SplitTableRow($s);
	if (@heads == @seps) {
	    my @align = map {
		if (/^:-+:$/) {" align=\"center\""}
		elsif (/^:/) {" align=\"left\""}
		elsif (/:$/) {" align=\"right\""}
		else {""}
	    } @seps;
	    my $nohdr = "";
	    $nohdr = " $opt{style_prefix}table-nohdr" if join("", @heads) eq "";
	    my $tab ="\n<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\" class=\"$opt{style_prefix}table$nohdr\">\n";
	    $tab .=
		"  <tr class=\"$opt{style_prefix}row-hdr\">" . _MakeTableRow("th", \@align, @heads) . "</tr>\n"
		unless $nohdr;
	    my $cnt = 0;
	    my @classes = ("class=\"$opt{style_prefix}row-even\"", "class=\"$opt{style_prefix}row-odd\"");
	    $tab .= "  <tr " . $classes[++$cnt % 2] . ">" . _MakeTableRow("td", \@align, @$_) . "</tr>\n"
		    foreach (_SplitMergeRows($rows));
	    $tab .= "</table>\n\n";
	} else {
	    $w;
	}
    }egmx;

    return $text;
}


sub _SplitMergeRows {
    my @rows = ();
    my ($mergeprev, $mergenext) = (0,0);
    foreach (split(/\n/, $_[0])) {
	$mergeprev = $mergenext;
	$mergenext = 0;
	my @cols = _SplitTableRow($_);
	if (_endswithbareslash($cols[$#cols])) {
	    my $last = $cols[$#cols];
	    substr($last, -1, 1) = "";
	    $last =~ s/[ ]+$//;
	    $cols[$#cols] = $last;
	    $mergenext = 1;
	}
	if ($mergeprev) {
	    for (my $i = 0; $i <= $#cols; ++$i) {
		my $cell = $rows[$#rows]->[$i];
		defined($cell) or $cell = "";
		$rows[$#rows]->[$i] = _MergeCells($cell, $cols[$i]);
	    }
	} else {
	    push(@rows, [@cols]);
	}
    }
    return @rows;
}


sub _endswithbareslash {
    return 0 unless substr($_[0], -1, 1) eq "\\";
    my @parts = split(/\\\\/, $_[0], -1);
    return substr($parts[$#parts], -1, 1) eq "\\";
}


sub _MergeCells {
    my ($c1, $c2) = @_;
    return $c1 if $c2 eq "";
    return $c2 if $c1 eq "";
    return $c1 . " " . $c2;
}


sub _SplitTableRow {
    my $row = shift;
    $row =~ s/^$LEAD//;
    $row =~ s/$TRAIL$//;
    $row =~ s!\\\\!$g_escape_table{'\\'}!go; # Must process escaped backslashes first.
    $row =~ s!\\\|!$g_escape_table{'|'}!go; # Then do \|
    my @elems = map {
      s!$g_escape_table{'|'}!|!go;
      s!$g_escape_table{'\\'}!\\\\!go;
      s/^[ ]+//;
      s/[ ]+$//;
      $_;
    } split(/[ ]*\|[ ]*/, $row, -1);
    @elems or push(@elems, "");
    return @elems;
}


sub _MakeTableRow {
    my $etype = shift;
    my $align = shift;
    my $row = "";
    for (my $i = 0; $i < @$align; ++$i) {
	my $data = $_[$i];
	defined($data) or $data = "";
	$row .= "<" . $etype . $$align[$i] . ">" .
	    _RunSpanGamut($data) . "</" . $etype . ">";
    }
    return $row;
}


sub _FormParagraphs {
#
# Params:
#   $text - string to process with html <p> tags
#
    my $text = shift;

    # Strip leading and trailing lines:
    $text =~ s/\A\n+//;
    $text =~ s/\n+\z//;

    my @grafs = split(/\n{2,}/, $text);

    #
    # Wrap <p> tags.
    #
    foreach (@grafs) {
	unless (defined($g_html_blocks{$_}) || defined($g_code_blocks{$_})) {
	    $_ = _RunSpanGamut($_);
	    s/^([ ]*)/<p>/;
	    $_ .= "</p>";
	}
    }

    #
    # Unhashify HTML blocks
    #
    foreach (@grafs) {
	if (defined( $g_html_blocks{$_} )) {
	    $_ = $g_html_blocks{$_};
	}
    }

    return join "\n\n", @grafs;
}


my $g_possible_tag_name;
my %ok_tag_name;
BEGIN {
    # note: length("blockquote") == 10
    $g_possible_tag_name = qr/(?i:[a-z]{1,10}|h[1-6])/o;
    %ok_tag_name = map({$_ => 1} qw(
	a abbr acronym address area
	b basefont bdo big blockquote br
	caption center cite code col colgroup
	dd del dfn div dl dt
	em
	font
	h1 h2 h3 h4 h5 h6 hr
	i img ins
	kbd
	li
	map
	ol
	p pre
	q
	s samp small span strike strong sub sup
	table tbody td tfoot th thead tr tt
	u ul
	var
    ));
    $ok_tag_name{$_} = 0 foreach (qw(
	dir menu
    ));
}


sub _SetAllowedTag {
    my ($tag, $forbid) = @_;
    $ok_tag_name{$tag} = $forbid ? 0 : 1
	if defined($tag) && exists($ok_tag_name{$tag});
}


# Encode leading '<' of any non-tags
# However, "<?", "<!" and "<$" are passed through (legacy on that "<$" thing)
sub _DoTag {
    my $tag = shift;
    return $tag if $tag =~ /^<[?\$!]/;
    if (($tag =~ m{^<($g_possible_tag_name)(?:[\s>]|/>$)} || $tag =~ m{^</($g_possible_tag_name)\s*>}) &&
	$ok_tag_name{lc($1)}) {

	return _ProcessURLTag("href", $tag, 1) if $tag =~ /^<a\s/i;
	return _ProcessURLTag("src", $tag) if $tag =~ /^<img\s/i;
	return $tag;
    }
    $tag =~ s/^</&lt;/;
    return $tag;
}


my %univatt;	# universally allowed attribute names
my %tagatt;	# per-element allowed attribute names
my %tagmt;	# empty element tags
my %tagocl;	# non-empty elements with optional closing tag
my %tagacl;	# which %tagocl an opening %tagocl will close
my %tagblk;	# block elements
my %taga1p;	# open tags which require at least one attribute
my %lcattval;	# names of attribute values to lowercase
my %impatt;	# names of "implied" attributes
BEGIN {
    %univatt = map({$_ => 1} qw(class dir id lang style title xml:lang));
    %tagatt = (
	'a' => { map({$_ => 1} qw(href name)) },
	'area' => { map({$_ => 1} qw(alt coords href nohref shape)) },
	'basefont' => { map({$_ => 1} qw(color face size)) },
	'br' => { map({$_ => 1} qw(clear)) },
	'caption' => { map({$_ => 1} qw(align)) },
	'col' => { map({$_ => 1} qw(align span width valign)) },
	'colgroup' => { map({$_ => 1} qw(align span width valign)) },
	'dir' => { map({$_ => 1} qw(compact)) },
	'div' => { map({$_ => 1} qw(align)) },
	'dl' => { map({$_ => 1} qw(compact)) },
	'font' => { map({$_ => 1} qw(color face size)) },
	'h1' => { map({$_ => 1} qw(align)) },
	'h2' => { map({$_ => 1} qw(align)) },
	'h3' => { map({$_ => 1} qw(align)) },
	'h4' => { map({$_ => 1} qw(align)) },
	'h5' => { map({$_ => 1} qw(align)) },
	'h6' => { map({$_ => 1} qw(align)) },
	'hr' => { map({$_ => 1} qw(align noshade size width)) },
	# NO server-side image maps, therefore NOT ismap !
	'img' => { map({$_ => 1} qw(align alt border height hspace src usemap vspace width)) },
	'li' => { map({$_ => 1} qw(compact type value)) },
	'map' => { map({$_ => 1} qw(name)) },
	'menu' => { map({$_ => 1} qw(compact)) },
	'ol' => { map({$_ => 1} qw(compact start type)) },
	'p' => { map({$_ => 1} qw(align)) },
	'pre' => { map({$_ => 1} qw(width)) },
	'table' => { map({$_ => 1} qw(align border cellpadding cellspacing summary width)) },
	'tbody' => { map({$_ => 1} qw(align valign)) },
	'tfoot' => { map({$_ => 1} qw(align valign)) },
	'thead' => { map({$_ => 1} qw(align valign)) },
	'td' => { map({$_ => 1} qw(align colspan height nowrap rowspan valign width)) },
	'th' => { map({$_ => 1} qw(align colspan height nowrap rowspan valign width)) },
	'tr' => { map({$_ => 1} qw(align valign)) },
	'ul' => { map({$_ => 1} qw(compact type)) }
    );
    %tagmt = map({$_ => 1} qw(area basefont br col hr img));
    %tagocl = map({$_ => 1} qw(colgroup dd dt li p tbody td tfoot th thead tr));
    %tagacl = (
	'colgroup' => \%tagocl,
	'dd' => \%tagocl,
	'dt' => \%tagocl,
	'li' => \%tagocl,
	'tbody' => \%tagocl,
	'td' => { map({$_ => 1} qw(colgroup dd dt li p td tfoot th thead)) },
	'tfoot' => \%tagocl,
	'th' => { map({$_ => 1} qw(colgroup dd dt li p td tfoot th thead)) },
	'thead' => \%tagocl,
	'tr' => { map({$_ => 1} qw(colgroup dd dt li p td tfoot th thead tr)) },
    );
    %tagblk = map({$_ => 1} qw(address blockquote div dl h1 h2 h3 h4 h5 h6 hr ol p pre table));
    %impatt = map({$_ => 1} qw(checked compact ismap nohref noshade nowrap));
    %lcattval = map({$_ => 1} qw(
	align border cellpadding cellspacing checked clear color colspan
	compact coords height hspace ismap nohref noshade nowrap rowspan size
	span shape valign vspace width
    ));
    %taga1p = map({$_ => 1} qw(a area img map));
}


# _SanitizeTags
#
# Inspect all '<'...'>' tags in the input and HTML encode those things
# that cannot possibly be tags and at the same time sanitize them.
#
# $1 => text to process
# <= sanitized text
sub _SanitizeTags {
    my ($text, $validate) = @_;
    $text =~ s/\s+$//;
    $text ne "" or return "";
    my @stack = ();
    my $ans = "";
    my $end = length($text);
    pos($text) = 0;
    my ($autoclose, $autoclopen);
    my $lastmt = "";
    $autoclose = sub {
	my $s = $_[0] || "";
	while (@stack && $stack[$#stack]->[0] ne $s &&
		$tagocl{$stack[$#stack]->[0]}) {
	    $ans .= "</" . $stack[$#stack]->[0] . ">";
	    pop(@stack);
	}
    } if $validate;
    $autoclopen = sub {
	my $s = $_[0] || "";
	my $c;
	if ($tagblk{$s}) {$c = {p=>1}}
	elsif ($tagocl{$s}) {$c = $tagacl{$s}}
	else {return}
	while (@stack && $c->{$stack[$#stack]->[0]}) {
	    $ans .= "</" . $stack[$#stack]->[0] . ">";
	    pop(@stack);
	}
    } if $validate;
    while (pos($text) < $end) {
	if ($text =~ /\G([^<]+)/gc) {
	    $ans .= $1;
	    $lastmt = "" if $1 =~ /\S/;
	    next;
	}
	my $tstart = pos($text);
	if ($text =~ /\G(<[^>]*>)/gc) {
	    my $tag = $1;
	    if ($tag =~ /^<!--/) { # pass "comments" through
		$ans .= $tag;
		next;
	    }
	    my $tt;
	    if (($tag =~ m{^<($g_possible_tag_name)(?:[\s>]|/>$)} ||
		 $tag =~ m{^</($g_possible_tag_name)\s*>}) &&
		$ok_tag_name{$tt=lc($1)})
	    {
		my ($stag, $styp) = _Sanitize($tag);
		if ($styp == 2 && $lastmt eq $tt) {
		    $lastmt = "";
		    next;
		}
		$lastmt = $styp == 3 ? $tt : "";
		if ($validate && $styp) {
		    &$autoclopen($tt) if $styp == 1 || $styp == 3;
		    if ($styp == 1) {
			push(@stack,[$tt,$tstart]);
		    } elsif ($styp == 2) {
			&$autoclose($tt) unless $tt eq "p";
			!@stack and _xmlfail("closing tag $tt without matching open at " .
			    _linecol($tstart, $text));
			if ($stack[$#stack]->[0] eq $tt) {
			    pop(@stack);
			} else {
			    my @i = @{$stack[$#stack]};
			    _xmlfail("opening tag $i[0] at " . _linecol($i[1], $text) .
				" mismatch with closing tag $tt at " . _linecol($tstart, $text));
			}
		    }
		}
		$ans .= $stag;
		next;
	    } else {
		$tag =~ s/^</&lt;/;
		$ans .= $tag;
		$lastmt = "";
		next;
	    }
	}
	# can only get here if "\G" char is an unmatched "<"
	pos($text) += 1;
	$ans .= "&lt;";
	$lastmt = "";
    }
    &$autoclose if $validate;
    if ($validate && @stack) {
	my @errs;
	my $j;
	for ($j = 0; $j <= $#stack; ++$j) {
		my @i = @{$stack[$j]};
		unshift(@errs, "opening tag $i[0] without matching close at " .
			    _linecol($i[1], $text));
	}
	_xmlfail(@errs);
    }
    return $ans."\n";
}


sub _linecol {
	my ($pos, $txt) = @_;
	pos($txt) = 0;
	my ($l, $p);
	$l = 1;
	++$l while ($p = pos($txt)), $txt =~ /\G[^\n]*\n/gc && pos($txt) <= $pos;
	return "line $l col " . (1 + ($pos - $p));
}


sub _xmlfail {
	die join("", map("$_\n", @_));
}


sub _Sanitize {
    my $tag = shift;
    my $seenatt = {};
    if ($tag =~ m{^</}) {
	$tag =~ s/\s+>$/>/;
	return (lc($tag),2);
    }
    if ($tag =~ /^<([^\s<\/>]+)\s+/gs) {
	my $tt = lc($1);
	my $out = "<" . $tt . " ";
	my $ok = $tagatt{$tt};
	ref($ok) eq "HASH" or $ok = {};
	while ($tag =~ /\G\s*([^\s\042\047<\/>=]+)((?>=)|\s*)/gcs) {
	    my ($a,$s) = ($1, $2);
	    if ($s eq "" && substr($tag, pos($tag), 1) =~ /^[\042\047]/) {
		# pretend the "=" sign wasn't overlooked
		$s = "=";
	    }
	    if (substr($s,0,1) ne "=") {
		# it's one of "those" attributes (e.g. compact) or not
		# _SanitizeAtt will fix it up if it is
		$out .= _SanitizeAtt($a, '""', $ok, $seenatt);
		next;
	    }
	    if ($tag =~ /\G([\042\047])((?:(?!\1)(?!<).)*)\1\s*/gcs) {
		$out .= _SanitizeAtt($a, $1.$2.$1, $ok, $seenatt);
		next;
	    }
	    if ($tag =~ /\G([\042\047])((?:(?!\1)(?![<>])(?![\/][>]).)*)/gcs) {
		# what to do what to do what to do
		# trim trailing \s+ and magically add the missing quote
		my ($q, $v) = ($1, $2);
		$v =~ s/\s+$//;
		$out .= _SanitizeAtt($a, $q.$v.$q, $ok, $seenatt);
		next;
	    }
	    if ($tag =~ /\G([^\s<\/>]+)\s*/gcs) {
		# auto quote it
		my $v = $1;
		$v =~ s/\042/&quot;/go;
		$out .= _SanitizeAtt($a, '"'.$v.'"', $ok, $seenatt);
		next;
	    }
	    # give it an empty value
	    $out .= _SanitizeAtt($a, '""', $ok, $seenatt);
        }
	my $sfx = substr($tag, pos($tag));
	$out =~ s/\s+$//;
	my $typ = 1;
	if ($tagmt{$tt}) {
	    $typ = 3;
	    $out .= $opt{empty_element_suffix};
	} else {
	    $out .= ">";
	    $out .= "</$tt>" and $typ = 3 if $tag =~ m,/>$,;
	}
	return ($out,$typ);
    } elsif ($tag =~ /^<([^\s<\/>]+)/s) {
	my $tt = lc($1);
	return ("&lt;" . substr($tag,1), 0) if $taga1p{$tt};
	if ($tagmt{$tt}) {
	    return ("<" . $tt . $opt{empty_element_suffix}, 3);
	} elsif ($tag =~ m,/>$,) {
	    return ("<" . $tt . "></" . $tt . ">", 3);
	} else {
	    return ("<" . $tt . ">", 1);
	}
    }
    return (lc($tag),0);
}


sub _SanitizeAtt {
    my $att = lc($_[0]);
    return "" unless $att =~ /^[_a-z:][_a-z:0-9.-]*$/; # no weirdo char att names
    return "" unless $univatt{$att} || $_[2]->{$att};
    return "" if $_[3]->{$att}; # no repeats
    $_[3]->{$att} = 1;
    $impatt{$att} and return $att."=".'"'.$att.'"';
    if ($lcattval{$att}) {
	return $att."=".lc($_[1])." ";
    } else {
	return $att."=".$_[1]." ";
    }
}


sub _ProcessURLTag {
    my ($att, $tag, $dofrag) = @_;

    $att = lc($att) . "=";
    if ($tag =~ /^(<[^\s>]+\s+)/g) {
	my $out = $1;
	while ($tag =~ /\G([^\s\042\047<\/>=]+=)([\042\047])((?:(?!\2)(?!<).)*)(\2\s*)/gcs) {
	    my ($p, $q, $v, $s) = ($1, $2, $3, $4);
	    if (lc($p) eq $att && $v ne "") {
		if ($dofrag && $v =~ m"^#") {
		    $v = _FindFragmentMatch($v);
		    my $bp;
		    if (($bp = $opt{base_prefix}) ne "") {
			$v = "\2\3" . $bp . $v;
		    }
		} else {
		    $v = _PrefixURL($v);
		}
		$v = _EncodeAttText($v);
	    }
	    $out .= $p . $q . $v . $s;
	}
	$out .= substr($tag, pos($tag));
	substr($out,0,1) = $g_escape_table{'<'};
	substr($out,-1,1) = $g_escape_table{'>'};
	return $out;
    }

    return $tag;
}


sub _HTMLEncode {
    my $text = shift;

    # Ampersand-encoding based entirely on Nat Irons's Amputator MT plugin:
    #   http://bumppo.net/projects/amputator/
    $text =~ s/&(?!#?[xX]?(?:[0-9a-fA-F]+|\w+);)/&amp;/g;

    # Remaining entities now
    $text =~ s/\042/&quot;/g;
    $text =~ s/\047/&#39;/g; # Some older browsers do not grok &apos;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;

    return $text;
}


sub _EncodeAmps {
    my $text = shift;

    # Ampersand-encoding based entirely on Nat Irons's Amputator MT plugin:
    #   http://bumppo.net/projects/amputator/
    $text =~ s/&(?!#?[xX]?(?:[0-9a-fA-F]+|\w+);)/&amp;/g;

    return $text;
}


sub _EncodeAmpsAndAngles {
# Smart processing for ampersands and angle brackets that need to be encoded.

    my $text = shift;

    # Ampersand-encoding based entirely on Nat Irons's Amputator MT plugin:
    #   http://bumppo.net/projects/amputator/
    $text =~ s/&(?!#?[xX]?(?:[0-9a-fA-F]+|\w+);)/&amp;/g;

    # Encode naked <'s
    $text =~ s{<(?![a-z/?\$!])}{&lt;}gi;
    $text =~ s{<(?=[^>]*$)}{&lt;}g;

    # Encode <'s that cannot possibly be a start or end tag
    $text =~ s{(<[^>]*>)}{_DoTag($1)}ige;

    return $text;
}


sub _EncodeBackslashEscapes {
#
# Parameter: String.
# Returns:   String after processing the following backslash escape sequences.
#
    local $_ = shift;

    s!\\\\!$g_escape_table{'\\'}!go; # Must process escaped backslashes first.
    s{\\([`*_~{}\[\]()>#+\-.!`])}{$g_escape_table{$1}}g;

    return $_;
}


sub _DoAutoLinks {
    local $_ = shift;

    s{<((https?|ftps?):[^'\042>\s]+)>(?!\s*</a>)}{_MakeATag($1, "&lt;".$1."&gt;")}gise;

    # Email addresses: <address@domain.foo>
    s{
	<
	(?:mailto:)?
	(
	    [-.\w]+
	    \@
	    [-a-z0-9]+(\.[-a-z0-9]+)*\.[a-z]+
	)
	>
    }{
	_EncodeEmailAddress(_UnescapeSpecialChars($1), "&#x3c;", "&#62;");
    }egix;

    # (kjm) I don't do "x" patterns
    s{(?:^|(?<=\s))((?:https?|ftps?)://(?:[-a-zA-Z0-9./?\&\%=_~!*;:\@+\$,\x23](?:(?<![.,:;])|(?=[^\s])))+)}
     {_MakeATag($1, $1)}soge;
    s{(?<![][])(?<!\] )\[RFC( ?)([0-9]{1,5})\](?![][])(?! \[)}
     {"["._MakeATag("https://tools.ietf.org/html/rfc$2", "RFC$1$2", "RFC $2")."]"}soge;

    return $_;
}


sub _EncodeEmailAddress {
#
# Input: an email address, e.g. "foo@example.com"
#
# Output: the email address as a mailto link, with each character
#         of the address encoded as either a decimal or hex entity, in
#         the hopes of foiling most address harvesting spam bots. E.g.:
#
#   <a href="&#x6D;&#97;&#105;&#108;&#x74;&#111;:&#102;&#111;&#111;&#64;&#101;
#   x&#x61;&#109;&#x70;&#108;&#x65;&#x2E;&#99;&#111;&#109;">&#102;&#111;&#111;
#   &#64;&#101;x&#x61;&#109;&#x70;&#108;&#x65;&#x2E;&#99;&#111;&#109;</a>
#
# Based on a filter by Matthew Wickline, posted to the BBEdit-Talk
# mailing list: <http://tinyurl.com/yu7ue>
#

    my ($addr, $prefix, $suffix) = @_;
    $prefix = "" unless defined($prefix);
    $suffix = "" unless defined($suffix);

    srand(unpack('N',md5($addr)));
    my @encode = (
	sub { '&#' .		     ord(shift)	  . ';' },
	sub { '&#x' . sprintf( "%X", ord(shift) ) . ';' },
	sub {				 shift		},
    );

    $addr = "mailto:" . $addr;

    $addr =~ s{(.)}{
	my $char = $1;
	if ( $char eq '@' ) {
	    # this *must* be encoded. I insist.
	    $char = $encode[int rand 1]->($char);
	} elsif ( $char ne ':' ) {
	    # leave ':' alone (to spot mailto: later)
	    my $r = rand;
	    # roughly 10% raw, 45% hex, 45% dec
	    $char = (
		$r > .9	  ?  $encode[2]->($char)  :
		$r < .45  ?  $encode[1]->($char)  :
			     $encode[0]->($char)
	    );
	}
	$char;
    }gex;

    # strip the mailto: from the visible part
    (my $bareaddr = $addr) =~ s/^.+?://;
    $addr = _MakeATag("$addr", $prefix.$bareaddr.$suffix);

    return $addr;
}


sub _UnescapeSpecialChars {
#
# Swap back in all the special characters we've hidden.
#
    my $text = shift;

    while( my($char, $hash) = each(%g_escape_table) ) {
	$text =~ s/$hash/$char/g;
    }
    return $text;
}


sub _TokenizeHTML {
#
# Parameter: String containing HTML markup.
# Returns:   Reference to an array of the tokens comprising the input
#            string. Each token is either a tag (possibly with nested,
#            tags contained therein, such as <a href="<MTFoo>">, or a
#            run of text between tags. Each element of the array is a
#            two-element array; the first is either 'tag' or 'text';
#            the second is the actual value.
#
#
# Derived from the _tokenize() subroutine from Brad Choate's MTRegex plugin.
#   <http://www.bradchoate.com/past/mtregex.php>
#

    my $str = shift;
    my $pos = 0;
    my $len = length $str;
    my @tokens;

    my $depth = 6;
    my $nested_tags = join('|', ('(?:<[a-z/!$](?:[^<>]') x $depth) . (')*>)' x $depth);
    my $match = qr/(?s: <! ( -- .*? -- \s* )+ > ) | # comment
		   (?s: <\? .*? \?> ) |		    # processing instruction
		   $nested_tags/iox;		    # nested tags

    while ($str =~ m/($match)/g) {
	my $whole_tag = $1;
	my $sec_start = pos $str;
	my $tag_start = $sec_start - length $whole_tag;
	if ($pos < $tag_start) {
	    push @tokens, ['text', substr($str, $pos, $tag_start - $pos)];
	}
	push @tokens, ['tag', $whole_tag];
	$pos = pos $str;
    }
    push @tokens, ['text', substr($str, $pos, $len - $pos)] if $pos < $len;
    \@tokens;
}


sub _Outdent {
#
# Remove one level of line-leading indent_width of spaces
#
    my $text = shift;

    $text =~ s/^ {1,$opt{indent_width}}//gm;
    return $text;
}


# _DeTab
#
# $1 => input text
# $2 => optional tab width (default is $opt{tab_width})
# $3 => leading spaces to strip off each line first (default is 0 aka none)
# <= result with tabs expanded
sub _DeTab {
    my $text = shift;
    my $ts = shift || $opt{tab_width};
    my $leadsp = shift || 0;
    my $spr = qr/^ {1,$leadsp}/ if $leadsp;
    pos($text) = 0;
    my $end = length($text);
    my $ans = "";
    while (pos($text) < $end) {
	my $line;
	if ($text =~ /\G(.*?\n)/gcs) {
	    $line = $1;
	} else {
	    $line = substr($text, pos($text));
	    pos($text) = $end;
	}
	$line =~ s/$spr// if $leadsp;
	# From the Perl camel book section "Fluent Perl" but modified a bit
	$line =~ s/(.*?)(\t+)/$1 . ' ' x (length($2) * $ts - length($1) % $ts)/ges;
	$ans .= $line;
    }
    return $ans;
}


sub _PrefixURL {
#
# Add URL prefix if needed
#
    my $url = shift;
    $url =~ s/^\s+//;
    $url =~ s/\s+$//;
    $url = "#" unless $url ne "";

    return $url unless $opt{url_prefix} ne '' || $opt{img_prefix} ne '';
    return $url if $url =~ m"^\002\003" || $url =~ m"^#" ||
	    $url =~ m,^//, || $url =~ /^[A-Za-z][A-Za-z0-9+.-]*:/;
    my $ans = $opt{url_prefix};
    $ans = $opt{img_prefix}
	if $opt{img_prefix} ne '' && $url =~ m"^[^#?]*\.(?:png|gif|jpe?g|svgz?)(?:[#?]|$)"i;
    return $url unless $ans ne '';
    $ans .= '/' if substr($ans, -1, 1) ne '/';
    $ans .= substr($url, 0, 1) eq '/' ? substr($url, 1) : $url;
    return "\2\3".$ans;
}


BEGIN {
    $g_style_sheet = <<'STYLESHEET';

<style type="text/css">
/* <![CDATA[ */

/* Markdown.pl fancy style sheet
** Copyright (C) 2017,2018,2019 Kyle J. McKay.
** All rights reserved.
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are met:
**
**   1. Redistributions of source code must retain the above copyright notice,
**      this list of conditions and the following disclaimer.
**
**   2. Redistributions in binary form must reproduce the above copyright
**      notice, this list of conditions and the following disclaimer in the
**      documentation and/or other materials provided with the distribution.
**
**   3. Neither the name of the copyright holder nor the names of its
**      contributors may be used to endorse or promote products derived from
**      this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
** AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
** IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
** ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
** LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
** CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
** SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
** INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
** CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
** ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
** POSSIBILITY OF SUCH DAMAGE.
*/

div.%(base)code-bt > pre, div.%(base)code > pre {
	margin: 0;
	padding: 0;
	overflow: auto;
}

div.%(base)code-bt > pre > code, div.%(base)code > pre > code {
	display: inline-block;
	margin: 0;
	padding: 0.5em 0;
	border-top: thin dotted;
	border-bottom: thin dotted;
}

table.%(base)table {
	margin-bottom: 0.5em;
}
table.%(base)table, table.%(base)table th, table.%(base)table td {
	border-collapse: collapse;
	border-spacing: 0;
	border: thin solid;
}

ol.%(base)ol {
	counter-reset: %(base)item;
}
ol.%(base)ol[start="0"] {
	counter-reset: %(base)item -1;
}
ol.%(base)ol[start="5"] {
	counter-reset: %(base)item 4;
}
ol.%(base)ol[start="10"] {
	counter-reset: %(base)item 9;
}
ol.%(base)ol > span.%(base)ol-incr {
	counter-increment: %(base)item;
}
ol.%(base)ol > span.%(base)ol-incr-2 {
	counter-increment: %(base)item 2;
}
ol.%(base)ol > span.%(base)ol-incr-5 {
	counter-increment: %(base)item 5;
}
ol.%(base)ol > span.%(base)ol-incr-10 {
	counter-increment: %(base)item 10;
}
ol.%(base)lc-greek, li.%(base)lc-greek {
	list-style-type: lower-greek;
}
ol.%(base)ol > li {
	counter-increment: %(base)item;
}
ol.%(base)ol > li.%(base)li,
ol.%(base)ol > li.%(base)li-lc,
ol.%(base)ol > li.%(base)li-lc-greek,
ol.%(base)ol > li.%(base)li-uc {
	list-style-type: none;
	display: block;
}
ol.%(base)ol > li.%(base)li:before,
ol.%(base)ol > li.%(base)li-lc:before,
ol.%(base)ol > li.%(base)li-lc-greek:before,
ol.%(base)ol > li.%(base)li-uc:before {
	position: absolute;
	text-align: right;
	white-space: nowrap;
	margin-left: -9ex;
	width: 9ex;
}
ol.%(base)ol > li.%(base)li[type="1"]:before {
	content: counter(%(base)item, decimal) ")\A0 \A0 ";
}
ol.%(base)ol > li.%(base)li-lc[type="i"]:before,
ol.%(base)ol > li.%(base)li-lc[type="I"]:before {
	content: counter(%(base)item, lower-roman) ")\A0 \A0 ";
}
ol.%(base)ol > li.%(base)li-uc[type="I"]:before,
ol.%(base)ol > li.%(base)li-uc[type="i"]:before {
	content: counter(%(base)item, upper-roman) ")\A0 \A0 ";
}
ol.%(base)ol > li.%(base)li-lc[type="a"]:before,
ol.%(base)ol > li.%(base)li-lc[type="A"]:before {
	content: counter(%(base)item, lower-alpha) ")\A0 \A0 ";
}
ol.%(base)ol > li.%(base)li-lc-greek[type="a"]:before,
ol.%(base)ol > li.%(base)li-lc-greek[type="A"]:before {
	content: counter(%(base)item, lower-greek) ")\A0 \A0 ";
}
ol.%(base)ol > li.%(base)li-uc[type="A"]:before,
ol.%(base)ol > li.%(base)li-uc[type="a"]:before {
	content: counter(%(base)item, upper-alpha) ")\A0 \A0 ";
}

li.%(base)checkbox-on,
li.%(base)checkbox-off {
	list-style-type: none;
	display: block;
}
li.%(base)checkbox-on > span:first-child + span + span,
li.%(base)checkbox-off > span:first-child + span + span {
	position: absolute;
	clip: rect(0,0,0,0);
}
li.%(base)checkbox-on > span:first-child,
li.%(base)checkbox-off > span:first-child,
li.%(base)checkbox-on > span:first-child + span,
li.%(base)checkbox-off > span:first-child + span {
	display: block;
	position: absolute;
	margin-left: -3ex;
	width: 1em;
	height: 1em;
}
li.%(base)checkbox-on > span:first-child > span:first-child,
li.%(base)checkbox-off > span:first-child > span:first-child {
	display: block;
	position: absolute;
	left: 0.75pt; top: 0.75pt; right: 0.75pt; bottom: 0.75pt;
}
li.%(base)checkbox-on > span:first-child > span:first-child:before,
li.%(base)checkbox-off > span:first-child > span:first-child:before {
	display: inline-block;
	position: relative;
	right: 1pt;
	width: 100%;
	height: 100%;
	border: 1pt solid;
	content: "";
}
li.%(base)checkbox-on > span:first-child + span:before {
	position: relative;
	left: 2pt;
	bottom: 1pt;
	font-size: 125%;
	line-height: 80%;
	vertical-align: text-top;
	content: "\2713";
}

/* ]]> */
</style>

STYLESHEET
    $g_style_sheet =~ s/^\s+//g;
    $g_style_sheet =~ s/\s+$//g;
    $g_style_sheet .= "\n";
}

1;

__DATA__

=head1 NAME

Markdown.pl - convert Markdown format text files to HTML

=head1 SYNOPSIS

B<Markdown.pl> [B<--help>] [B<--html4tags>] [B<--htmlroot>=I<prefix>]
    [B<--imageroot>=I<prefix>] [B<--version>] [B<--shortversion>]
    [B<--tabwidth>=I<num>] [B<--stylesheet>] [B<--stub>] [--]
    [I<file>...]

 Options:
   -h                                   show short usage help
   --help                               show long detailed help
   --html4tags                          use <br> instead of <br />
   --deprecated                         allow <dir> and <menu> tags
   --sanitize                           sanitize tag attributes
   --no-sanitize                        do not sanitize tag attributes
   --validate-xml                       check if output is valid XML
   --validate-xml-internal              fast basic check if output is valid XML
   --no-validate-xml                    do not check output for valid XML
   --tabwidth=num                       expand tabs to num instead of 8
   -b prefix | --base=prefix            prepend prefix to fragment-only URLs
   -r prefix | --htmlroot=prefix        append relative non-img URLs to prefix
   -i prefix | --imageroot=prefix       append relative img URLs to prefix
   -w [wikipat] | --wiki[=wikipat]      activate wiki links using wikipat
   -V | --version                       show version, authors, license
                                        and copyright
   -s | --shortversion                  show just the version number
   --raw                                input contains only raw html
   --stylesheet                         output the fancy style sheet
   --no-stylesheet                      do not output fancy style sheet
   --stub                               wrap output in stub document
                                        implies --stylesheet
   --                                   end options and treat next
                                        argument as file

=head1 DESCRIPTION

Markdown is a text-to-HTML filter; it translates an easy-to-read /
easy-to-write structured text format into HTML. Markdown's text format
is most similar to that of plain text email, and supports features such
as headers, *emphasis*, code blocks, blockquotes, and links.

Markdown's syntax is designed not as a generic markup language, but
specifically to serve as a front-end to (X)HTML. You can  use span-level
HTML tags anywhere in a Markdown document, and you can use block level
HTML tags (like <div> and <table> as well).

For more information about Markdown's syntax, see the F<basics.md>
and F<syntax.md> files included with F<Markdown.pl>.

Input (auto-detected) may be either ISO-8859-1 or UTF-8.  Output is always
converted to the UTF-8 character set.


=head1 OPTIONS

Use "--" to end switch parsing. For example, to open a file named "-z", use:

    Markdown.pl -- -z

=over


=item B<--html4tags>

Use HTML 4 style for empty element tags, e.g.:

    <br>

instead of Markdown's default XHTML style tags, e.g.:

    <br />

This option is I<NOT compatible> with the B<--validate-xml> option
and will produce an immediate error if both are given.


=item B<--deprecated>

Both "<dir>" and "<menu>" are normally taken as literal text and the leading
"<" will be automatically escaped.

If this option is used, they are recognized as valid tags and passed through
without being escaped.

When dealing with program argument descriptions "<dir>" can be particularly
problematic therefore use of this option is not recommended.

Other deprecated tags (such as "<font>" and "<center>" for example) continue
to be recognized and passed through even without using this option.


=item B<--sanitize>

Removes troublesome tag attributes from embedded tags.  Only a very strictly
limited set of tag attributes will be permitted, other attributes will be
silently discarded.  The set of allowed attributes varies by tag.

Splits empty minimized elements that are not one of the HTML allowed empty
elements (C<area> C<basefont> C<br> C<col> C<hr> C<img>) into separate begin
and end tags.  For example, C<< <p/> >> or C<< <p /> >> will be split into
C<< <p></p> >>.

Combines adjacent (whitespace separated only) opening and closing tags for
the same HTML empty element into a single minimized tag.  For example,
C<< <br></br> >> will become C<< <br /> >>.

This is enabled by default.


=item B<--no-sanitize>

Do not sanitize tag attributes.  This option does not allow any tags that
would not be allowed without this option, but it does completely suppress
the attribute sanitation process.   If this option is specified, no
attributes will be removed from any tag (although C<img> and C<a> tags will
still be affected by B<--imageroot>, B<--htmlroot> and/or B<--base> options).
Use of this option is I<NOT RECOMMENDED>.


=item B<--validate-xml>

Perform XML validation on the output before it's output and die if
it fails validation.  This requires the C<XML::Simple> or C<XML::Parser>
module be present (one is only required if this option is given).

Any errors are reported to STDERR and the exit status will be
non-zero on XML validation failure.  Note that all line and column
numbers in the error output refer to the entire output that would
have been produced.  Re-run with B<--no-validate-xml> to see what's
actually present at those line and column positions.

If the B<--stub> option has also been given, then the entire output is
validated as-is.  Without the B<--stub> option, the output will be wrapped
in C<< <div>...</div> >> for validation purposes but that extra "div" added
for validation will not be added to the final output.

This option is I<NOT enabled by default>.

This option is I<NOT compatible> with the B<--html4tags> option and will
produce an immediate error if both are given.


=item B<--validate-xml-internal>

Perform XML validation on the output before it's output and die if
it fails validation.  This uses a simple internal consistency checker
that finds unmatched and mismatched open/close tags.

Non-empty elements that in HTML have optional closing tags (C<colgroup>
C<dd> C<dt> C<li> C<p> C<tbody> C<td> C<tfoot> C<th> C<thead> C<tr>)
will automatically have any omitted end tags inserted during the
`--validate-xml-internal` process.

Any errors are reported to STDERR and the exit status will be
non-zero on XML validation failure.  Note that all line and column
numbers in the error output refer to the entire output that would
have been produced before sanitization without any B<--stub> or
B<--stylesheet> options.  Re-run with B<--no-sanitize> and
B<--no-validate-xml> and I<without> any B<--stub> or B<--stylesheet>
options to see what's actually present at those line and column
positions.

This option validates the output I<prior to> adding any requested
B<--stub> or B<--stylesheet>.  As the built-in stub and stylesheet
have already been validated that speeds things up.  The output is
I<NOT> wrapped (in a C<< <div>...</div> >>) for validation as that's
not required for the internal checker.

This option is I<IS enabled by default> unless B<--no-sanitize> is
active.

This option is I<IS compatible> with the B<--html4tags> option.

This option requires the B<--sanitize> option and will produce an
immediate error if both B<--no-sanitize> and B<--validate-xml-internal>
are given.

Note that B<--validate-xml-internal> is I<MUCH faster> than
B<--validate-xml> and I<does NOT> require any extra XML modules to
be present.


=item B<--no-validate-xml>

Do not perform XML validation on the output.  Markdown.pl itself will
normally generate valid XML sequences (unless B<--html4tags> has been
used).  However, any raw tags in the input (that are on the "approved"
list), could potentially result in invalid XML output (i.e. mismatched
start and end tags, missing start or end tag etc.).

Markdown.pl will I<NOT check> for these issues itself.  But with
the B<--validate-xml> option will use C<XML::Simple> or C<XML::Parser>
to do so.

Note that B<--validate-xml-internal> is the default option unless
B<--no-sanitize> is used in which case B<--no-validate-xml> is the
default option.


=item B<--tabwidth>=I<num>

Expand tabs to I<num> character wide tab stop positions instead of the default
8.  Don't use this; physical tabs should always be expanded to 8-character
positions.  This option does I<not> affect the number of spaces needed to
start a new "indent level".  That will always be 4 no matter what value is
used (or implied by default) with this option.  Also note that tabs inside
backticks-delimited code blocks will always be expanded to 8-character tab
stop positions no matter what value is used for this option.

The value must be S<2 <= I<num> <= 32>.


=item B<-b> I<prefix>, B<--base>=I<prefix>

Any fragment-only URLs have I<prefix> prepended.  The default is to prepend
nothing and leave them as bare fragment URLs.  Use of this option may be
necessary when embedding the output of Markdown.pl into a document that makes
use of the C<< <base> >> tag in order for intra-document fragment URL links to
work properly in such a document.


=item B<-r> I<prefix>, B<--htmlroot>=I<prefix>

Any non-absolute URLs have I<prefix> prepended.


=item B<-i> I<prefix>, B<--imageroot>=I<prefix>

Any non-absolute URLs have I<prefix> prepended (overriding the B<-r> prefix
if any) but only if they end in an image suffix.


=item B<-w> [I<wikipat>], B<--wiki>[=I<wikipat>]

Activate wiki links.  Any link enclosed in double brackets (e.g. "[[link]]") is
considered a wiki link.  By default only absolute URL and fragment links are
allowed in the "wiki link style" format.  Any other double-bracketed strings
are left unmolested.

If this option is given, all other wiki links are enabled as well.  Any
non-absolute URL or fragment links will be transformed into a link using
I<wikipat> where the default I<wikipat> if none is given is C<%{s}.html>.

If the given I<wikipat> does not contain a C<%{...}> placeholder sequence
then it will automatically have C<%{s}.html> suffixed to it.

The C<...> part of the C<%{...}> sequence specifies zero or more case-insensitive
single-letter options with the following effects:

=over

=item B<d>

Convert spaces to dashes (ASCII 0x2D) instead of underscore (ASCII 0x5F).  Note
that if this option is given then runs of multiple dashes will be converted to
a single dash I<instead> but runs of multiple underscores will be left untouched.

=item B<f>

Flatten the resulting name by replacing forward slashes (ASCII 0x2F) as well.
They will be converted to underscores unless the C<d> option is given (in which
case they will be converted to dashes).  This conversion takes place before
applying the runs-of-multiple reduction.

=item B<l>

Convert link target (excluding any query string and/or fragment) to lowercase.
Takes precedence over any C<u> option, but specifically excludes C<%>-escapes
which are always UPPERCASE hexadecimal.

=item B<r>

Leave raw UTF-8 characters in the result.  Normally anything not allowed
directly in a URL ends up URL-encoded.  With this option, raw valid UTF-8
sequences will be left untouched.  Use with care.

=item B<s>

After (temporarily) removing any query string and/or fragment, strip any final
"dot" suffix so long as it occurs after the last slash (if any slash was present
before applying the C<f> option).  The "dot" (ASCII 0x2E) and all following
characters (if any) are removed.

=item B<u>

Convert link target (excluding any query string and/or fragment) to UPPERCASE.

=item B<v>

Leave runs-of-multiple characters alone (aka "verbatim").  Does not affect
any of the other options except by eliminating the runs-of-multple reduction
step.  Also does I<not> inhibit the initial whitespace trimming.

=back

The URL target of the wiki link is created by first trimming whitespace
(starting and ending whitespace is removed and all other runs of consecutive
whitespace are replaced with a single space) from the wiki link target,
removing (temporarily) any query string and/or fragment, if no options are
present, spaces are converted to underscores (C<_>) and runs of multiple
consecutive underscores are replaced with a single underscore (ASCII 0x5F).
Finally, the I<wikipat> string gets its first placeholder (the C<%{...}>
sequence) replaced with this computed value and the original query string
and/or fragment is re-appended (if any were originally present) and
URL-encoding is applied as needed to produce the actual final target URL.

See above option descriptions for possible available modifications.

One of the commonly used hosting platforms does something substantially similar
to using C<%{dfrsv}> as the placeholder.


=item B<-V>, B<--version>

Display Markdown's version number and copyright information.


=item B<-s>, B<--shortversion>

Display the short-form version number.


=item B<--raw>

Input contains only raw HTML/XHTML.  All options other than
B<--html4tags>, B<--deprecated>, B<--sanitize> (on by default),
B<--validate-xml> and B<--validate-xml-internal> (and their B<--no-...>
variants) are ignored.

With this option, arbitrary HTML/XHTML input can be passed through
the sanitizer and/or validator.  If sanitation is requested (the
default), input must only contain the contents of the "<body>"
section (i.e. no "<head>" or "<html>").  Output I<will> be converted
to UTF-8 regardless of the input encoding.  All line endings will
be normalized to C<\n> and input encodings other than UTF-8 or
ISO-8859-1 or US-ASCII will end up mangled.

Remember that any B<--stub> and/or B<--stylesheet> options are
I<completely ignored> when B<--raw> is given.


=item B<--stylesheet>

Include the fancy style sheet at the beginning of the output (or in the
C<head> section with B<--stub>).  This style sheet makes fancy checkboxes
and makes a right parenthesis C<)> show instead of a C<.> for ordered lists
that use them.  Without it things will still look fine except that the
fancy stuff won't be there.

Use this option with no other arguments and redirect standard input to
/dev/null to get just the style sheet and nothing else.


=item B<--no-stylesheet>

Overrides a previous B<--stylesheet> and disables implicit inclusion
of the style sheet by the B<--stub> option.


=item B<--stub>

Wrap the output in a full document stub (i.e. has C<html>, C<head> and C<body>
tags).  The style sheet I<will> be included in the C<head> section unless the
B<--no-stylesheet> option is also used.


=item B<-h>, B<--help>

Display Markdown's help.  With B<--help> full help is shown, with B<-h> only
the usage and options are shown.


=back


=head1 VERSION HISTORY

Z<> See the F<README> file for detailed release notes for this version.

=over

=item Z<> 1.1.9 - 15 Dec 2019

=item Z<> 1.1.8 - 22 Nov 2019

=item Z<> 1.1.7 - 14 Feb 2018

=item Z<> 1.1.6 - 03 Jan 2018

=item Z<> 1.1.5 - 07 Dec 2017

=item Z<> 1.1.4 - 24 Jun 2017

=item Z<> 1.1.3 - 13 Feb 2017

=item Z<> 1.1.2 - 19 Jan 2017

=item Z<> 1.1.1 - 12 Jan 2017

=item Z<> 1.1.0 - 11 Jan 2017

=item Z<> 1.0.4 - 05 Jun 2016

=item Z<> 1.0.3 - 06 Sep 2015

=item Z<> 1.0.2 - 03 Sep 2015

=item Z<> 1.0.1 - 14 Dec 2004

=item Z<> 1.0.0 - 28 Aug 2004

=back

=head1 AUTHORS

=over

=item John Gruber

=item L<http://daringfireball.net>

=item L<http://daringfireball.net/projects/markdown/>

=item E<160>

=back

=over

=item PHP port and other contributions by Michel Fortin

=item L<http://michelf.com>

=item E<160>

=back

=over

=item Additional enhancements and tweaks by Kyle J. McKay

=item mackyle<at>gmail.com

=back

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2003-2004 John Gruber

=item Copyright (C) 2015-2019 Kyle J. McKay

=item All rights reserved.

=back

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

=over

=item *

Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

=item *

Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

=item *

Neither the name "Markdown" nor the names of its contributors may
be used to endorse or promote products derived from this software
without specific prior written permission.

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
