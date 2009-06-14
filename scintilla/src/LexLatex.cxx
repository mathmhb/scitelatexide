// Scintilla source code edit control
/** @file LexLatex.cxx
 ** Lexer for the Latex typesetting language, a replacer of LeXTeX lexer
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
#include "KeyWords.h"
#include "Scintilla.h"
#include "SciLexer.h"
#include "StyleContext.h"

#define KEYWORDS_FOLD 8
#define MAX_CMD_LENGTH  100

// Auxillary functions for LaTeX Lexer ----------------------
static inline bool isnumber(int ch) {
	return
      (ch == '0') || (ch == '1') || (ch == '2') || 
      (ch == '3') || (ch == '4') || (ch == '5') || 
      (ch == '6') || (ch == '7') || (ch == '8') || (ch == '9');
}

static inline bool iswordchar(int ch) {
	return ((ch >= 'a') && (ch <= 'z')) || ((ch >= 'A') && (ch <= 'Z'));
}

static inline bool isbracket(int ch) 
{
	return
      (ch == '(') || (ch == ')') || (ch == '[') || 
      (ch == ']') || (ch == '{') || (ch == '}'); 
}

static inline bool issymbol(int ch)
{
	return (ch == '~') || (ch == '`') || (ch == '\'')|| (ch == '~') ||
           (ch == '#') || (ch == '^') || (ch == '&') || (ch == '+') || 
           (ch == '-') || (ch == '=') || (ch == '>') || (ch == '<') ||
           (ch == '\"') || (ch== '_') || (ch=='@');
}

inline bool isargletter(char ch)
{
    return ((ch >= 'a') && (ch <= 'z')) || ((ch >= 'A') && (ch <= 'Z')) || (ch == '*');
}

inline bool iscmdletter(char ch)
{
    return isargletter(ch) || (ch == '@');
}

inline bool is1cmdletter(char ch)
{
   return (ch==','  || ch==':'  ||  ch==';' || ch=='%'  || ch=='\''  ||  ch=='"' ||  
           ch=='\\' || ch=='['  ||  ch==']' || ch=='{'  || ch=='}'   ||  ch==' ' || 
           ch=='$'  || ch=='^'  ||  ch=='(' || ch==')'  || ch=='-'   ||  ch=='&' || 
           ch=='#'  || ch=='!'  ||  ch=='|');
}

inline bool isEOL(char ch)
{
   return (ch == '\r' || ch == '\n');
}

inline int isequal(char* s, char *t)
{
   for(; *s==*t; s++, t++)
       if(*s==0) return 1;
   return 0;
}

//--------------------------------------------------


static int ParseLaTeXCommand(unsigned int pos, Accessor &styler, char *command)
{
  int length=0;
  char ch=styler.SafeGetCharAt(pos+1);
  
  if(ch==',' || ch==':' || ch==';' || ch=='%'){
      command[0]=ch;
      command[1]=0;
	  return 1;
  }

  // find end
     while(iswordchar(ch) && !isnumber(ch) && ch!='_' && ch!='.' && length< MAX_CMD_LENGTH){
          command[length]=ch;
          length++;
          ch=styler.SafeGetCharAt(pos+length+1);
     }
     
  command[length]='\0';   
  if(!length) return 0;
  return length+1;
}

static int classifyFoldPointLaTeXGroups(const char* s, WordList *keywordlists[]) {
	WordList &groupstart = *keywordlists[6];
	WordList &groupstop  = *keywordlists[7];
	WordList &groupexclude  = *keywordlists[16];
	if(groupexclude.InList(s))  return 0;
	else if(groupstart.InList(s))  return 1;
	else if(groupstop.InList(s)) return -1;
	else return 0;
/*	else{
		int lev=0; 
		if (strcmp(s, "begin")==0||strcmp(s,"unprotect")==0||
			strcmp(s,"title")==0||strncmp(s,"start",5)==0||strncmp(s,"Start",5)==0||
			strncmp(s,"if",2)==0
			)
			lev=1;
		if (strcmp(s, "end")==0||strcmp(s,"protect")==0||
			strcmp(s,"maketitle")==0||strncmp(s,"stop",4)==0||strncmp(s,"Stop",4)==0||
			strcmp(s,"fi")==0
			) 
		lev=-1;
		return lev;
	}*/
}

