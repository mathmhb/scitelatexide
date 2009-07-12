// SciTE - Scintilla based Text Editor
/** @file PropSetFile.cxx
 ** Property set implementation.
 **/
// Copyright 1998-2007 by Neil Hodgson <neilh@scintilla.org>
// The License.txt file describes the conditions under which this software may be distributed.

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <fcntl.h>
#include <time.h>
#include <locale.h>

#include "Platform.h"

#if PLAT_GTK

#include <unistd.h>

#endif

#include "PropSet.h"
#include "Scintilla.h"
#include "FilePath.h"
#include "PropSetFile.h"

bool PropSetFile::caseSensitiveFilenames = false;

PropSetFile::PropSetFile(bool lowerKeys_) : lowerKeys(lowerKeys_) {}

PropSetFile::~PropSetFile() {}

/**
 * Get a line of input. If end of line escaped with '\\' then continue reading.
 */
static bool GetFullLine(const char *&fpc, int &lenData, char *s, int len) {
	bool continuation = true;
	s[0] = '\0';
	while ((len > 1) && lenData > 0) {
		char ch = *fpc;
		fpc++;
		lenData--;
		if ((ch == '\r') || (ch == '\n')) {
			if (!continuation) {
				if ((lenData > 0) && (ch == '\r') && ((*fpc) == '\n')) {
					// munch the second half of a crlf
					fpc++;
					lenData--;
				}
				*s = '\0';
				return true;
			}
		} else if ((ch == '\\') && (lenData > 0) && ((*fpc == '\r') || (*fpc == '\n'))) {
			continuation = true;
			if ((lenData > 1) && (((*fpc == '\r') && (*(fpc+1) == '\r')) || ((*fpc == '\n') && (*(fpc+1) == '\n'))))
				continuation = false;
			else if ((lenData > 2) && ((*fpc == '\r') && (*(fpc+1) == '\n') && (*(fpc+2) == '\n' || *(fpc+2) == '\r')))
				continuation = false;
		} else {
			continuation = false;
			*s++ = ch;
			*s = '\0';
			len--;
		}
	}
	return false;
}

static bool IsSpaceOrTab(char ch) {
	return (ch == ' ') || (ch == '\t');
}

static bool IsCommentLine(const char *line) {
	while (IsSpaceOrTab(*line)) ++line;
	return (*line == '#');
}

bool PropSetFile::ReadLine(const char *lineBuffer, bool ifIsTrue, FilePath directoryForImports,
                           FilePath imports[], int sizeImports) {
	//UnSlash(lineBuffer);
	if (!IsSpaceOrTab(lineBuffer[0]))    // If clause ends with first non-indented line
		ifIsTrue = true;
	if (isprefix(lineBuffer, "if ")) {
		const char *expr = lineBuffer + strlen("if") + 1;
		ifIsTrue = GetInt(expr) != 0;
	} else if (isprefix(lineBuffer, "import ") && directoryForImports.IsSet()) {
		SString importName(lineBuffer + strlen("import") + 1);
		//!importName += ".properties";
		bool loaded = false; //!-add-[import]
		FilePath importPath(directoryForImports, FilePath(importName.c_str()));
		if (Read(importPath, directoryForImports, imports, sizeImports)) {
//!-start-[import]
			loaded = true;
		} else {
			importName += ".properties";
			importPath.Set(directoryForImports, FilePath(importName.c_str()));
			if (Read(importPath, directoryForImports, imports, sizeImports)) {
				loaded = true;
			}
		}
		if (loaded) {
//!-end-[import]
			if (imports) {
				for (int i = 0; i < sizeImports; i++) {
					if (!imports[i].IsSet()) {
						imports[i] = importPath;
						break;
					}
				}
			}
		}
	} else if (ifIsTrue && !IsCommentLine(lineBuffer)) {
		Set(lineBuffer);
	}
	return ifIsTrue;
}

void PropSetFile::ReadFromMemory(const char *data, int len, FilePath directoryForImports,
                                 FilePath imports[], int sizeImports) {
	const char *pd = data;
	char lineBuffer[60000];
	bool ifIsTrue = true;
	while (len > 0) {
		GetFullLine(pd, len, lineBuffer, sizeof(lineBuffer));
		if (lowerKeys) {
			for (int i=0; lineBuffer[i] && (lineBuffer[i] != '='); i++) {
				if ((lineBuffer[i] >= 'A') && (lineBuffer[i] <= 'Z')) {
					lineBuffer[i] = static_cast<char>(lineBuffer[i] - 'A' + 'a');
				}
			}
		}
		ifIsTrue = ReadLine(lineBuffer, ifIsTrue, directoryForImports, imports, sizeImports);
	}
}

