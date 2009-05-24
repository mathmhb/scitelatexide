#! /usr/bin/env perl
# -*- coding: utf-8 -*-

# V1.6 修订：
#	修正updmapcfg选项的错误（map文件名及选项激活开关两处问题）;
#	修正生成*_pt1.map的流程，在不配置Type1字体的时候不再产生空的*_pt1.map文件;
#	采用新的*_ttf.map文件格式，不再生成enc文件;
#	增加依赖包，允许在Windows下编译执行。

# V1.5 修订：
#	$outstream会在map文件中产生一些不合理的符号">"，已删除所有$outstream。代价是
#	    verbose mode产生的输出信息会减少;
#	Type1字体的生成很费时间，加强了已存在字体的检查，避免重复生成;
#	采纳aloft自动从pfb文件获取psname的技术，废止参数-psname。
#	
# 2009/05/24 instanton

# milksea 修订：
#	更改文件路径的位置，以适合标准的 TeXLive TDS；
#	按 linux 作了少量修改；
#	针对 TTF 或 Type1 字体选择生成 map 文件，不再多余生成；
#	更改路径名为 / 分隔，加强兼容性；
#	加强了对已安装字体的检测；
#	忽略 TTC 字体的 -Type1 选项；
#	增加 -verbose 选项，可输出更多提示信息；
#	改变了 -updmap 选项的功能，直接调用 updmap 程序，原来的改为 -updmapcfg；
#	更正了原来程序中的一些 bug。
# 2008/10/18

use File::Basename;
use File::Path;
use File::Copy;
use File::DosGlob 'glob';
@flist = glob "*.*";


$progname = "$0";
$version = "V1.6+";
$copyright = "Copyright (C) 2008-2009 Instanton";
$contributions = "Contributions from milksea and aloft included";

$need_help=0;
$lead=9;
$md_afm=$md_type1=$mv_afm=$mv_type1=$extra_run=$stemv="";
$genslanted=0;
$slant="sl";

$ttfdir = "$ENV{'SYSTEMROOT'}/Fonts";
$ttfdir =~ s/\\/\//;	# 文件路径用斜线 / 代替反斜线 \
$destdir = "./Fonts";
$updmap = 0;
$updmapcfg = 0;

$pfb=0;
$ttfname=0;
$familyname=0;
$ttfsuffix="_ttf";
$pt1suffix="_pt1";

$cjkmapbase="cjk";

$verbose=0;

## default GBK encoding settings: 
$encoding="GBK";
$pre="gbk";
$switches="-GFAe -L cugbk0.map+";
@range1=@range2=(0..9);
$Uenc="UGBK";
$set_dim=$set2_dim=10;
$fdpre="c19";
$CJKnormal="";
$fddir="GBK";

sub usage
{
    print <<EOF;
FontsGen $version: Configure Chinese fonts for TeX system 
$copyright
$contributions

Usage: $progname [-options]
Avaliable options:

  [-encoding=...]	  Set encoding of fonts. Supported encodings 
			  are GBK, UTF8 and Big5. Defaults to GBK;
  [-prefix=...]	  	  Prefix for CJK fonts. Defaults to gbk for GBK 
			  encoding, uni for UTF8 and b5 for Big5 encodings;
  [-ttf=....ttf/c]	  Specify name of the TrueType fonts;
  [-CJKname=...]	  CJKfamily name of the generated fonts;
  [-cjkmap=...]	  	  Base name of the .map file to be placed under
			  Fonts\/map. Defaults to be cjk (corresponds to 
			  cjk_pt1.map for Type1 and cjk_ttf.map for TrueType);
  [-slanted=y|n]	  Whether to generate slanted fonts. Defaults to no.
  [-ttfdir=...]		  Path to the TrueType fonts. Defaults to
			  %SystemRoot%\/Fonts;
  [-destdir=...]	  Location of destination. Defaults to .\/Fonts;
  [-Type1]		  Switch on Type1 fonts generation;
  [-stemv=...]		  Add -v parameter into cid-x.map;
  [-updmap]		  Update font maps for TeX Live system;
  [-updmapcfg]		  Add map file info into updmap.cfg file for MiKTeX;
  [-verbose|-v]		  Print more information;
  [--version|-V]	  Version number and copyright infomation;
  [--help|-h]		  Show this help text.
EOF
}