static int ParseLaTeXHeadersDepth(const char* s, WordList *keywordlists[]) 
	{
// *keywordlists[8] -- *keywordlists[16] corresponds to keywords9.$(file.patterns.latex) -- keywords17.$(file.patterns.latex)
		WordList &headerkeywords1 = *keywordlists[8];
		WordList &headerkeywords2 = *keywordlists[9];
		WordList &headerkeywords3 = *keywordlists[10];
		WordList &headerkeywords4 = *keywordlists[11];
		WordList &headerkeywords5 = *keywordlists[12];
		WordList &headerkeywords6 = *keywordlists[13];
		WordList &headerkeywords7 = *keywordlists[14];
		WordList &headerkeywords8 = *keywordlists[15];		
		WordList &headerkeywords9 = *keywordlists[16];		
// -- user defined headers, put fore-most in order that user defined keywords can overide built-in ones  ----
//  -- headerkeywords9 is used to remove predefined header keywords form the list of folding headers --
		if(headerkeywords9.InList(s)) return 0;
		else if(headerkeywords1.InList(s))  return 1;
		else if(headerkeywords2.InList(s)) return 2;
		else if(headerkeywords3.InList(s)) return 3;
		else if(headerkeywords4.InList(s)) return 4;
		else if(headerkeywords5.InList(s)) return 5;
		else if(headerkeywords6.InList(s)) return 6;
		else if(headerkeywords7.InList(s)) return 7;
		else if(headerkeywords8.InList(s)) return 8;
// --------------- cascaded Header depth --------------------------		
/*		else if(strcmp(s,"documentclass")==0) return 1;
		else if(strcmp(s,"abstract")==0) return 1;
		else if(strcmp(s,"part")==0) return 1;
		else if(strcmp(s,"appendix")==0) return 1;
// --- ConTeXt topic or Topic is equivalent to latex chapters, is that right? -----------
		else if(strcmp(s,"chapter")==0) return 1;
		else if(strcmp(s,"Topic")==0) return 1;
		else if(strcmp(s,"topic")==0) return 1;
// ---------------------------------------------------------------------------------------------------
		else if(strcmp(s,"section")==0) return 2;
		else if(strcmp(s,"subject")==0) return 2;
// ---------------------------------------------------------------------------------------------------
		else if(strcmp(s,"subsection")==0) return 3;
		else if(strcmp(s,"subsubject")==0) return 3;
		else if(strcmp(s,"framed")==0) return 3;
// ---------------------------------------------------------------------------------------------------
		else if(strcmp(s,"subsubsection")==0) return 4;
		else if(strcmp(s,"subsubsubsection")==0) return 5;
		else if(strcmp(s,"paragraph")==0) return 6;
// ----- slide headers are all temporarily of depth 7 -------------------------------------
		else if(strcmp(s,"frame")==0) return 7;
		else if(strcmp(s,"foilhead")==0) return 7;
		else if(strcmp(s,"overlays")==0) return 7;
		else if(strcmp(s,"slide")==0) return 7;
*/		else return 0;
	}

static int classifyFoldPointLaTeXHeaders(const char* s, WordList *keywordlists[]) 
	{
		if(ParseLaTeXHeadersDepth(s, keywordlists)>0){ return 1;}
		else return 0;
	}

// --------------- def, not really headers -----------------------
static int classifyFoldPointLaTeXDefs(const char* s) 
	{
		if(strcmp(s,"def")==0) return 1;
		else if(strcmp(s,"gdef")==0) return 1;
		else if(strcmp(s,"edef")==0) return 1;
		else if(strcmp(s,"xdef")==0) return 1;
		else return 0;
	}

static int TextAtPos(int pos, char *s, Accessor &styler)
{
  char *p=s;
  int   i=0;

    for(; *p && styler.SafeGetCharAt(pos+i)==*p; *p++, i++);
//    return !(int)*p;
    if(!*p) return i;
    return 0;
}

static int IsManualFolderStart(int pos, Accessor &styler)
{
	return (TextAtPos(pos, "%%--<<", styler)) || (TextAtPos(pos, "%%--{{", styler));
}

static bool IsManualFolderStop(int pos, Accessor &styler)
{
	return (TextAtPos(pos, "%%>>--", styler)) || (TextAtPos(pos, "%%}}--", styler));
}

static bool IsTeXCommentLine(int line, Accessor &styler) {
	int pos = styler.LineStart(line);
	int eol_pos = styler.LineStart(line + 1) - 1;
	
	int startpos = pos;
	
	while (startpos<eol_pos){
		if(IsManualFolderStart(startpos, styler) || IsManualFolderStop(startpos, styler)){
			return false;
		}

		char ch = styler[startpos];
		if (ch!='%' && ch!=' ' && ch!='\t') return false;
		else if (ch=='%') return true;
		startpos++;
	}		
	return false;
}

static bool InTeXComment(int line, int position, Accessor &styler) {
	int pos = styler.LineStart(line);
	int eol_pos = styler.LineStart(line + 1) - 1;
	
	int startpos = pos;
	int comment_pos = eol_pos;
	
	while (startpos<eol_pos){
		char ch = styler[startpos];
		if (ch=='%') {
			comment_pos = startpos;
			if(comment_pos < position) return true;
		}
		startpos++;
	}
	return false;
}


static void ColouriseLatexDoc(unsigned int startPos, int length, int initStyle, WordList *keywordlists[], Accessor &styler) 
{
    char word[MAX_CMD_LENGTH]  = "";
    bool running        = 0;
    bool group          = 0;
	bool url=0;
	bool headers=0;
	int  vrb=0;
	char verb_symb;
	
    WordList& keywords1=*keywordlists[0];    // commands
    WordList& keywords2=*keywordlists[1];    
    WordList& keywords3=*keywordlists[2];    
    WordList& keywords4=*keywordlists[3];    
    WordList& keywords5=*keywordlists[4];    // text in braces {}
    WordList& keywords6=*keywordlists[5];            

    styler.StartAt(startPos);
    styler.StartSegment(startPos);

    initStyle = initStyle & 31;

    StyleContext sc(startPos, length, initStyle, styler);
    
    // main loop ---------------------------------------------------------------
    for(running = sc.More(); running; sc.Forward()){
        if (!sc.More()){running = false;}
        
        // current state -------------------------------------------------------
        switch(sc.state){
            // commands -----------------------------
            case SCE_L_COMMAND:
                // single character 
                if(sc.chPrev=='\\' && is1cmdletter(sc.ch)){
                     sc.ForwardSetState(SCE_L_DEFAULT);
                     group=0;                     
                }
                // word characters
                else if(!iscmdletter(sc.ch)){
                    sc.GetCurrent(word, sizeof(word)-1);
                    int length = strlen(word);

                    if(length>1){
                        memmove(word, word+1, length) ;
                        word[length] = 0;
                        if(keywords1.InList(word)){
							sc.ChangeState(SCE_L_COMMAND1);
							headers=1;
						}
						else if(keywords2.InList(word))   sc.ChangeState(SCE_L_COMMAND2);
                        else if(keywords3.InList(word))   sc.ChangeState(SCE_L_COMMAND3);
                        else if(keywords4.InList(word))   sc.ChangeState(SCE_L_COMMAND4);
                        if(isequal(word, "begin")|| isequal(word, "end")) {
							group=1;
							sc.ChangeState(SCE_L_COMMAND5);
						}
						else if(isequal(word, "href")||isequal(word, "url")||isequal(word, "nolinkurl")){
							url=1;
						}
						else if(isequal(word,"verb")){
							vrb=1;
						}
                        else{
							group=0;
							vrb=0;
						}
                    }
                    else sc.ChangeState(SCE_L_DEFAULT);     // single slash at EOL
                    sc.SetState(SCE_L_DEFAULT);
                }
            break;

            //------------------------------------------------------------------
            case SCE_L_COMMENT:            
                if(sc.atLineEnd)        sc.SetState(SCE_L_DEFAULT); // sc.SetState(SCE_L_TEXT);
                group=0;
            break;

            //------------------------------------------------------------------
            case SCE_L_STRING:
                if(sc.atLineEnd) sc.ForwardSetState(SCE_L_STRING); 
                else if((sc.chPrev=='\'' && sc.ch == '\'')||(sc.chPrev=='"')) { //[mhb] 06/14/09: suggested by qsh, to fix latex ``...." coloring bug
                    sc.ForwardSetState(SCE_L_DEFAULT);
				}
            break;            

            //------------------------------------------------------------------
            case SCE_L_URL:
				if(sc.ch==' ' || isbracket(sc.ch) || isEOL(sc.ch)){ 
                    sc.SetState(SCE_L_DEFAULT);
				}
            break;            

			//------------------------------------------------------------------
            case SCE_L_HEADING:
				if(sc.ch=='}'){ 
                    sc.SetState(SCE_L_DEFAULT);
				}
            break;            

            //------------------------------------------------------------------
            case SCE_L_SYMBOL:
                if(vrb==0){
					if(!issymbol(sc.ch)) sc.SetState(SCE_L_DEFAULT);
				}
                group=0;
            break;

            //------------------------------------------------------------------
				
            case SCE_L_BRACKET:
                if(!group){
					if(!isbracket(sc.ch))   sc.SetState(SCE_L_DEFAULT);
                }
                else if(sc.ch=='}'){
                    if(sc.LengthCurrent()>0){
                        sc.GetCurrent(word, sizeof(word)-1);
                        if(keywords5.InList(word))   sc.ChangeState(SCE_L_ARGUMENT1);
                        else if(keywords6.InList(word))   sc.ChangeState(SCE_L_ARGUMENT2);
                        else sc.ChangeState(SCE_L_ARGUMENT);

                        sc.SetState(SCE_L_DEFAULT);
                    }
                    group=0;                    
                }
                else if(!isargletter(sc.ch)){
                      sc.ChangeState(SCE_L_DEFAULT);
                      group=0;                
                }
            break;
            //------------------------------------------------------------------            
            case SCE_L_NUMBER:
                if(!isnumber(sc.ch))    sc.SetState(SCE_L_DEFAULT);
                group=0;
            break;
            //------------------------------------------------------------------            
            case SCE_L_VERBAL:
                if(sc.ch == verb_symb){
					sc.ForwardSetState(SCE_L_DEFAULT);
					vrb=0;
				}
            break;

            //------------------------------------------------------------------            
            case SCE_L_MATHGROUP:
                if(sc.ch!='$') sc.SetState(SCE_L_DEFAULT);
                group=0;                
            break;

            //------------------------------------------------------------------
            case SCE_L_TEXT:
				if(!iswordchar(sc.ch) || !isspace(sc.ch)) {
					sc.SetState(SCE_L_DEFAULT);
				}
            break;

            default: 
                    group=0;
        } // switch

        // new state -----------------------------------------------------------
        if(sc.state==SCE_L_DEFAULT){
            // command
			if(sc.ch=='\\'){
                sc.SetState(SCE_L_COMMAND);
                group = 0;                
            }
            // comment, ...
            else if(sc.ch=='%' && sc.chPrev!='\\') 
                sc.SetState(SCE_L_COMMENT);
			// string
            else if(sc.ch=='`' && sc.chNext=='`'){
				sc.SetState(SCE_L_STRING);
			}	
            // math group        
            else if(sc.ch=='$' && sc.chPrev!='\\'){
                sc.SetState(SCE_L_MATHGROUP);
            }
            // number
            else if(isnumber(sc.ch))
                sc.SetState(SCE_L_NUMBER);

            // text in braces
            else if(isbracket(sc.ch)){
                sc.SetState(SCE_L_BRACKET); 
                if(sc.ch=='{'){
					if(url){
						sc.ForwardSetState(SCE_L_URL);
						url=0;
					}
					if(headers){
						sc.ForwardSetState(SCE_L_HEADING);
						headers=0;
					}
					else if(group && iscmdletter(sc.chNext)){
						sc.ForwardSetState(SCE_L_BRACKET); 
					}
					else group=0;
				}
            }
            // symbol
            else if(issymbol(sc.ch))
				if(vrb==0){
					sc.SetState(SCE_L_SYMBOL);
				}
				else{
					verb_symb=sc.ch;
					sc.ChangeState(SCE_L_VERBAL);
				}
            // line end
            else if(sc.atLineEnd || isEOL(sc.ch)){
                sc.SetState(SCE_L_TEXT);
                group    = 0;
            }
			else sc.SetState(SCE_L_TEXT);            
        } 
    } 

    sc.ChangeState(SCE_L_TEXT);
    sc.Complete();
}

static void FoldLaTeXDoc(unsigned int startPos, int length, int initStyle, WordList *keywordlists[], Accessor &styler) 
{
	bool foldCompact = styler.GetPropertyInt("fold.compact", 1) != 0;
	bool foldComment = styler.GetPropertyInt("fold.comment") != 0;

	unsigned int endPos = startPos+length;
	int visibleChars=0;
	int lineCurrent=styler.GetLine(startPos);
	int levelPrev=styler.LevelAt(lineCurrent) & SC_FOLDLEVELNUMBERMASK;
	int levelCurrent=levelPrev;
	char chNext=styler[startPos];
	char buffer[MAX_CMD_LENGTH]="";
	int depth=0;
	int prevdepth=0;
	int nextdepth=0;
	int countDefs=0;
	int numDefs=0;
	int headerPoint=0;
	int style=initStyle;
	int n;	

// -------------------------------------------------------------	
    if(startPos>0){
        if(lineCurrent>0){
            lineCurrent--;
	        startPos     = styler.LineStart(lineCurrent);
            levelCurrent = styler.LevelAt(lineCurrent) & SC_FOLDLEVELNUMBERMASK;
        }
    }
	chNext          = styler.SafeGetCharAt(startPos);
	levelPrev       = levelCurrent;
// --------------------------------------------------------------

	
	for (unsigned int i=startPos; i < endPos; i++) {
		char ch=chNext;
		chNext=styler.SafeGetCharAt(i+1);
        style = styler.StyleAt(i);        

		bool atEOL = (ch == '\r' && chNext != '\n') || (ch == '\n');
		
		if(!(style==SCE_L_VERBAL)){
			if(ch=='\\' && !InTeXComment(lineCurrent, i+1, styler))
			{
				int len=ParseLaTeXCommand(i, styler, buffer);

				headerPoint=classifyFoldPointLaTeXHeaders(buffer,keywordlists);
				numDefs=classifyFoldPointLaTeXDefs(buffer);
				depth=ParseLaTeXHeadersDepth(buffer,keywordlists);
				if(numDefs>0){countDefs=numDefs;}
				if(depth>0){prevdepth=depth;} 

				int addToLevel=classifyFoldPointLaTeXGroups(buffer,keywordlists)
					+headerPoint+numDefs;
				levelCurrent+=addToLevel;
				if(addToLevel){
					i+=len-1; // skip this command
					ch=styler.SafeGetCharAt(i); // new current character
					chNext=styler.SafeGetCharAt(i+1); //new next character
				}
			}

			if(ch == '\r' || ch=='\n')
			{
				if(styler.SafeGetCharAt(i+1)=='\\' && !InTeXComment(lineCurrent, i+1, styler))
				{
					ParseLaTeXCommand(i+1, styler, buffer);
					depth=ParseLaTeXHeadersDepth(buffer,keywordlists);
					headerPoint=classifyFoldPointLaTeXHeaders(buffer,keywordlists);
				
					if(depth>0){nextdepth=depth;}
				
					if(prevdepth!=0 && nextdepth!=0){
						levelCurrent-=headerPoint+prevdepth-nextdepth;
					}
					else if(levelCurrent>0)
					{
						levelCurrent-=headerPoint;
					}
				}
			}
		
			if(ch=='\\' && chNext=='[') levelCurrent+=1;
			if(ch=='\\' && chNext==']') levelCurrent-=1;

			if(ch=='}' && countDefs>0){
				levelCurrent--;
				countDefs=0;
			}

			if(style== SCE_L_COMMENT) {
				if(n=IsManualFolderStart(i,styler)){
					i+=n-1;
					levelCurrent++; 
				}
				else if(n=IsManualFolderStop(i,styler)){
					i+=n-1;
					levelCurrent--; 
				}
				else if (foldComment && isEOL(ch) && IsTeXCommentLine(lineCurrent, styler)) {
					if (!IsTeXCommentLine(lineCurrent - 1, styler) && IsTeXCommentLine(lineCurrent + 1, styler)) 
						levelCurrent+=1;
					else if (IsTeXCommentLine(lineCurrent - 1, styler) && !IsTeXCommentLine(lineCurrent+1, styler))
						levelCurrent-=1;
				}
			}
		}
		
//---------------------------------------------------------------------------------------------	

		if (atEOL) {
			int lev = levelPrev;
			if (visibleChars == 0 && foldCompact)
				lev |= SC_FOLDLEVELWHITEFLAG;
			if ((levelCurrent > levelPrev) && (visibleChars > 0))
				lev |= SC_FOLDLEVELHEADERFLAG;
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




static const char * const latexWordListDesc[] = {
    "TeX, eTeX, pdfTeX, Omega",
    "ConTeXt Dutch",
    "ConTeXt English",
    "ConTeXt German",
    "ConTeXt Czech",
    "ConTeXt Italian",
    "ConTeXt Romanian",
	"FoldHeader1",
	"FoldHeader2",
	"FoldHeader3",
	"FoldHeader4",
	"FoldHeader5",
	"FoldHeader6",
	"FoldHeader7",
	"FoldHeader8",
	"FoldHeader9",
	0,
} ;

LexerModule lmLatex(SCLEX_LATEX, ColouriseLatexDoc, "latex", FoldLaTeXDoc, latexWordListDesc);
