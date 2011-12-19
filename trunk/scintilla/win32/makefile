# Make file for Scintilla on Windows
# Copyright 1998-2010 by Neil Hodgson <neilh@scintilla.org>
# The License.txt file describes the conditions under which this software may be distributed.
# This makefile assumes the mingw32 version of GCC 3.x or 4.x is used and changes will
# be needed to use other compilers.

.SUFFIXES: .cxx
CC = g++
DLLWRAP = dllwrap
DEL = del /q
WINDRES = windres
RANLIB = ranlib

COMPONENT = ../bin/Scintilla.dll
LEXCOMPONENT = ../bin/SciLexer.dll
LEXLIB = Lexers.a

vpath %.h ../src ../include ../lexlib
vpath %.cxx ../src ../lexlib ../lexers

LDFLAGS=-shared -static -Wl,--enable-runtime-pseudo-reloc-v2 -mwindows -Wl,--add-stdcall-alias
LIBS=-lstdc++ -limm32 -lole32 -luuid
# Add -MMD to get dependencies
INCLUDEDIRS=-I ../include -I ../src -I../lexlib
CXXBASEFLAGS=-Wall -Wno-missing-braces -Wno-char-subscripts -pedantic $(INCLUDEDIRS) -fno-rtti

ifdef DEBUG
CXXFLAGS=-DDEBUG -g $(CXXBASEFLAGS)
else
CXXFLAGS=-DNDEBUG -Os $(CXXBASEFLAGS)
STRIPFLAG=-s
endif

.cxx.o:
	$(CC) $(CXXFLAGS) -c $<

## [mhb] 07/11/09 : run gen_lexers to generate _lexers.inc first
ALL:	gen_lexers $(COMPONENT) $(LEXCOMPONENT) $(LEXLIB) ScintillaWinS.o

clean:
	$(DEL) *.exe *.o *.obj *.dll *.res *.map