bool PropSetFile::Read(FilePath filename, FilePath directoryForImports,
                       FilePath imports[], int sizeImports) {
	FILE *rcfile = filename.Open(fileRead);
	if (rcfile) {
		char propsData[60000];
		int lenFile = static_cast<int>(fread(propsData, 1, sizeof(propsData), rcfile));
		fclose(rcfile);
		const char *data = propsData;
		if (memcmp(data, "\xef\xbb\xbf", 3) == 0) {
			data += 3;
			lenFile -= 3;
		}
		ReadFromMemory(data, lenFile, directoryForImports, imports, sizeImports);
		return true;
	}
	return false;
}

void PropSetFile::SetInteger(const char *key, sptr_t i) {
	char tmp[32];
	sprintf(tmp, "%d", static_cast<int>(i));
	Set(key, tmp);
}

static inline char MakeUpperCase(char ch) {
	if (ch < 'a' || ch > 'z')
		return ch;
	else
		return static_cast<char>(ch - 'a' + 'A');
}

static bool StringEqual(const char *a, const char *b, size_t len, bool caseSensitive) {
	if (caseSensitive) {
		for (size_t i = 0; i < len; i++) {
			if (a[i] != b[i])
				return false;
		}
	} else {
		for (size_t i = 0; i < len; i++) {
			if (MakeUpperCase(a[i]) != MakeUpperCase(b[i]))
				return false;
		}
	}
	return true;
}

// Match file names to patterns allowing for a '*' suffix or prefix.
static bool MatchWild(const char *pattern, size_t lenPattern, const char *fileName, bool caseSensitive) {
	size_t lenFileName = strlen(fileName);
	if (lenFileName == lenPattern) {
		if (StringEqual(pattern, fileName, lenFileName, caseSensitive)) {
			return true;
		}
	}
	if (lenFileName >= lenPattern-1) {
		if (pattern[0] == '*') {
			// Matching suffixes
			return StringEqual(pattern+1, fileName + lenFileName - (lenPattern-1), lenPattern-1, caseSensitive);
		} else if (pattern[lenPattern-1] == '*') {
			// Matching prefixes
			return StringEqual(pattern, fileName, lenPattern-1, caseSensitive);
		}
	}
	return false;
}

//[mhb] 06/22/09 added: Match filenames to multiple patterns seperated by ";"
static bool MatchPatterns(const char *patterns, const char *fileName, bool caseSensitive) {
	char *keyfile=StringDup(patterns);
	for (;;) {
		char *del = strchr(keyfile, ';');
		if (del == NULL)
			del = keyfile + strlen(keyfile);
		if (MatchWild(keyfile, del - keyfile, fileName, caseSensitive)) {
			delete []keyfile;
			return true;
		}
		if (*del == '\0')
			break;
		keyfile = del + 1;
	}
	return false;
}

SString PropSetFile::GetWildUsingStart(const PropSet &psStart, const char *keybase, const char *filename) {

	for (int root = 0; root < hashRoots; root++) {
		for (Property *p = props[root]; p; p = p->next) {
			if (isprefix(p->key, keybase)) {
				char *orgkeyfile = p->key + strlen(keybase);
				char *keyfile = NULL;

				if (strncmp(orgkeyfile, "$(", 2) == 0) {
					const char *cpendvar = strchr(orgkeyfile, ')');
					if (cpendvar) {
						SString var(orgkeyfile, 2, cpendvar-orgkeyfile);
						SString s = psStart.GetExpanded(var.c_str());
						keyfile = StringDup(s.c_str());
					}
				}
				char *keyptr = keyfile;

				if (keyfile == NULL)
					keyfile = orgkeyfile;

				for (;;) {
					char *del = strchr(keyfile, ';');
					if (del == NULL)
						del = keyfile + strlen(keyfile);
					if (MatchWild(keyfile, del - keyfile, filename, caseSensitiveFilenames)) {
						delete []keyptr;
						return p->val;
					}
					if (*del == '\0')
						break;
					keyfile = del + 1;
				}
				delete []keyptr;

				if (0 == strcmp(p->key, keybase)) {
					return p->val;
				}
			}
		}
	}
	if (superPS) {
		// Failed here, so try in super property set
		return static_cast<PropSetFile *>(superPS)->GetWildUsingStart(psStart, keybase, filename);
	} else {
		return "";
	}
}

