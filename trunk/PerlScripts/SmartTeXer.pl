#!/usr/bin/perl

use File::Basename;
#use File::Copy;

$progname = "$0";
$version = "V3.3";
$copyright = "Copyright (C) 2008-2009 Instanton";

$istexfile = 0;
$need_help=0;

@cmd2dvi=("tex","latex","xetex","xelatex","texexec");
@cmd2pdf=("pdftex","pdflatex","xetex","xelatex","texexec");
@cmd2htm=("httex","htlatex","htxetex","htxelatex","htcontext");
@cmds=(@cmd2dvi, @cmd2pdf, @cmd2htm);

@dvi2pdfcmds1=("dvipdfm","dvipdfm","xdvipdfmx","xdvipdfmx","dvipdfm");
@dvi2pdfcmds2=("dvipdfmx","dvipdfmx","xdvipdfmx","xdvipdfmx","dvipdfmx");
@dvipdfcmds=(@dvi2pdfcmds1, @dvi2pdfcmds2);

$jumpstep=5;

$dvips=$dvipdfm=$dvipdfmx=$latex=$label=$hyperref=$index=$bibtex=$cjk=$texrunonce=$preview=$ps2pdf=0;
$jump=$shift=$pointer=$nonstop=$syncpdf=0;

$texbin="";
$verbose=1;
$countrun=1;

sub usage
{
	print <<EOF;
$progname $version: Smart compiler for tex files. $copyright
Usage:   $progname [-options] [foo.tex|-source=foo.ext]
Available options:
  [--help|-h]	 	Gives this usage text;
  [--version|-v]	Gives version number and copyright information;
  [-once]		Stop compilation after the first run, useful when 
			checking errors. Can be used in combination with other
			options;
  [-nonstopmode]	Force continue while error occurs (not for -html);
  [--texbinpath=...|-tp=...]
			Specify the bin path of your tex release. Useful when
			the TeX bin folder is not in %path%;
  [-quiet]		Turn off compiling messages;
  [--preview|-view]	Preview output using default previewer (which  
			has no effect if the output is an xdv file);
  [-dvi]		Output dvi or xdv file. This option is default;
  [-dvips]		Output ps file;
  [-pdf|-dvipdfm(x)|-ps2pdf]
			Output pdf file using different methods;
  [-synctex]		Enable synctex (works only if -pdf is present);
  [-htm(l)]		Output html files. The html output will be placed 
			in the file.tex-htmlpage subdirectory.
The last 4 lines of options are mutually exclusive.
EOF
}

sub version
{
	print <<EOF;

$progname $version: smart compiler for tex files in one step
$copyright

This program comes with ABSOLUTELY NO WARRANTY.  This is free software, 
you are welcome to redistribute it under the terms of the GNU General 
Public License.

For help on usage of this program type $progname --help or $progname -h.  

EOF
}

foreach $arg (@ARGV)
{
#	$arg=~ tr/[A-Z]/[a-z]/;
	if($arg eq "-preview")
	{
		$preview=1;
	}
	if(($arg eq "-h") || ($arg eq "--help")) 
	{
		$need_help=1;
	}
	elsif(($arg eq "-v") || ($arg eq "--version"))
	{
		version();
		exit;
	}
	elsif($arg eq "-once")
	{
		$texrunonce=1;
	}
	elsif($arg =~ /--texbinpath=/)
	{
	$arg=~ s/(--texbinpath=)(.+)/$2/;
	$texbin="\"$arg\\\"";
	}
	elsif($arg =~ /-tp=/)
	{
	$arg=~ s/(-tp=)(.+)/$2/;
	$texbin="\"$arg\\\"";
	}
	elsif($arg eq "-quiet")
	{
		$verbose=0;
	}
	elsif($arg eq "-nonstopmode")
	{
		$nonstop=1;
	}
	elsif(($arg eq "-view")||($arg eq "--preview"))
	{
		$preview=1;
	}
	elsif($arg eq "-dvips")
	{
		$dvips=1;
	}
	elsif($arg eq "-ps2pdf")
	{
		$ps2pdf=1;
	}
	elsif($arg eq "-synctex")
	{
		$syncpdf=1;
	}
	elsif($arg eq "-dvipdfm")
	{
		$dvipdfm=1;
	}
	elsif($arg eq "-dvipdfmx")
	{
		$dvipdfmx=1;
		$shift=$jumpstep;
	}
	elsif($arg eq "-dvi")
	{
		$jump=0;
	}
	elsif($arg eq "-pdf")
	{
		$jump=$jumpstep;
	}
	elsif($arg eq "-htm" || $arg eq "-html")
	{
		$jump=2*$jumpstep;
	}
	elsif($arg =~ /-source=/)
	{
		$file="$arg";
		$file =~ s/(-source=)(.+)/$2/;
		$filebase="$file";
		$filebase=~ s/(.*)(\.)(.*)/$1/;
		$istexfile=1;
	}
	elsif($arg =~ m/\.tex/)
	{
		$file="$arg";
		$filebase="$arg";
		$filebase=~ s/(.*)(\.tex)/$1/;
		$istexfile=1;
	}
	else
	{
		print "\nInvalid option or not a tex file!\nType SmartTeXer -h or SmartTeXer --help for usage info.\n";
		exit;
	}
}
if((! $istexfile) || $need_help)
{ 
    usage();
    exit;
}
if(!(-e $file))
{
	print "\n$file not found!\n";
	exit;
}

