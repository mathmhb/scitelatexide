// Scintilla source code edit control
/** @file LexScilab.cxx
 ** Lexer for Scilab.
 ** Written by José Fonseca
 **
 ** Changes by Christoph Dalitz 2003/12/04:
 **   - added support for Octave
 **   - Strings can now be included both in single or double quotes
 **/
// Copyright 1998-2001 by Neil Hodgson <neilh@scintilla.org>
// The License.txt file describes the conditions under which this software may be distributed.

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <stdarg.h>

#include "Platform.h"

#include "PropSet.h"
#include "Accessor.h"
#include "StyleContext.h"
#include "KeyWords.h"
#include "Scintilla.h"
#include "SciLexer.h"

#ifdef SCI_NAMESPACE
using namespace Scintilla;
#endif

static bool IsScilabCommentChar(int c) {
//~ static bool IsScilabCommentChar(StyleContext &sc) {
	return (c == '/') ;
	//~ return (sc.Match('/', '/')) ;
}

//~ static bool IsOctaveCommentChar(int c) {
	//~ return (c == '%' || c == '#') ;
//~ }

static bool IsScilabComment(Accessor &styler, int pos, int len) {
	return len > 0 && IsScilabCommentChar(styler[pos]) && IsScilabCommentChar(styler[pos+1]) ;
}

//~ static bool IsOctaveComment(Accessor &styler, int pos, int len) {
	//~ return len > 0 && IsOctaveCommentChar(styler[pos]) ;
//~ }

static inline bool IsAWordChar(const int ch) {
	return (ch < 0x80) && (isalnum(ch) || ch == '_');
}

static inline bool IsAWordStart(const int ch) {
	return (ch < 0x80) && (isalnum(ch) || ch == '_');
}

static void ColouriseScilabOctaveDoc(
            unsigned int startPos, int length, int initStyle,
            WordList *keywordlists[], Accessor &styler,
            bool (*IsCommentChar)(int)) {

	WordList &keywords = *keywordlists[0];

	styler.StartAt(startPos);

	bool transpose = false;

	StyleContext sc(startPos, length, initStyle, styler);

	for (; sc.More(); sc.Forward()) {

		if (sc.state == SCE_SCILAB_OPERATOR) {
			if (sc.chPrev == '.') {
				if (sc.ch == '*' || sc.ch == '/' || sc.ch == '\\' || sc.ch == '^') {
					sc.ForwardSetState(SCE_SCILAB_DEFAULT);
					transpose = false;
				} else if (sc.ch == '\'') {
					sc.ForwardSetState(SCE_SCILAB_DEFAULT);
					transpose = true;
				} else {
					sc.SetState(SCE_SCILAB_DEFAULT);
				}
			} else {
				sc.SetState(SCE_SCILAB_DEFAULT);
			}
		} else if (sc.state == SCE_SCILAB_KEYWORD) {
			if (!isalnum(sc.ch) && sc.ch != '_') {
				char s[100];
				sc.GetCurrentLowered(s, sizeof(s));
				if (keywords.InList(s)) {
					sc.SetState(SCE_SCILAB_DEFAULT);
					transpose = false;
				} else {
					sc.ChangeState(SCE_SCILAB_IDENTIFIER);
					sc.SetState(SCE_SCILAB_DEFAULT);
					transpose = true;
				}
			}
		} else if (sc.state == SCE_SCILAB_NUMBER) {
			if (!isdigit(sc.ch) && sc.ch != '.'
			        && !(sc.ch == 'e' || sc.ch == 'E')
			        && !((sc.ch == '+' || sc.ch == '-') && (sc.chPrev == 'e' || sc.chPrev == 'E'))) {
				sc.SetState(SCE_SCILAB_DEFAULT);
				transpose = true;
			}
		} else if (sc.state == SCE_SCILAB_STRING) {
			if (sc.ch == '\\') {
				if (sc.chNext == '\"' || sc.chNext == '\'' || sc.chNext == '\\') {
					sc.Forward();
				}
			} else if (sc.ch == '\'') {
				sc.ForwardSetState(SCE_SCILAB_DEFAULT);
			}
		} else if (sc.state == SCE_SCILAB_DOUBLEQUOTESTRING) {
			if (sc.ch == '\\') {
				if (sc.chNext == '\"' || sc.chNext == '\'' || sc.chNext == '\\') {
					sc.Forward();
				}
			} else if (sc.ch == '\"') {
				sc.ForwardSetState(SCE_SCILAB_DEFAULT);
			}
		} else if (sc.state == SCE_SCILAB_COMMENT || sc.state == SCE_SCILAB_COMMAND) {
			if (sc.atLineEnd) {
				sc.SetState(SCE_SCILAB_DEFAULT);
				transpose = false;
			}
		}

		if (sc.state == SCE_SCILAB_DEFAULT) {
			if (IsCommentChar(sc.ch) && IsCommentChar(sc.chNext)) {
				sc.SetState(SCE_SCILAB_COMMENT);
			} else if (sc.ch == '!' && sc.chNext != '=' ) {
				sc.SetState(SCE_SCILAB_COMMAND);
			} else if (sc.ch == '\'') {
				if (transpose) {
					sc.SetState(SCE_SCILAB_OPERATOR);
				} else {
					sc.SetState(SCE_SCILAB_STRING);
				}
			} else if (sc.ch == '"') {
				sc.SetState(SCE_SCILAB_DOUBLEQUOTESTRING);
			} else if (isdigit(sc.ch) || (sc.ch == '.' && isdigit(sc.chNext))) {
				sc.SetState(SCE_SCILAB_NUMBER);
			} else if (isalpha(sc.ch)) {
				sc.SetState(SCE_SCILAB_KEYWORD);
			} else if (isoperator(static_cast<char>(sc.ch)) || sc.ch == '@' || sc.ch == '\\') {
				if (sc.ch == ')' || sc.ch == ']') {
					transpose = true;
				} else {
					transpose = false;
				}
				sc.SetState(SCE_SCILAB_OPERATOR);
			} else {
				transpose = false;
			}
		}
	}
	sc.Complete();
}

static void ColouriseScilabDoc(unsigned int startPos, int length, int initStyle,
                               WordList *keywordlists[], Accessor &styler) {
	ColouriseScilabOctaveDoc(startPos, length, initStyle, keywordlists, styler, IsScilabCommentChar);
}

//~ static void ColouriseOctaveDoc(unsigned int startPos, int length, int initStyle,
                               //~ WordList *keywordlists[], Accessor &styler) {
	//~ ColouriseScilabOctaveDoc(startPos, length, initStyle, keywordlists, styler, IsOctaveCommentChar);
//~ } //Not used

static void FoldScilabOctaveDoc(unsigned int startPos, int length, int,
                                WordList *[], Accessor &styler,
                                bool (*IsComment)(Accessor&, int, int)) {

	int endPos = startPos + length;

	// Backtrack to previous line in case need to fix its fold status
	int lineCurrent = styler.GetLine(startPos);
	if (startPos > 0) {
		if (lineCurrent > 0) {
			lineCurrent--;
			startPos = styler.LineStart(lineCurrent);
		}
	}
	int spaceFlags = 0;
	int indentCurrent = styler.IndentAmount(lineCurrent, &spaceFlags, IsComment);
	char chNext = styler[startPos];
	for (int i = startPos; i < endPos; i++) {
		char ch = chNext;
		chNext = styler.SafeGetCharAt(i + 1);

		if ((ch == '\r' && chNext != '\n') || (ch == '\n') || (i == endPos)) {
			int lev = indentCurrent;
			int indentNext = styler.IndentAmount(lineCurrent + 1, &spaceFlags, IsComment);
			if (!(indentCurrent & SC_FOLDLEVELWHITEFLAG)) {
				// Only non whitespace lines can be headers
				if ((indentCurrent & SC_FOLDLEVELNUMBERMASK) < (indentNext & SC_FOLDLEVELNUMBERMASK)) {
					lev |= SC_FOLDLEVELHEADERFLAG;
				} else if (indentNext & SC_FOLDLEVELWHITEFLAG) {
					// Line after is blank so check the next - maybe should continue further?
					int spaceFlags2 = 0;
					int indentNext2 = styler.IndentAmount(lineCurrent + 2, &spaceFlags2, IsComment);
					if ((indentCurrent & SC_FOLDLEVELNUMBERMASK) < (indentNext2 & SC_FOLDLEVELNUMBERMASK)) {
						lev |= SC_FOLDLEVELHEADERFLAG;
					}
				}
			}
			indentCurrent = indentNext;
			styler.SetLevel(lineCurrent, lev);
			lineCurrent++;
		}
	}
}

static void FoldScilabDoc(unsigned int startPos, int length, int initStyle,
                          WordList *keywordlists[], Accessor &styler) {
	FoldScilabOctaveDoc(startPos, length, initStyle, keywordlists, styler, IsScilabComment);
}

//~ static void FoldOctaveDoc(unsigned int startPos, int length, int initStyle,
                          //~ WordList *keywordlists[], Accessor &styler) {
	//~ FoldScilabOctaveDoc(startPos, length, initStyle, keywordlists, styler, IsOctaveComment);
//~ }//Not used

static const char * const scilabWordListDesc[] = {
	"Keywords",
	0
};

//~ static const char * const octaveWordListDesc[] = {
	//~ "Keywords",
	//~ 0
//~ };

LexerModule lmScilab(SCLEX_SCILAB, ColouriseScilabDoc, "scilab", FoldScilabDoc, scilabWordListDesc);

//~ LexerModule lmOctave(SCLEX_OCTAVE, ColouriseOctaveDoc, "octave", FoldOctaveDoc, octaveWordListDesc);
