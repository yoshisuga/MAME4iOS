========
Markdown
========

Version 1.1.9

John Gruber  
Kyle J. McKay


------------
Introduction
------------

Markdown is a text-to-HTML conversion tool for web writers. Markdown
allows you to write using an easy-to-read, easy-to-write plain text
format, then convert it to structurally valid XHTML (or HTML).

Thus, "Markdown" is two things: a plain text markup syntax, and a
software tool, written in Perl, that converts the plain text markup
to HTML.

Markdown works both as a Movable Type plug-in and as a standalone Perl
script -- which means it can also be used as a text filter in BBEdit
(or any other application that supporst filters written in Perl).

Full documentation of Markdown's syntax and configuration options is
available in the `basics.md` and `syntax.md` files.
(Note: this readme file and the basics and syntax files are formatted
in Markdown.)


-----------------------------
Installation and Requirements
-----------------------------

Markdown requires Perl 5.8.0 or later. Welcome to the 21st Century.
Markdown also requires the standard Perl library module `Digest::MD5`.

As of version 1.1.1, Markdown auto-detects the character set of the
input (US-ASCII, ISO-8859-1 and UTF-8 are supported) and always
converts the input to UTF-8 when writing the output.


Movable Type
~~~~~~~~~~~~

Markdown works with Movable Type version 2.6 or later (including
MT 3.0 or later).

1.  Copy the "Markdown.pl" file into your Movable Type "plugins"
    directory. The "plugins" directory should be in the same directory
    as "mt.cgi"; if the "plugins" directory doesn't already exist, use
    your FTP program to create it. Your installation should look like
    this:

        (mt home)/plugins/Markdown.pl

2.  Once installed, Markdown will appear as an option in Movable Type's
    Text Formatting pop-up menu. This is selectable on a per-post basis.
    Markdown translates your posts to HTML when you publish; the posts
    themselves are stored in your MT database in Markdown format.

3.  If you also install SmartyPants 1.5 (or later), Markdown will offer
    a second text formatting option: "Markdown with SmartyPants". This
    option is the same as the regular "Markdown" formatter, except that
    automatically uses SmartyPants to create typographically correct
    curly quotes, em-dashes, and ellipses. See the SmartyPants web page
    for more information: <http://daringfireball.net/projects/smartypants/>

4.  To make Markdown (or "Markdown with SmartyPants") your default
    text formatting option for new posts, go to Weblog Config ->
    Preferences.

Note that by default, Markdown produces XHTML output. To configure
Markdown to produce HTML 4 output, see "Configuration", below.


Blosxom
~~~~~~~

Markdown works with Blosxom version 2.x.

1.  Rename the "Markdown.pl" plug-in to "Markdown" (case is
    important). Movable Type requires plug-ins to have a ".pl"
    extension; Blosxom forbids it.

2.  Copy the "Markdown" plug-in file to your Blosxom plug-ins folder.
    If you're not sure where your Blosxom plug-ins folder is, see the
    Blosxom documentation for information.

3.  That's it. The entries in your weblog will now automatically be
    processed by Markdown.

4.  If you'd like to apply Markdown formatting only to certain posts,
    rather than all of them, see Jason Clark's instructions for using
    Markdown in conjunction with Blosxom's Meta plugin:

    <http://jclark.org/weblog/WebDev/Blosxom/Markdown.html>


BBEdit
~~~~~~

Markdown works with BBEdit 6.1 or later on Mac OS X. (It also works
with BBEdit 5.1 or later and MacPerl 5.6.1 on Mac OS 8.6 or later.)

1.  Copy the "Markdown.pl" file to appropriate filters folder in your
    "BBEdit Support" folder. On Mac OS X, this should be:

        BBEdit Support/Unix Support/Unix Filters/

    See the BBEdit documentation for more details on the location of
    these folders.

    You can rename "Markdown.pl" to whatever you wish.

2.  That's it. To use Markdown, select some text in a BBEdit document,
    then choose Markdown from the Filters sub-menu in the "#!" menu, or
    the Filters floating palette


-------------
Configuration
-------------

By default, Markdown produces XHTML output for tags with empty elements.
E.g.:

      <br />

Markdown can be configured to produce HTML-style tags; e.g.:

      <br>


Movable Type
~~~~~~~~~~~~

You need to use a special `MTMarkdownOptions` container tag in each
Movable Type template where you want HTML 4-style output:

    <MTMarkdownOptions output='html4'>
        ... put your entry content here ...
    </MTMarkdownOptions>

The easiest way to use MTMarkdownOptions is probably to put the
opening tag right after your `<body>` tag, and the closing tag right
before `</body>`.

To suppress Markdown processing in a particular template, i.e. to
publish the raw Markdown-formatted text without translation into
(X)HTML, set the `output` attribute to 'raw':

    <MTMarkdownOptions output='raw'>
        ... put your entry content here ...
    </MTMarkdownOptions>


Command-Line
~~~~~~~~~~~~

Use the `--html4tags` command-line switch to produce HTML output from a
Unix-style command line. E.g.:

    % perl Markdown.pl --html4tags foo.txt

Type `perldoc Markdown.pl`, or read the POD documentation within the
Markdown.pl source code for more information.


---------------
Version History
---------------

1.1.9 (15 Dec 2019):

* improve bare fragment URL link handling and add fragment `--base` option

* match block tags case-insensitively and relax `<hr>` matching rules


1.1.8 (22 Nov 2019):

* correct a number of issues with improperly nested markup involving
  links, blockquotes, strong and emphasis etc.

* parse nested `[`...`]` and `(`...`)` properly when inside links

* avoid getting confused by nested lists

* allow first blockquote line to be empty

* as-documented single-quote titles in link definitions now work

* when escaping a single-quote use `&#39;` instead of `&apos;`

* ignore control characters in input (other than whitespace)

* wiki links can be processed by providing a new `--wiki` option

* an empty table header row is omitted from the output

* table rows can be joined with a trailing `\` (see syntax.md)

* add several new XML validation options

* perform XML validation and tag sanitation by default (see help)

* tab expansion in shifted backticks-delimited code blocks has
  been adjusted to better match expected behavior

* all atx-style header levels now get anchors not just levels 1-3

* internal document "fragment" links `[...](#section)` hook up to
  the target section much more reliably now

* backticks-delimited code blocks can now specify a syntax language
  name that ends with a `#` character

* more lists that were not being recognized before because they did
  not have a preceding blank line are now recognized


1.1.7 (14 Feb 2018):

* Markdown.pl: _PrefixURL more intelligently


1.1.6 (03 Jan 2018):

* Markdown.pl: be more flexible parsing backticks-delimited code blocks

* Markdown.pl: improve XML comment parsing

* Markdown.pl: correct .svg extension matching rule

* Markdown.pl: apply -i and -r options to a and img tags


1.1.5 (07 Dec 2017):

* Markdown.pl: support tables

* Markdown.pl: make sure all alt= and title= text is escaped


1.1.4 (24 Jun 2017):

+ Markdown.pl: disallow <dir> and <menu> without --deprecated


1.1.3 (13 Feb 2017):

+ Markdown.pl: auto escape '<' of non-tags

+ Markdown.pl: do not overlook sibling list items


1.1.2 (19 Jan 2017):

+ Markdown.pl: usually (i), (v) and (x) are roman

+ Markdown.pl: retain square brackets around footnotes

+ Markdown.pl: treat '*' in `<ol>` like last marker

+ Markdown.pl: normalize link white space

+ Markdown.pl: do not mishandle double list markers redux

+ Markdown.pl: recognize two ```-delimited blocks in a row

+ Markdown: allow trailing '[]' to be omitted

+ Markdown.pl: tweak code block output again


1.1.1 (12 Jan 2017):

+ Markdown.pl: support lower-greek ol lists

+ Markdown.pl: auto-detect latin-1/utf-8 input always output utf-8  
  The minimum version of Perl required is now 5.8.0.


1.1.0 (11 Jan 2017):

+ Markdown.pl: handle some limited [[wiki style links]]

+ Markdown.pl: add --stub, --stylesheet and --tabwidth options

+ Markdown.pl: support more list markers

+ Markdown.pl: format fancy checkboxes

+ Markdown.pl: add anchors and definitions for headers

+ Markdown.pl: do not mishandle double list markers

+ Markdown.pl: handle non-backticks-delimited code blocks properly

+ Markdown.pl: recognize top-level lists better

+ Markdown.pl: output deterministic documents

+ Markdown.pl: auto linkify without '<'...'>'


1.0.4 (05 Jun 2016):

+ Markdown.pl can now be require'd and the Markdown function called
  repeatedly by external code.

+ Backticks (```) delimited code blocks are now handled better and are
  no longer subject to any further accidental processing.


1.0.3 (06 Sep 2015):

+ Added support for --htmlroot option to set a URL prefix.

+ Relaxed matching rule for non-indented code blocks.

+ Added support for --imageroot option to set an img URL prefix.


1.0.2 (03 Sep 2015):

+ Added support for -h and --help to display Markdown.pl help.