sub version
{
    print <<EOF;

FontGen $version: Automatically configure Chinese fonts for TeX
$copyright
$contributions

This program comes with ABSOLUTELY NO WARRANTY.  This is free software, 
you are welcome to redistribute it under the terms of the GNU General 
Public License.

For help on usage of this program type FontGen --help or FontGen -h.  

EOF
}

# 打印 verbose 模式内容
sub printverb
{
    if ($verbose) {
	print "@_";
    }
}

# 若路径不存在，创建路径
sub test_makedir
{
    if (!(-e "@_")) {
	printverb("Dir `@_' does not exist. Make it.\n");
	mkpath("@_");
    }
}

if ($#ARGV<0) 
{
    usage();
    exit;
}
foreach $arg (@ARGV)
{
    if($arg =~ /-ttfdir=/)
    {
	$ttfdir=$arg;	
	$ttfdir =~ s/(-ttfdir=)(.+)/$2/;
	if(!(-e $ttfdir))
	{
	    print "ERROR: TrueType font directory not found!\n";
	    exit;
	}
    }
    elsif($arg =~ /-ttf=/)
    {
	$ttfname = $arg;
	$ttfname =~ s/(-ttf=)(.+)/$2/;
	$ttfbase = $ttfname;
	$ttfbase =~ s/(.*)(\.[tT][tT][fFcC])/$1/;
	if ("$ttfname" eq "$ttfbase") {
	    $ttfname = $ttfbase.".ttf";
	}
    }
    elsif($arg =~ /-encoding=/) 
    {
	$encoding=$arg;
	$encoding =~ s/(-encoding=)(.+)/$2/;
	if($encoding eq "GBK")
	{
	    # empty
	}
	elsif($encoding eq "UTF8")
	{
	    $pre="uni";
	    $switches="-GFAE -l plane+0x";
	    @range1=@range2=(0..9,"a".."f");
	    $Uenc="Unicode";
	    $set_dim=$set2_dim=16;
	    $fdpre="c70";
	    $CJKnormal="\\CJKnormal";
	    $fddir="UTF8";
	}
	elsif($encoding eq "Big5")
	{
	    $pre="b5";
	    $switches="-GFAe -L cubig5.map+";
	    @range1="0..5";
	    @range2="0..9";
	    $Uenc="UBig5";
	    $set_dim=6;
	    $set2_dim=10;
	    $fdpre="c00";
	    $fddir="Bg5";
	}
	else
	{
	    print "Font encoding $encoding not supported.\n";
	    exit;
	}
    }
    elsif($arg =~ /-slanted=/)
    {
	$genslanted = $arg;	
	$genslanted =~ s/(-slanted=)(.+)/$2/;
    }
    elsif($arg =~ /-prefix=/)
    {
	$pre=$arg;	
	$pre =~ s/(-prefix=)(.+)/$2/;
    }
    elsif($arg =~ /-stemv=/)
    {
	$vs=$arg;	
	$vs =~ s/(-stemv=)([0-9]+)/$2/;
	$stemv="-v $vs";
    }
    elsif($arg =~ /-CJKname=/)
    {
	$familyname=$arg;
	$familyname =~ s/(-CJKname=)(.+)/$2/;
    }
    elsif($arg =~ /-cjkmap=/)
    {
	$cjkmapbase=$arg;	
	$cjkmapbase =~ s/(-cjkmap=)(.+)/$2/;
    }
    elsif($arg =~ /-destdir=/)
    {
	$destdir=$arg;	
	$destdir =~ s/(-destdir=)(.+)/$2/;
    }
    elsif($arg eq "-Type1")
    {
	if ($ttfname =~ /.*\.[tT][tT][cC]/) {
	    print "Warning: Program ttf2pt1 does not support TTC fonts. I will ignore `-Type1' option.\n";
	    $pfb = 0;
	}
	else {
	    $pfb = 1;
	}
    }
    elsif($arg eq "-updmap")
    {
	$updmap=1;	
    }
    elsif ($arg eq "updmapcfg") {
	$updmapcfg = 1;
    }
    elsif( ($arg eq "-verbose") || ($arg eq "-v") )
    {
	$verbose = 1;
    }
    elsif(($arg eq "--version")||($arg eq "-V"))
    {
	version();
	exit;
    }
    elsif(($arg eq "--help")||($arg eq "-h"))
    {
	usage();
	exit;
    }
    elsif($arg !~ /=/) 
    {
	print "Unrecognized option: $arg. Type $progname -h for usage.\n";
	exit;
    }
    elsif($arg =~ /=/)
    {
	$testarg = $arg;
	$testarg =~ s/(.*)(=.*)/$1/;
	if(!(($testarg eq "-ttf") || ($testarg eq "-ttfdir") || ($testarg eq "-encoding") || 
	    ($testarg eq "-prefix") || ($testarg eq "-CJKname") || ($testarg eq "-slanted") || 
	    ($testarg eq "-destdir")))
	{
	    print "Unrecognized option: $arg. Type $progname -h for usage.\n";
	    exit;
	}
    }
}


$Fdpre = $fdpre;
$Fdpre =~ s/c/C/;


if(!$ttfname)
{
    print "ERROR: No TrueType font specified!\n";
    exit;
}
elsif(!$familyname)
{
    print "ERROR: No CJKfamily name specified!\n";
    exit;
}
elsif(!(-e "$ttfdir/$ttfname"))
{
    print "ERROR: TrueType font file $ttfname not found!\n";
    exit;
}

printverb("Installing TTF font $ttfbase with CJKfamily name `$familyname' in encoding $encoding...\n");

#test_makedir("$destdir/fonts/enc/Chinese/$pre$familyname");
test_makedir("$destdir/fonts/tfm/Chinese/$pre$familyname");
if($pfb)
{
    test_makedir("$destdir/fonts/afm/Chinese/$pre$familyname");
    test_makedir("$destdir/fonts/type1/Chinese/$pre$familyname");
}

printverb("Generating TFM files... ");

# this is a little noisy, so changed into $exec=...
#system("ttf2tfm $ttfdir/$ttfname -q -f 0 -w $pre$familyname\@$Uenc\@.tfm");     
#system("ttf2tfm $ttfdir/$ttfname -q -f 0 -s 0.167 $pre$familyname$slant\@$Uenc\@.tfm");

$exec = `ttf2tfm $ttfdir/$ttfname -q -f 0 -w $pre$familyname\@$Uenc\@.tfm`;
if($genslanted eq "y")
{
    $exec = `ttf2tfm $ttfdir/$ttfname -q -f 0 -s 0.167 $pre$familyname$slant\@$Uenc\@.tfm`;
}
printverb("Ok.\n");

if ($pfb) 
{
    printverb("Generating Type1 fonts (AFM and PFB files) ... ");
    foreach $i (@range1) {
	foreach $j (@range2) {
	    if ((-e "$pre$familyname$i$j.enc") && 
		(! (-e "$destdir/fonts/type1/Chinese/$pre$familyname/$pre$familyname$i$j.pfb"))) 
	    # generation of pfb files is time consuming, so avoid regenerating existing files
	    {
		system("ttf2pt1 -W0 -b $switches$i$j  $ttfdir/$ttfname $pre$familyname$i$j");
	    }
	}
    }
    printverb("Ok.\n");
}

printverb("Moving TFM files to $destdir/fonts/tfm/Chinese/$pre$familyname/ ... ");
foreach $tfmfile (<*.tfm>)
{
    move("$tfmfile", "$destdir/fonts/tfm/Chinese/$pre$familyname/");
}
printverb("Ok.\n");

#printverb("Moving ENC files to $destdir/fonts/enc/Chinese/$pre$familyname/ ... ");
#foreach $encfile (<*.enc>)
#{
#    move("$encfile", "$destdir/fonts/enc/Chinese/$pre$familyname/");
#}
#printverb("Ok.\n");

if ($pfb)
{
    printverb("Moving AFM files to $destdir/fonts/afm/Chinese/$pre$familyname/ ... ");
    foreach $afmfile (<*.afm>) {
	move("$afmfile", "$destdir/fonts/afm/Chinese/$pre$familyname/");
    }
    printverb("Ok.\n");
    printverb("Moving PFB fonts $destdir/fonts/type1/Chinese/$pre$familyname/ ... ");
    foreach $pfbfile (<*.pfb>) {
	move("$pfbfile", "$destdir/fonts/type1/Chinese/$pre$familyname/");
    }
    printverb("Ok.\n");
}

$flag = 0;
if (-e "$destdir/fonts/map/dvipdfm/dvipdfmx/cid-x.map")
{
    open(F, "<$destdir/fonts/map/dvipdfm/dvipdfmx/cid-x.map");
    foreach $fileline (<F>) {
	chomp($fileline);
        if($fileline =~ /$pre$familyname/) 
	{
	    printverb("Font family `$pre$familyname' is already installed in cid-x.map, ignored.\n");
	    $flag = 1;
	    last;
	}
    }
}
close(F);
unless ($flag)
{
    test_makedir("$destdir/fonts/map/dvipdfm/dvipdfmx");
    printverb("Writing `$destdir/fonts/map/dvipdfm/dvipdfmx/cid-x.map' for dvipdfmx... ");
    open(F, ">>$destdir/fonts/map/dvipdfm/dvipdfmx/cid-x.map");
    print F "$pre$familyname\@$Uenc\@ unicode :0:$ttfname $stemv\n";
    if($genslanted eq "y")
    {
    	print F "$pre$familyname$slant\@$Uenc\@ unicode :0:$ttfname -s .167 $stemv\n\n";
    }
    close(F);
    printverb("Ok.\n");
}

$flag = 0;
if (-e "$destdir/fonts/map/ttf2pk/config/ttfonts.map")
{
    open(F, "< $destdir/fonts/map/ttf2pk/config/ttfonts.map");
    foreach $fileline (<F>) 
    {
	chomp($fileline);
        if($fileline =~ /$pre$familyname/) {
	    printverb("Font family `$pre$familyname' is already installed in ttfonts.map, ignored.\n");
	    $flag = 1;
	    last;
	}
    }
}
close(F);
unless ($flag) 
{
    test_makedir("$destdir/fonts/map/ttf2pk/config");
    printverb("Writing `$destdir/fonts/map/ttf2pk/config/ttfonts.map'... ");
    open(F, ">>$destdir/fonts/map/ttf2pk/config/ttfonts.map");
    print F "$pre$familyname\@$Uenc\@  $ttfname Pid = 3 Eid = 1\n";
    if($genslanted eq "y")
    {
    	print F "$pre$familyname$slant\@$Uenc\@  $ttfname Slant=0.167 Pid = 3 Eid = 1\n\n";
    }
    close(F);
    printverb("Ok.\n");
}

test_makedir("$destdir/fonts/map");

$flag1 = 0;  # $flag1 = 0 表示当前字体未被当作TeX可用的TTF字体进行配置;
if (-e "$destdir/fonts/map/$cjkmapbase$ttfsuffix.map")
{
    open(F, "< $destdir/fonts/map/$cjkmapbase$ttfsuffix.map");
    foreach $fileline (<F>) {
	chomp($fileline);
        if ($fileline =~ /$pre$familyname/) 
	{
	    printverb("Font family `$pre$familyname' is already installed in $cjkmapbase$ttfsuffix.map, ignored.\n");
	    $flag1 = 1;
	    last;
        }
    }
    close(F);
}
unless($flag1)
{
    printverb("Writing `$destdir/fonts/map/$cjkmapbase$ttfsuffix.map'... ");
    open(F, ">> $destdir/fonts/map/$cjkmapbase$ttfsuffix.map");
    print F "$pre$familyname\@$Uenc\@ <$ttfname PidEid=3,1\n";
    if($genslanted eq "y")
    {
    	print F "$pre$familyname$slant\@$Uenc\@ < $ttfname PidEid=3,1\n\n";
    }
    close(F);
    printverb("Ok.\n");
}

$flag2 = 0;  # $flag2 = 0 表示当前字体未被当作TeX可用的Type1字体进行配置;
if (-e "$destdir/fonts/map/$cjkmapbase$pt1suffix.map")
{
    open(F, "< $destdir/fonts/map/$cjkmapbase$pt1suffix.map");
    foreach $fileline (<F>) {
	chomp($fileline);
	if ($fileline =~ /$pre$familyname/) 
	{
	    printverb("Font family `$pre$familyname' is already installed in $cjkmapbase$pt1suffix.map, ignored.\n");
	    $flag2 = 1;
	    last;
	}
    }
    close(F);
}
if ($pfb && not $flag2) 
{
    printverb("Writing `$destdir/fonts/map/$cjkmapbase$pt1suffix.map'... ");
    open(F, ">> $destdir/fonts/map/$cjkmapbase$pt1suffix.map");
    @set=(0..9,"a".."f");
    for ($i=0;$i<$set_dim;$i=$i+1) 
    {
	for ($j=0;$j<$set2_dim;$j=$j+1) 
	{
	    #if (-e "$destdir/fonts/tfm/Chinese/$pre$familyname/$pre$familyname@set[$i]@set[$j].tfm") 
	    if (-e "$pre$familyname@set[$i]@set[$j].enc") 
	    {
		if (-e "$destdir/fonts/type1/Chinese/$pre$familyname/$pre$familyname@set[i]@set[j].pfb") 
		{
		    open(FF, "<$destdir/fonts/type1/Chinese/$pre$familyname/$pre$familyname@set[i]@set[j].pfb");
		    @pfb=<FF>;
		    close(FF);
		    @pfb=grep(/\/FontName.*def/, @pfb);
		    $psname = @pfb[0];
		    $psname =~ s|/FontName /(.+)-\w{2} def.*|$1|s;
		}
		print F "$pre$familyname@set[$i]@set[$j]  $psname-@set[$i]@set[$j] < $pre$familyname@set[$i]@set[$j].pfb\n";
		if($genslanted eq "y")
		{
		    print F "$pre$familyname$slant@set[$i]@set[$j]  $psname-@set[$i]@set[$j] \" .167 SlantFont \" < $pre$familyname@set[$i]@set[$j].pfb\n";
		}
	    }
	}
    }
    print F "\n";
    close(F);
    printverb("Ok.\n");
}

foreach $encfile (<*.enc>)
{
    unlink($encfile);
}


if (-e "$destdir/tex/latex/CJK/$fddir/$fdpre$familyname.fd") {
    printverb("Font definition file `$fdpre$familyname.fd' already exists, ignored.\n");
}
else {
    if($genslanted eq "y")
    {
	@genfd=(
	    "% This is the file $fdpre$familyname.fd of the CJK package\n",
	    "% for using Asian logographs (Chinese\/Japanese\/Korean) with LaTeX2e\n",
	    "%\n",
	    "% automatically generated by FontsGen $version\n",
	    "\n",
	    "\\def\\fileversion{4.8.1}\n",
	    "\\def\\filedate{2008/08/10}\n",
	    "\\ProvidesFile{$fdpre$familyname.fd}[\\filedate\\space\\fileversion]\n",
	    "\n",
	    "% Chinese characters\n",
	    "%\n",
	    "% character set: $encoding\n",
	    "% font encoding: CJK ($encoding)\n",
	    "\n",
	    "\\DeclareFontFamily{$Fdpre}{$familyname}{\\hyphenchar \\font\\m\@ne}\n",
	    "\n",
	    "\\DeclareFontShape{$Fdpre}{$familyname}{m}{n}{<-> CJK * $pre$familyname}{$CJKnormal}\n",
	    "\\DeclareFontShape{$Fdpre}{$familyname}{bx}{n}{<-> CJKb * $pre$familyname}{\\CJKbold}\n",
	    "\\DeclareFontShape{$Fdpre}{$familyname}{m}{it}{<-> CJK * $pre$familyname$slant}{$CJKnormal}\n",
	    "\\DeclareFontShape{$Fdpre}{$familyname}{bx}{it}{<-> CJKb * $pre$familyname$slant}{\\CJKbold}\n",
	    "\\DeclareFontShape{$Fdpre}{$familyname}{m}{sl}{<-> CJK * $pre$familyname$slant}{$CJKnormal}\n",
	    "\\DeclareFontShape{$Fdpre}{$familyname}{bx}{sl}{<-> CJKb * $pre$familyname$slant}{\\CJKbold}\n",
	    "\n",
	    "\\endinput\n"
	);
    }
    else
    {
	@genfd=(
	    "% This is the file $fdpre$familyname.fd of the CJK package\n",
	    "% for using Asian logographs (Chinese\/Japanese\/Korean) with LaTeX2e\n",
	    "%\n",
	    "% automatically generated by FontsGen $version\n",
	    "\n",
	    "\\def\\fileversion{4.8.1}\n",
	    "\\def\\filedate{2008/08/10}\n",
	    "\\ProvidesFile{$fdpre$familyname.fd}[\\filedate\\space\\fileversion]\n",
	    "\n",
	    "% Chinese characters\n",
	    "%\n",
	    "% character set: $encoding\n",
	    "% font encoding: CJK ($encoding)\n",
	    "\n",
	    "\\DeclareFontFamily{$Fdpre}{$familyname}{\\hyphenchar \\font\\m\@ne}\n",
	    "\n",
	    "\\DeclareFontShape{$Fdpre}{$familyname}{m}{n}{<-> CJK * $pre$familyname}{$CJKnormal}\n",
	    "\\DeclareFontShape{$Fdpre}{$familyname}{bx}{n}{<-> CJKb * $pre$familyname}{\\CJKbold}\n",
	    "\n",
	    "\\endinput\n"
	);
    }
    test_makedir("$destdir/tex/latex/CJK/$fddir");
    printverb("Genarating font definition file `$destdir/tex/latex/CJK/$fddir/$fdpre$familyname.fd'... ");
    open(FD, "> $destdir/tex/latex/CJK/$fddir/$fdpre$familyname.fd");
    print FD @genfd;
    close(FD);
    printverb("Ok.\n");
}


# for TeX Live only
if ($updmap) 
{
    printverb("Updating font maps...\n");
    if ($pfb) 
    {
	system("updmap-sys --enable Map=$cjkmapbase$pt1suffix.map");
	system("updmap --enable Map=$cjkmapbase$pt1suffix.map");
    }
    else 
    {
	system("updmap-sys --enable Map=$cjkmapbase$ttfsuffix.map");
	system("updmap --enable Map=$cjkmapbase$ttfsuffix.map");
    }
    printverb("Ok.\n");
}

# For MiKTeX only. Harmless for TeX Live, I think.
if($updmapcfg)
{
    $flag = 0;
    open(F, "< $destdir/web2c/updmap.cfg");
    foreach $fileline (<F>) 
    {
	chomp($fileline);
	if ($fileline =~ /$pre$familyname/) 
	{
	    printverb("Font family `$pre$familyname' is already installed in updmap.map, ignored.\n");
	    $flag = 1;
	    last;
	}
    }
    close(F);
    unless ($flag) 
    {
	printverb("Writing $destdir/web2c/updmap.cfg... ");
	test_makedir("$destdir/web2c");
	open(F, ">> $destdir/web2c/updmap.cfg");
	if ($pfb) 
	{
	    print F "Map $cjkmapbase$pt1suffix.map\n";
	}
	else 
	{
	    print F "MixedMap $cjkmapbase$ttfsuffix.map\n";
	}
	close(F);
	printverb("Ok.\n");
    }
}

printverb("\n");

# vim:ai:ts=8:sts=4:sw=4:noet:sta:ft=perl:
