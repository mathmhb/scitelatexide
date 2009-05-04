// Scintilla source code edit control
/** @file LexBiB.cxx
 ** Lexer for the Bibtex typesetting language
 **/
// Copyright 2008 Instanton
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

static inline bool issymbol(int ch)
{
	return (ch == '~') || (ch == '`') || (ch == '\'')|| (ch == '~') ||
           (ch == '#') || (ch == '^') || (ch == '&') || (ch == '+') || 
           (ch == '-') || (ch == '=') || (ch == '>') || (ch == '<') ||
           (ch == '\"');
}

static inline bool isbracket(int ch) 
{
	return
      (ch == '(') || (ch == ')') || (ch == '[') || 
      (ch == ']') || (ch == '{') || (ch == '}'); 
}

static inline bool isnumber(int ch) {
	return
      (ch == '0') || (ch == '1') || (ch == '2') || 
      (ch == '3') || (ch == '4') || (ch == '5') || 
      (ch == '6') || (ch == '7') || (ch == '8') || (ch == '9');
}

static inline bool iswordchar(int ch) {
	return ((ch >= 'a') && (ch <= 'z')) || ((ch >= 'A') && (ch <= 'Z'));
}

inline bool isEOL(char ch)
{
   return (ch == '\r' || ch == '\n');
}

static void ColouriseBIBDoc(unsigned int startPos, 
		int length, int initStyle, WordList *keywordlists[], Accessor &styler) 
{
    WordList& keywords = *keywordlists[0];    
 
    char word[512]  = "";

    int afterEqual      = 0; 
	int afterAt		=0;
	styler.StartAt(startPos);
    styler.StartSegment(startPos);

    initStyle = initStyle & 0x1f;
    StyleContext sc(startPos, length, initStyle, styler);

    // scan  ---------------------------------------------
	bool going = sc.More() ; // needed because of a fuzzy end of file state
    for(; going; sc.Forward()){
		if (! sc.More()) { going = false ; }
		
        // Determine if the current state should terminate.
        switch(sc.state){
            case SCE_BIB_RECORD:
                if(!iswordchar(sc.ch)) sc.SetState(SCE_BIB_DEFAULT);                    
            break;
            case SCE_BIB_FIELD:
                if(!iswordchar(sc.ch)) {  //sc.SetState(SCE_BIB_DEFAULT);                    
                   sc.GetCurrentLowered(word, sizeof(word)-1);
                    int length = strlen(word);

                    if(length>1){
                        word[length] = 0;
                        if(!keywords.InList(word))  sc.ChangeState(SCE_BIB_TEXT);
                    }
                    else sc.ChangeState(SCE_BIB_DEFAULT);     // single symbol at EOL
                    sc.SetState(SCE_BIB_DEFAULT); 
				}
            break;
			case SCE_BIB_KEY:
				if(sc.ch==',') sc.SetState(SCE_BIB_DEFAULT); 
			break;
            case SCE_BIB_STRING:
                if(sc.atLineEnd) sc.ForwardSetState(SCE_BIB_STRING); 
                else if(sc.ch=='\"' && sc.chPrev!='\\'){ 
                    if (sc.chNext == '\"') sc.Forward();
                    else sc.ForwardSetState(SCE_BIB_DEFAULT);
				}
            break;            
            case SCE_BIB_SYMBOL:
                if(!issymbol(sc.ch)) sc.SetState(SCE_BIB_DEFAULT);
            break;
            case SCE_BIB_BRACKET:
				if(!isbracket(sc.ch)) sc.SetState(SCE_BIB_DEFAULT);
            break;
            case SCE_BIB_NUMBER:
                if(!isnumber(sc.ch)) sc.SetState(SCE_BIB_DEFAULT);
            break;
            case SCE_BIB_TEXT:
                if(!iswordchar(sc.ch) || !isspace(sc.ch)) sc.SetState(SCE_BIB_DEFAULT);
            break; 
            case SCE_BIB_COMMENT:                         
                if(sc.atLineEnd) sc.SetState(SCE_BIB_TEXT);
            break;                  
        }
        // Determine if a new state should be entered.
        if(sc.state==SCE_BIB_DEFAULT){
				
			//intialize afterEqual;
			if(sc.ch=='=') afterEqual=1;
			if(sc.ch=='@') afterAt=1;
            if(sc.ch==',') {
				afterAt=0; 
				afterEqual=0;
			}
			
			//check if change of state is needed
            if(sc.ch=='@') {
				sc.SetState(SCE_BIB_RECORD); 
			}
            else if(sc.chPrev!='\\' && sc.ch=='\"') sc.SetState(SCE_BIB_STRING);
            else if(sc.chPrev!='\\' && sc.ch=='%') sc.SetState(SCE_BIB_COMMENT);
            else if(afterAt==1 && !isbracket(sc.ch)) sc.SetState(SCE_BIB_KEY);
            else if(isbracket(sc.ch)) sc.SetState(SCE_BIB_BRACKET);    
			else if(isnumber(sc.ch)) sc.SetState(SCE_BIB_NUMBER);
            else if(issymbol(sc.ch)) sc.SetState(SCE_BIB_SYMBOL);            
            else if(afterEqual==0 && iswordchar(sc.ch)) sc.SetState(SCE_BIB_FIELD);
			else if(sc.atLineEnd || isEOL(sc.ch)) sc.ForwardSetState(SCE_BIB_TEXT);
            else sc.SetState(SCE_BIB_TEXT);
        }
    } // for
    
	sc.SetState(SCE_BIB_DEFAULT);
    sc.Complete();
}