//[mhb] 06/22/09 added: to extract property "keybase.keyext"
SString PropSetFile::GetPropExt(const char *fmt, const char *keybase, const char *keyext) {
	char buf[100];
	SString s;
	sprintf(buf,fmt,keybase,keyext);
	s=GetExpanded(buf);
	return s;
}
//[mhb] 06/22/09 added: to extract current file type via searching property "get.wild.filetypes"
SString PropSetFile::GetFileType(const char *filename) {
	SString ft=GetExpanded("get.wild.filetypes");
	//search file.patterns.xxx for any xxx in property "get.wild.filetypes"
	char *p=StringDup(ft.c_str()),*q=NULL,*p0=p;
	while (*p) {
		q=strchr(p,';');
		if (q) {*q=0;}
		SString fp=GetPropExt("%s.%s","file.patterns",p);
		if (MatchPatterns(fp.c_str(), filename, caseSensitiveFilenames)) {
            q=strdup(p);
			delete []p0;
			return SString(q);
		}
		if (!q) {break;} else {p=q+1;}
	}
	delete []p0;
	return SString("");
}

SString PropSetFile::GetWild(const char *keybase, const char *filename) {
	//[mhb] added: use new property "get.wild.mode" to choose how to GetWild
	SString wild_mode=GetExpanded("get.wild.mode");
	if (wild_mode.value()==0) {// use original very slow method in SciTE
		return GetWildUsingStart(*this, keybase, filename);
	}
	
	//[mhb] 06/22/09: use new FAST method, not searching the whole properties files
	SString s=GetPropExt("%s%s",keybase,filename);
	if (s.length()==0) {
		char *ext=strrchr(filename,'.');
		if (ext) {s=GetPropExt("%s*%s",keybase,ext);}
	}
	if (s.length()==0) {
		SString typ="";
		if (wild_mode.value()>1) {//[mhb] 07/12/09 : use prop FileType only when get.wild.mode>1
			typ=GetExpanded("FileType");//automatically set when open/switch file
		}
        if (typ.length()==0) {
            typ=GetFileType(filename);//if FileType is not set, try to detect by using GetFileType
        }
		if (typ.length()>0) {
			s=GetPropExt("%s$(file.patterns.%s)",keybase,typ.c_str());
		}
	}
	if (s.length()==0) {
		s=GetPropExt("%s%s",keybase,"*");
	}
	return s;
}

// GetNewExpand does not use Expand as it has to use GetWild with the filename for each
// variable reference found.
SString PropSetFile::GetNewExpand(const char *keybase, const char *filename) {
	char *base = StringDup(GetWild(keybase, filename).c_str());
	char *cpvar = strstr(base, "$(");
	int maxExpands = 1000;	// Avoid infinite expansion of recursive definitions
	while (cpvar && (maxExpands > 0)) {
		const char *cpendvar = strchr(cpvar, ')');
		if (cpendvar) {
			int lenvar = cpendvar - cpvar - 2;  	// Subtract the $()
			char *var = StringDup(cpvar + 2, lenvar);
			SString val = GetWild(var, filename);
			if (0 == strcmp(var, keybase))
				val.clear(); // Self-references evaluate to empty string
			size_t newlenbase = strlen(base) + val.length() - lenvar;
			char *newbase = new char[newlenbase];
			strncpy(newbase, base, cpvar - base);
			strcpy(newbase + (cpvar - base), val.c_str());
			strcpy(newbase + (cpvar - base) + val.length(), cpendvar + 1);
			delete []var;
			delete []base;
			base = newbase;
		}
		cpvar = strstr(base, "$(");
		maxExpands--;
	}
	SString sret = base;
	delete []base;
	return sret;
}

/**
 * Initiate enumeration.
 */
bool PropSetFile::GetFirst(char **key, char **val) {
	for (int i = 0; i < hashRoots; i++) {
		for (Property *p = props[i]; p; p = p->next) {
			if (p) {
				*key = p->key;
				*val = p->val;
				enumnext = p->next; // GetNext will begin here ...
				enumhash = i;		  // ... in this block
				return true;
			}
		}
	}
	return false;
}

/**
 * Continue enumeration.
 */
bool PropSetFile::GetNext(char ** key, char ** val) {
	bool firstloop = true;

	// search begins where we left it : in enumhash block
	for (int i = enumhash; i < hashRoots; i++) {
		if (!firstloop)
			enumnext = props[i]; // Begin with first property in block
		// else : begin where we left
		firstloop = false;

		for (Property *p = enumnext; p; p = p->next) {
			if (p) {
				*key = p->key;
				*val = p->val;
				enumnext = p->next; // for GetNext
				enumhash = i;
				return true;
			}
		}
	}
	return false;
}