$preamble="__preamble.tex";
open(PREAMBLE,">$preamble") || die;
open(INPUT_TEX,"$file") || die;
while (<INPUT_TEX>) 
  {
    if (!/\\pagestyle/ && !/\\begin{document}/) 
    {
		print PREAMBLE;
    }
    last if /\\begin{document}/
  }
close(INPUT_TEX); 
close(PREAMBLE); 



open(F, "<${file}");
	@filecontents = <F>;
close(F);

foreach $fileline (@filecontents)
{
	chop($fileline);
	if(!(($fileline =~ /^%/)||($fileline =~ /(^\s+)(%)/)))
	{
		if($fileline =~ /(\\documentclass|\\documentstyle)/)
		{
			$latex=1;
			$pointer=1;
		}
		if($fileline =~ m/(\\begin)(.*)({GBK})/)
		{
			$gbk=1;
		}
		if($fileline =~ m/(\\ref|\\autoref|\\cite|\\tableofcontents|\\listoffigures\\listoftables)/)
		{
			$label=1;
		}
		if($fileline =~ m/(\\bibliography)/)
		{
			$bibtex=1;
		}
		if(!latex)
		{
			if($fileline =~ /(\\XeTeX)(inputencoding|defaultencoding)/)
			{
				$pointer=2;
			}
			if($fileline =~ m/(\\starttext|\\usemodule)/)
			{
				$pointer=4;
			}
				if($fileline =~ m/(\\setup|\\define|\\place)/)
			{
				$pointer=4;
			}
		}
	}
}

undef @filecontents;

if($latex)
{
	open(PREAMBLE, "<$preamble");
		@filecontents = <PREAMBLE>;
	close(PREAMBLE);
	foreach $fileline (@filecontents)
	{
		chop($fileline);
		if(!(($fileline =~ /^%/)||($fileline =~ /(^\s+)(%)/)))
		{
			if($fileline =~ /(\\XeTeX)(inputencoding|defaultencoding)/)
			{
				$pointer=3;
			}
			if($fileline =~ m/(\\usepackage)(.*)(fontspec|xunicode|xltxtra|zhspacing|xeCJK|xCJK|xCCT)/)
			{
				$pointer=3;
			}
			if($fileline =~ /\\input{ctex4xetex.cfg}/)
			{
				$pointer=3;
			}
			if($fileline =~ m/(\\documentclass)(.*)({ctex}|{cctart}|{cctbook}|{cctrep}|{ctexart}|{ctexbook}|{ctexrep}|{CASthesis})/)
			{
				$gbk=1;
			}
			if($fileline =~ m/(\\usepackage)(.*)({ctex})/)
			{
				$gbk=1;
			}
		}
	}
	undef @filecontents;
	unlink($preamble);
}

@modifierdvi=("-src-specials","-src-specials","-no-pdf","-no-pdf", "");
@modifierpdf=("","","","","--pdf");
@modifier=(@modifierdvi, @modifierpdf);

if(($jump eq $jumpstep) && $syncpdf){
	$syncmodifier="-synctex=-1";
}
else{
	$syncmodifier="";
}

if($nonstop){
	$modifier2="-interaction=nonstopmode";
}
else{
	$modifier2="";
}

$pointer=$pointer+$jump;