static void FoldBIBDoc(unsigned int startPos, int length, int, WordList *[],
                        Accessor &styler) {

	unsigned int endPos = startPos + length;
	int visibleChars = 0;
	int lineCurrent = styler.GetLine(startPos);
	int levelPrev = styler.LevelAt(lineCurrent) & SC_FOLDLEVELNUMBERMASK;
	int levelCurrent = levelPrev;
	char chNext = styler[startPos];
	bool foldCompact = styler.GetPropertyInt("fold.compact", 1) != 0;
	int styleNext = styler.StyleAt(startPos);
	char s[10];

	for (unsigned int i = startPos; i < endPos; i++) {
		char ch = chNext;
		chNext = styler.SafeGetCharAt(i + 1);
		int style = styleNext;
		styleNext = styler.StyleAt(i + 1);
		bool atEOL = (ch == '\r' && chNext != '\n') || (ch == '\n');

		if (style == SCE_BIB_RECORD) {
			if (ch == '@') {
				for (unsigned int j = 0; j < 8; j++) {
					s[j] = styler[i + j];
					s[j + 1] = '\0';
				}
			}
		} else {
			if (ch == '{') {
				levelCurrent++;
			} else if (ch == '}') {
				levelCurrent--;
			}
		}
		if (atEOL) {
			int lev = levelPrev;
			if (visibleChars == 0 && foldCompact) {
				lev |= SC_FOLDLEVELWHITEFLAG;
			}
			if ((levelCurrent > levelPrev) && (visibleChars > 0)) {
				lev |= SC_FOLDLEVELHEADERFLAG;
			}
			if (lev != styler.LevelAt(lineCurrent)) {
				styler.SetLevel(lineCurrent, lev);
			}
			lineCurrent++;
			levelPrev = levelCurrent;
			visibleChars = 0;
		}
		if (!isspacechar(ch))
			visibleChars++;
	}
	// Fill in the real level of the next line, keeping the current flags as they will be filled in later
	int flagsNext = styler.LevelAt(lineCurrent) & ~SC_FOLDLEVELNUMBERMASK;
	styler.SetLevel(lineCurrent, levelPrev | flagsNext);
}

static const char * const bibWordLists[] = {
    "Fields", 0, 0, 0, 0, 0, 0,
};

LexerModule lmBiB(SCLEX_BIBTEX, ColouriseBIBDoc, "bib", FoldBIBDoc, bibWordLists);