deps:
	$(CC) -MM $(CXXFLAGS) *.cxx ../src/*.cxx ../lexlib/*.cxx ../lexers/*.cxx >deps.mak


## [mhb] 07/11/09 : use less lexers to reduce exe file size if LESS_LEXERS is defined
ifdef LESS_LEXERS
LEXERS=Ada Asm ASY AU3 Bash Basic BiB Cmake COBOL Conf CPP \
Crontab CSS D Eiffel Erlang EScript Euphoria Flagship Forth Fortran Gui4Cli \
HTML Inno Kix Latex Lisp Lout Lua Markdown Matlab Metapost MSSQL MySQL Nsis Others\
Pascal PB Perl PowerPro PowerShell PS Python R Rebol Ruby Smalltalk SQL TCL VB
## [mhb] 07/11/09 : now there is no need to explicitly specify Lex*.o; you need just place wanted lexers above:-)
LEXOBJS:=$(LEXERS:%=Lex%.o)
else
LEXOBJS:=$(addsuffix .o,$(basename $(notdir $(wildcard ../lexers/Lex*.cxx)))) 
endif

## [mhb] 07/11/09 : the following codes generate correct table of lexer names
LEXNAMS:=$(LEXERS:Basic=BlitzBasic PureBasic FreeBasic)
LEXNAMS:=$(LEXNAMS:CLW=Clw ClwNoCase)
LEXNAMS:=$(LEXNAMS:CPP=CPP CPPNoCase)
LEXNAMS:=$(LEXNAMS:Crontab=Nncrontab)
LEXNAMS:=$(LEXNAMS:CSS=Css)
LEXNAMS:=$(LEXNAMS:Eiffel=Eiffel Eiffelkw)
LEXNAMS:=$(LEXNAMS:EScript=ESCRIPT)
LEXNAMS:=$(LEXNAMS:Flagship=FlagShip)
LEXNAMS:=$(LEXNAMS:Fortran=Fortran F77)
LEXNAMS:=$(LEXNAMS:HTML=HTML XML PHPSCRIPT)
LEXNAMS:=$(LEXNAMS:Lisp=LISP)
LEXNAMS:=$(LEXNAMS:Magik=MagikSF)
LEXNAMS:=$(LEXNAMS:Matlab=Matlab Octave)
LEXNAMS:=$(LEXNAMS:Metapost=METAPOST)
LEXNAMS:=$(LEXNAMS:MPT=Lot)
LEXNAMS:=$(LEXNAMS:Others=Batch Diff Po Props Make ErrorList Null)
LEXNAMS:=$(LEXNAMS:Rebol=REBOL)
LEXNAMS:=$(LEXNAMS:Sorcus=Sorc)
LEXNAMS:=$(LEXNAMS:VB=VB VBScript)

## [mhb] 07/11/09 : now we do not need to specify what lexers should be linked; we generate the list automatically!
gen_lexers:
	rm -f ../src/_lexers.inc
	for lex in $(LEXNAMS); do echo "LINK_LEXER(lm$$lex);">>../src/_lexers.inc; done


BASEOBJS = \
	AutoComplete.o \
	CallTip.o \
	CellBuffer.o \
	CharacterSet.o \
	CharClassify.o \
	ContractionState.o \
	Decoration.o \
	Document.o \
	Editor.o \
	KeyMap.o \
	Indicator.o \
	LineMarker.o \
	PerLine.o \
	PlatWin.o \
	PositionCache.o \
	PropSetSimple.o \
	RESearch.o \
	RunStyles.o \
	ScintRes.o \
	Selection.o \
	Style.o \
	UniConversion.o \
	ViewStyle.o \
	XPM.o

SOBJS = ScintillaWin.o ScintillaBase.o $(BASEOBJS)

$(COMPONENT): $(SOBJS) Scintilla.def
	$(CC) $(LDFLAGS) -o $@ $(STRIPFLAG) $(SOBJS) $(CXXFLAGS) $(LIBS)

LOBJS = \
	Accessor.o \
	Catalogue.o \
	ExternalLexer.o \
	LexerBase.o \
	LexerModule.o \
	LexerSimple.o \
	ScintillaWinL.o \
	ScintillaBaseL.o \
	StyleContext.o \
	WordList.o \
	$(BASEOBJS) \
	$(LEXOBJS)
$(LEXCOMPONENT): $(LOBJS) Scintilla.def
	$(CC) $(LDFLAGS) -o $@ $(STRIPFLAG) $(LOBJS) $(CXXFLAGS) $(LIBS)

$(LEXLIB): $(LEXOBJS)
	$(AR) rc $@ $^
	$(RANLIB) $@

# Automatically generate dependencies for most files with "make deps"
include deps.mak

# These dependencies are maintained by hand as they do not use the default output name

ScintillaBaseL.o: ScintillaBase.cxx Platform.h \
 ILexer.h Scintilla.h SciLexer.h PropSetSimple.h \
 SplitVector.h Partitioning.h RunStyles.h \
 ContractionState.h CellBuffer.h CallTip.h \
 KeyMap.h Indicator.h XPM.h LineMarker.h \
 Style.h ViewStyle.h AutoComplete.h \
 CharClassify.h Decoration.h Document.h \
 Selection.h PositionCache.h Editor.h \
 ScintillaBase.h LexAccessor.h Accessor.h \
 LexerModule.h Catalogue.h

ScintillaWinL.o: ScintillaWin.cxx Platform.h \
 ILexer.h Scintilla.h SplitVector.h \
 Partitioning.h RunStyles.h ContractionState.h \
 CellBuffer.h CallTip.h KeyMap.h Indicator.h \
 XPM.h LineMarker.h Style.h AutoComplete.h \
 ViewStyle.h CharClassify.h Decoration.h \
 Document.h Selection.h PositionCache.h \
 Editor.h ScintillaBase.h UniConversion.h \
 LexAccessor.h Accessor.h \
 LexerModule.h Catalogue.h

ScintillaWinS.o: ScintillaWin.cxx Platform.h \
 ILexer.h Scintilla.h SplitVector.h \
 Partitioning.h RunStyles.h ContractionState.h \
 CellBuffer.h CallTip.h KeyMap.h Indicator.h \
 XPM.h LineMarker.h Style.h AutoComplete.h \
 ViewStyle.h CharClassify.h Decoration.h \
 Document.h Selection.h PositionCache.h \
 Editor.h ScintillaBase.h UniConversion.h

ScintillaBaseL.o:
	$(CC) $(CXXFLAGS) -D SCI_LEXER -c $< -o $@

ScintillaWinS.o:
	$(CC) $(CXXFLAGS) -D STATIC_BUILD -c $< -o $@

ScintillaWinL.o:
	$(CC) $(CXXFLAGS) -D SCI_LEXER -c $< -o $@

ScintRes.o:	ScintRes.rc
	$(WINDRES) ScintRes.rc $@