if($jump>$jumpstep)
{
	@command=("$texbin@cmds[$pointer]", "$filebase");
	if($verbose) {system(@command)} else {$exec=`@command`};
	
	mkdir("$file-htmlpage");
	$clean="tidy.bat";
	open(CLEAN,">$clean");
	print CLEAN "move /y $filebase.html $file-htmlpage\n";
	print CLEAN "move /y $filebase.css $file-htmlpage\n";
	print CLEAN "move /y *.png $file-htmlpage\n"; 
	close(CLEAN);
	chmod 0755, $clean;
	$exec=`$clean`;
	unlink $clean;
	
	@cmdsummary=("$texbin@cmds[$pointer] $file");
}
else
{
	@command=("$texbin@cmds[$pointer]", "@modifier[$pointer]", $modifier2, $syncmodifier, "$file");
	if($verbose) {system(@command)} else {$exec=`@command`};

	$modifier_str=" @modifier[$pointer] $modifier2 ";
	$modifier_str=~ s/\s+/" "/;
	$modifier_str=~ s/(")(.*)(")/$2/;
	@cmdsummary=("$texbin@cmds[$pointer]$modifier_str$file");

	if(! $texrunonce)
	{
		open(F, "<$filebase.idx");
		@fileidx = <F>;
		close(F);

		foreach $fileline (@fileidx)
		{
			chop($fileline);
			if($fileline =~ /(\\indexentry)/)
			{
				$index=1;
			}
		}
		undef @fileidx;

		if($label)
		{
			$oncemore=1;
		}
		if($latex)
		{
			if($bibtex)
			{
				$bibtexbin="bibtex";
				@bibtex=("$texbin$bibtexbin", "$filebase");
				if($verbose) {system(@bibtex)} else {$exec=`@bibtex`};
				@cmdsummary=(@cmdsummary,"$texbin$bibtexbin $filebase");
			
				if($verbose) {system(@command)} else {$exec=`@command`};
				$countrun++;
				@cmdsummary=(@cmdsummary,@cmdsummary[0]);
				$oncemore=1;
			}
			elsif($index)
			{
				if($verbose) {system(@command)} else {$exec=`@command`};
				$countrun++;
				@cmdsummary=(@cmdsummary,@cmdsummary[0]);
			
				$makeindexbin="makeindex";
				@mkidx=("$texbin$makeindexbin", "$filebase");
				if($verbose) {system(@mkidx)} else {$exec=`@mkidx`};
				$oncemore=1;
				@cmdsummary=(@cmdsummary,"$texbin$makeindexbin $filebase");
			}
		}
		if($gbk && (-e "$filebase.out"))
		{
			$gbk2unibin="gbk2uni";
			@gbkuni=("$texbin$gbk2unibin", "$filebase.out");
			if($verbose) {system(@gbkuni)} else {$exec=`@gbkuni`};
			$oncemore=1;
			@cmdsummary=(@cmdsummary,"$texbin$gbk2unibin $filebase.out");
		}
		if($oncemore)
		{
			if($verbose) {system(@command)} else {$exec=`@command`};
			$countrun++;
			@cmdsummary=(@cmdsummary,@cmdsummary[0]);
		}
	}
}
if(($dvipdfm ||$dvipdfmx) && (-e "$filebase.dvi"))
{
	@command=("$texbin@dvipdfcmds[$shift+$pointer]", "$filebase.dvi");
	if($verbose) {system(@command)} else {$exec=`@command`};
	
	@cmdsummary=(@cmdsummary,"$texbin@dvipdfcmds[$shift+$pointer] $filebase.dvi");
}
elsif(($dvips) && (-e "$filebase.dvi"))
{
	$dvipscmd="dvips";
	@command=("$texbin$dvipscmd", "$filebase.dvi");
	if($verbose) {system(@command)} else {$exec=`@command`};
	
	@cmdsummary=(@cmdsummary,"$texbin$dvipscmd $filebase.dvi");
}
elsif(($ps2pdf) && (-e "$filebase.dvi"))
{
	$dvipscmd="dvips";
	@command=("$texbin$dvipscmd", "$filebase.dvi");
	if($verbose) {system(@command)} else {$exec=`@command`};
	
	@cmdsummary=(@cmdsummary,"$texbin$dvipscmd $filebase.dvi");

	$ps2pdfcmd="ps2pdf";
	@command=("$texbin$ps2pdfcmd", "$filebase.ps");
	if($verbose) {system(@command)} else {$exec=`@command`};
	
	@cmdsummary=(@cmdsummary,"$texbin$ps2pdfcmd $filebase.ps");
}

if($preview)
{
	if($dvipdfm ||$dvipdfmx ||($jump eq $jumpstep)||$ps2pdf)
	{
		if(-e "$filebase.pdf")
		{
			@command=("start","$filebase.pdf");
			system(@command);
			@cmdsummary=(@cmdsummary,"start $filebase.pdf");
		}
		else
		{
			@cmdsummary=(@cmdsummary,"start $filebase.pdf failed: file $filebase.pdf doesn't exist.");
		}
	}
	elsif($dvips) 
	{
		if(-e "$filebase.ps")
		{
			@command=("start","$filebase.ps");
			system(@command);
			@cmdsummary=(@cmdsummary,"start $filebase.ps");
		}
		else
		{
			@cmdsummary=(@cmdsummary,"start $filebase.ps failed: file $filebase.ps doesn't exist.");
		}
	}
	elsif($jump eq 0)
	{
		if(-e "$filebase.dvi")
		{
			@command=("start","$filebase.dvi");
			system(@command);
			@cmdsummary=(@cmdsummary,"start $filebase.dvi");
		}
		else
		{
			@cmdsummary=(@cmdsummary,"start $filebase.dvi failed: file $filebase.dvi doesn't exist.");
		}
	}
	elsif($jump eq 2*$jumpstep)
	{
		if(-e "$file-htmlpage\\$filebase.html")
		{
			@command=("start","$file-htmlpage\\$filebase.html");
			system(@command);
			@cmdsummary=(@cmdsummary,"start $file-htmlpage\\$filebase.html");
		}
		else
		{
			@cmdsummary=(@cmdsummary,"start $filebase.html failed: file $filebase.html doesn't exist.");
		}
	}
}
print "\n------------------ SmartTeXer execution summary ------------------\n";
print "Source file compiled $countrun time(s). Commands executed:\n";
foreach $cmd(@cmdsummary)
{
	print  "$cmd \n";
}
print "\n";
exit;