+ Added support for third-level headers using setext-like
  underlining using tildes (`~`'s).

+ Added support for an optional overline using the same character
  as the underline when using setext-style headers.

+ Stopped recognizing `_` within words.  The `*` character is still
  recognized within words.

+ Added support for strike through text using `~~` similarly to the
  way strong works using `**`.

+ Added support for non-indended code blocks by preceding and following
  them with a line consisting of 3 backtick quotes (`` ` ``) or more.


1.0.1 (14 Dec 2004):

+ Changed the syntax rules for code blocks and spans. Previously,
  backslash escapes for special Markdown characters were processed
  everywhere other than within inline HTML tags. Now, the contents
  of code blocks and spans are no longer processed for backslash
  escapes. This means that code blocks and spans are now treated
  literally, with no special rules to worry about regarding
  backslashes.

  **NOTE**: This changes the syntax from all previous versions of
  Markdown. Code blocks and spans involving backslash characters
  will now generate different output than before.

+ Tweaked the rules for link definitions so that they must occur
  within three spaces of the left margin. Thus if you indent a link
  definition by four spaces or a tab, it will now be a code block.

           [a]: /url/  "Indented 3 spaces, this is a link def"

            [b]: /url/  "Indented 4 spaces, this is a code block"

  **IMPORTANT**: This may affect existing Markdown content if it
  contains link definitions indented by 4 or more spaces.

+ Added `>`, `+`, and `-` to the list of backslash-escapable
  characters. These should have been done when these characters
  were added as unordered list item markers.

+ Trailing spaces and tabs following HTML comments and `<hr/>` tags
  are now ignored.

+ Inline links using `<` and `>` URL delimiters weren't working:

          like [this](<http://example.com/>)

+ Added a bit of tolerance for trailing spaces and tabs after
  Markdown hr's.

+ Fixed bug where auto-links were being processed within code spans:

          like this: `<http://example.com/>`

+ Sort-of fixed a bug where lines in the middle of hard-wrapped
  paragraphs, which lines look like the start of a list item,
  would accidentally trigger the creation of a list. E.g. a
  paragraph that looked like this:

          I recommend upgrading to version
          8. Oops, now this line is treated
          as a sub-list.

  This is fixed for top-level lists, but it can still happen for
  sub-lists. E.g., the following list item will not be parsed
  properly:

          + I recommend upgrading to version
            8. Oops, now this line is treated
            as a sub-list.

  Given Markdown's list-creation rules, I'm not sure this can
  be fixed.

+ Standalone HTML comments are now handled; previously, they'd get
  wrapped in a spurious `<p>` tag.

+ Fix for horizontal rules preceded by 2 or 3 spaces.

+ `<hr>` HTML tags in must occur within three spaces of left
  margin. (With 4 spaces or a tab, they should be code blocks, but
  weren't before this fix.)

+ Capitalized "With" in "Markdown With SmartyPants" for
  consistency with the same string label in SmartyPants.pl.
  (This fix is specific to the MT plug-in interface.)

+ Auto-linked email address can now optionally contain
 a 'mailto:' protocol. I.e. these are equivalent:

          <mailto:user@example.com>
          <user@example.com>

+ Fixed annoying bug where nested lists would wind up with
  spurious (and invalid) `<p>` tags.

+ You can now write empty links:

          [like this]()

  and they'll be turned into anchor tags with empty href attributes.
  This should have worked before, but didn't.

+ `***this***` and `___this___` are now turned into

          <strong><em>this</em></strong>

  Instead of

          <strong><em>this</strong></em>

  which isn't valid. (Thanks to Michel Fortin for the fix.)

+ Added a new substitution in `_EncodeCode()`: `s/\$/&#036;/g`;
  this is only for the benefit of Blosxom users, because Blosxom
  (sometimes?) interpolates Perl scalars in your article bodies.

+ Fixed problem for links defined with urls that include parens, e.g.:

          [1]: http://sources.wikipedia.org/wiki/Middle_East_Policy_(Chomsky)

  "Chomsky" was being erroneously treated as the URL's title.

+ At some point during 1.0's beta cycle, I changed every sub's
  argument fetching from this idiom:

          my $text = shift;

  to:

          my $text = shift || return '';

  The idea was to keep Markdown from doing any work in a sub
  if the input was empty. This introduced a bug, though:
  if the input to any function was the single-character string
  "0", it would also evaluate as false and return immediately.
  How silly. Now fixed.


---------------------
Copyright and License
---------------------

Copyright (C) 2003-2004 John Gruber  
Copyright (C) 2015-2018 Kyle J. McKay  
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

* Neither the name "Markdown" nor the names of its contributors may
  be used to endorse or promote products derived from this software
  without specific prior written permission.

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
