// SciTE - Scintilla based Text Editor
/** @file SciTEWinBar.cxx
 ** Bar and menu code for the Windows version of the editor.
 **/
// Copyright 1998-2003 by Neil Hodgson <neilh@scintilla.org>
// The License.txt file describes the conditions under which this software may be distributed.

#include "SciTEWin.h"

/**
 * Set up properties for FileTime, FileDate, CurrentTime, CurrentDate and FileAttr.
 */
void SciTEWin::SetFileProperties(
    PropSetFile &ps) {			///< Property set to update.

	const int TEMP_LEN = 100;
	char temp[TEMP_LEN];
	HANDLE hf = ::CreateFile(filePath.AsFileSystem(), GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	if (hf != INVALID_HANDLE_VALUE) {
		FILETIME ft;
		::GetFileTime(hf, NULL, NULL, &ft);
		::CloseHandle(hf);
		FILETIME lft;
		::FileTimeToLocalFileTime(&ft, &lft);
		SYSTEMTIME st;
		::FileTimeToSystemTime(&lft, &st);
		::GetTimeFormat(LOCALE_USER_DEFAULT,
		                0, &st,
		                NULL, temp, TEMP_LEN);
		ps.Set("FileTime", temp);

		::GetDateFormat(LOCALE_USER_DEFAULT,
		                DATE_SHORTDATE, &st,
		                NULL, temp, TEMP_LEN);
		ps.Set("FileDate", temp);

		DWORD attr = ::GetFileAttributes(filePath.AsFileSystem());
		SString fa;
		if (attr & FILE_ATTRIBUTE_READONLY) {
			fa += "R";
		}
		if (attr & FILE_ATTRIBUTE_HIDDEN) {
			fa += "H";
		}
		if (attr & FILE_ATTRIBUTE_SYSTEM) {
			fa += "S";
		}
		ps.Set("FileAttr", fa.c_str());
	} else {
		/* Reset values for new buffers with no file */
		ps.Set("FileTime", "");
		ps.Set("FileDate", "");
		ps.Set("FileAttr", "");
	}

	::GetDateFormat(LOCALE_USER_DEFAULT,
	                DATE_SHORTDATE, NULL,     	// Current date
	                NULL, temp, TEMP_LEN);
	ps.Set("CurrentDate", temp);

	::GetTimeFormat(LOCALE_USER_DEFAULT,
	                0, NULL,     	// Current time
	                NULL, temp, TEMP_LEN);
	ps.Set("CurrentTime", temp);
}

/**
 * Update the status bar text.
 */
void SciTEWin::SetStatusBarText(const char *s) {
	::SendMessage(reinterpret_cast<HWND>(wStatusBar.GetID()),
	              SB_SETTEXT, 0, reinterpret_cast<LPARAM>(s));
}

void SciTEWin::TabInsert(int index, char *title) {
	TCITEM tie;
	tie.mask = TCIF_TEXT | TCIF_IMAGE;
	tie.iImage = -1;
	tie.pszText = title;
	::SendMessage(reinterpret_cast<HWND>(wTabBar.GetID()), TCM_INSERTITEM, (WPARAM)index, (LPARAM)&tie);
}

void SciTEWin::TabSelect(int index) {
	::SendMessage(reinterpret_cast<HWND>(wTabBar.GetID()), TCM_SETCURSEL, (WPARAM)index, (LPARAM)0);
}

void SciTEWin::RemoveAllTabs() {
	::SendMessage(reinterpret_cast<HWND>(wTabBar.GetID()), TCM_DELETEALLITEMS, (WPARAM)0, (LPARAM)0);
}

/**
 * Manage Windows specific notifications.
 */
void SciTEWin::Notify(SCNotification *notification) {
	switch (notification->nmhdr.code) {
	case TCN_SELCHANGE:
		// Change of tab
		if (notification->nmhdr.idFrom == IDM_TABWIN) {
			int index = Platform::SendScintilla(wTabBar.GetID(), TCM_GETCURSEL, (WPARAM)0, (LPARAM)0);
			SetDocumentAt(index);
			CheckReload();
		}
		break;

	case NM_RCLICK:
		// Right click on a control
		if (notification->nmhdr.idFrom == IDM_TABWIN) {

			Point ptCursor;
			::GetCursorPos(reinterpret_cast<POINT *>(&ptCursor));
			Point ptClient = ptCursor;
			::ScreenToClient(reinterpret_cast<HWND>(wTabBar.GetID()),
			                 reinterpret_cast<POINT *>(&ptClient));
			TCHITTESTINFO info;
			info.pt.x = ptClient.x;
			info.pt.y = ptClient.y;

			int tabbarHitLast = TabCtrl_HitTest(reinterpret_cast<HWND> (wTabBar.GetID()), &info);

			if (buffers.Current() != tabbarHitLast) {
				SetDocumentAt(tabbarHitLast);
				CheckReload();
			}

			// Pop up menu here:
/*!
			popup.CreatePopUp();
			AddToPopUp("Close", IDM_CLOSE, true);
			AddToPopUp("");
			AddToPopUp("Save", IDM_SAVE, true);
			AddToPopUp("Save As", IDM_SAVEAS, true);
			AddToPopUp("");

			bool bAddSeparator = false;
			for (int item = 0; item < toolMax; item++) {
				int itemID = IDM_TOOLS + item;
				SString prefix = "command.name.";
				prefix += SString(item);
				prefix += ".";
				SString commandName = props.GetNewExpand(prefix.c_str(), filePath.AsInternal());
				if (commandName.length()) {
					SString sMenuItem = commandName;
					SString sMnemonic = "Ctrl+";
					sMnemonic += SString(item);
					AddToPopUp(sMenuItem.c_str(), itemID, true);
					bAddSeparator = true;
				}
			}

			if (bAddSeparator)
				AddToPopUp("");

			AddToPopUp("Print", IDM_PRINT, true);
			popup.Show(ptCursor, wSciTE);
*/
//!-start-[ExtendedContextMenu]
			int item = 0;
			MenuEx subMenu[50];
			subMenu[0].CreatePopUp();

			bool isAdded = false;
			SString tabContextMenu = props.GetNewExpand("user.tabcontext.menu.", ExtensionFileName().c_str());
			tabContextMenu.substitute('|', '\0');
			const char *userContextItem = tabContextMenu.c_str();
			const char *endDefinition = userContextItem + tabContextMenu.length();
			GenerateMenu(subMenu, userContextItem, endDefinition, 
				item, isAdded);

			if (!isAdded) {
				subMenu[0].Add(localiser.Text("Close").c_str(), IDM_CLOSE, IsMenuItemEnabled(IDM_CLOSE));
				subMenu[0].Add();
				subMenu[0].Add(localiser.Text("Save").c_str(), IDM_SAVE, IsMenuItemEnabled(IDM_SAVE));
				subMenu[0].Add(localiser.Text("Save As").c_str(), IDM_SAVEAS, IsMenuItemEnabled(IDM_SAVEAS));
				subMenu[0].Add();
				subMenu[0].Add(localiser.Text("Print").c_str(), IDM_PRINT, IsMenuItemEnabled(IDM_PRINT));
			}	

			subMenu[0].Show(ptCursor, wSciTE);
//!-end-[ExtendedContextMenu]
		}
		break;

	case NM_CLICK:
		// Click on a control
		if (notification->nmhdr.idFrom == IDM_STATUSWIN) {
			// Click on the status bar
			NMMOUSE *pNMMouse = (NMMOUSE *)notification;
			switch (pNMMouse->dwItemSpec) {
			case 0: 		/* Display of status */
				sbNum++;
				if (sbNum > props.GetInt("statusbar.number")) {
					sbNum = 1;
				}
				UpdateStatusBar(true);
				break;
			default:
				break;
			}
		}
		break;

	case TTN_GETDISPINFO:
		// Ask for tooltip text
		{
			static char ttt[MAX_PATH*2 + 1];
//!			const char *ttext = 0; //!-change-[user.toolbar]
			NMTTDISPINFO *pDispInfo = (NMTTDISPINFO *)notification;
			// Toolbar tooltips
/*!
			switch (notification->nmhdr.idFrom) {
			case IDM_NEW:
				ttext = "New";
				break;
			case IDM_OPEN:
				ttext = "Open";
				break;
			case IDM_SAVE:
				ttext = "Save";
				break;
			case IDM_CLOSE:
				ttext = "Close";
				break;
			case IDM_PRINT:
				ttext = "Print";
				break;
			case IDM_CUT:
				ttext = "Cut";
				break;
			case IDM_COPY:
				ttext = "Copy";
				break;
			case IDM_PASTE:
				ttext = "Paste";
				break;
			case IDM_CLEAR:
				ttext = "Delete";
				break;
			case IDM_UNDO:
				ttext = "Undo";
				break;
			case IDM_REDO:
				ttext = "Redo";
				break;
			case IDM_FIND:
				ttext = "Find";
				break;
			case IDM_REPLACE:
				ttext = "Replace";
				break;
			case IDM_MACRORECORD:
				ttext = "Record Macro";
				break;
			case IDM_MACROSTOPRECORD:
				ttext = "Stop Recording";
				break;
			case IDM_MACROPLAY:
				ttext = "Run Macro";
				break;
			default: {
*/
//!-start-[user.toolbar]
			SString stext;
			if (ToolBarTips.Lookup(notification->nmhdr.idFrom, stext)) {
				SString localised = localiser.Text(stext.c_str());
				strcpy(ttt, localised.c_str());
				pDispInfo->lpszText = ttt;
			}
			else {
//!-end-[user.toolbar]
					// notification->nmhdr.idFrom appears to be the buffer number for tabbar tooltips
					Point ptCursor;
					::GetCursorPos(reinterpret_cast<POINT *>(&ptCursor));
					Point ptClient = ptCursor;
					::ScreenToClient(reinterpret_cast<HWND>(wTabBar.GetID()),
					                 reinterpret_cast<POINT *>(&ptClient));
					TCHITTESTINFO info;
					info.pt.x = ptClient.x;
					info.pt.y = ptClient.y;
					int index = Platform::SendScintilla(wTabBar.GetID(), TCM_HITTEST, (WPARAM)0, (LPARAM) & info);
					if (index >= 0) {
						SString path = buffers.buffers[index].AsInternal();
						// Handle '&' characters in path, since they are interpreted in
						// tooltips.
						int amp = 0;
						while ((amp = path.search("&", amp)) >= 0) {
							path.insert(amp, "&");
							amp += 2;
						}
						strcpy(ttt, path.c_str());
						pDispInfo->lpszText = const_cast<char *>(ttt);
					}
/*!
				}
				break;
			}
			if (ttext) {
				SString localised = localiser.Text(ttext);
				strcpy(ttt, localised.c_str());
				pDispInfo->lpszText = ttt;
*/
			}
			break;
		}

	case SCN_CHARADDED:
		if ((notification->nmhdr.idFrom == IDM_RUNWIN) &&
		        jobQueue.IsExecuting() &&
		        hWriteSubProcess) {
			char chToWrite = static_cast<char>(notification->ch);
			if (chToWrite != '\r') {
				DWORD bytesWrote = 0;
				::WriteFile(hWriteSubProcess, &chToWrite,
				            1, &bytesWrote, NULL);
			}
		} else {
			SciTEBase::Notify(notification);
		}
		break;

	default:     	// Scintilla notification, use default treatment
		SciTEBase::Notify(notification);
		break;
	}
}

void SciTEWin::ShowToolBar() {
	SizeSubWindows();
}

void SciTEWin::ShowTabBar() {
	SizeSubWindows();
}

void SciTEWin::ShowStatusBar() {
	SizeSubWindows();
}

void SciTEWin::ActivateWindow(const char *) {
	// This does nothing as, on Windows, you can no longer activate yourself
}

/**
 * Resize the content windows, embedding the editor and output windows.
 */
void SciTEWin::SizeContentWindows() {
	PRectangle rcInternal = wContent.GetClientPosition();

	int w = rcInternal.Width();
	int h = rcInternal.Height();
	heightOutput = NormaliseSplit(heightOutput);

	if (splitVertical) {
		wEditor.SetPosition(PRectangle(0, 0, w - heightOutput - heightBar, h));
		wOutput.SetPosition(PRectangle(w - heightOutput, 0, w, h));
	} else {
		wEditor.SetPosition(PRectangle(0, 0, w, h - heightOutput - heightBar));
		wOutput.SetPosition(PRectangle(0, h - heightOutput, w, h));
	}
	wContent.InvalidateAll();
}

/**
 * Resize the sub-windows, ie. the toolbar, tab bar, status bar. And call @a SizeContentWindows.
 */
void SciTEWin::SizeSubWindows() {
	PRectangle rcClient = wSciTE.GetClientPosition();
	bool showTab = false;

	//::SendMessage(MainHWND(), WM_SETREDRAW, false, 0); // suppress flashing
	visHeightTools = tbVisible ? heightTools : 0;

	if (tabVisible) {	// ? hide one tab only
		showTab = tabHideOne ?
		          ::SendMessage(reinterpret_cast<HWND>(wTabBar.GetID()), TCM_GETITEMCOUNT, 0, 0) > 1 :
		          true;
	}

	if (showTab) {
		wTabBar.SetPosition(PRectangle(
			rcClient.left, rcClient.top + visHeightTools,
			rcClient.right, rcClient.top + heightTab + visHeightTools));
		int tabNb = ::SendMessage(reinterpret_cast<HWND>(
			wTabBar.GetID()), TCM_GETROWCOUNT, 0, 0);
		visHeightTab = ((tabNb - 1) * (heightTab - 6)) + heightTab;
	} else {
		visHeightTab = 0;
	}
	visHeightStatus = sbVisible ? heightStatus : 0;
	visHeightEditor = rcClient.Height() - visHeightTools - visHeightStatus - visHeightTab;
	if (visHeightEditor < 1) {
		visHeightTools = 1;
		visHeightStatus = 1;
		visHeightTab = 1;
		visHeightEditor = rcClient.Height() - visHeightTools - visHeightStatus - visHeightTab;
	}
	if (tbVisible) {
		wToolBar.SetPosition(PRectangle(
		                         rcClient.left, rcClient.top, rcClient.right, visHeightTools));
		wToolBar.Show(true);
	} else {
		wToolBar.Show(false);
		wToolBar.SetPosition(PRectangle(
		                         rcClient.left, rcClient.top - 2, rcClient.Width(), 1));
	}
	if (showTab) {
		wTabBar.SetPosition(PRectangle(
		                        rcClient.left, rcClient.top + visHeightTools,
		                        rcClient.right, rcClient.top + visHeightTab + visHeightTools));
		wTabBar.Show(true);
	} else {
		wTabBar.Show(false);
		wTabBar.SetPosition(PRectangle(
		                        rcClient.left, rcClient.top - 2,
		                        rcClient.Width(), 1));
	}
	if (sbVisible) {
		wStatusBar.SetPosition(PRectangle(
		                           rcClient.left, rcClient.top + visHeightTools + visHeightTab + visHeightEditor,
		                           rcClient.right,
		                           rcClient.top + visHeightTools + visHeightTab + visHeightEditor + visHeightStatus));
		wStatusBar.Show(true);
	} else {
		wStatusBar.Show(false);
		wStatusBar.SetPosition(PRectangle(
		                           rcClient.left, rcClient.top - 2, rcClient.Width(), 1));
	}

	wContent.SetPosition(PRectangle(
	                         rcClient.left, rcClient.top + visHeightTab + visHeightTools,
	                         rcClient.right,
	                         rcClient.top + visHeightTab + visHeightTools + visHeightEditor));
	SizeContentWindows();
	//::SendMessage(MainHWND(), WM_SETREDRAW, true, 0);
	//::RedrawWindow(MainHWND(), NULL, NULL, RDW_INVALIDATE | RDW_ALLCHILDREN);
}



// Keymod param is interpreted using the same notation (and much the same
// code) as KeyMatch uses in SciTEWin.cxx.


//!-start-[user.toolbar]
struct BarButtonIn {
	BarButtonIn() :id(0), cmd(0) {};
	BarButtonIn(int _id, int _cmd) : id(_id), cmd(_cmd) {};
	int id;
	int cmd;
};

void SciTEWin::SetToolBar() {
	ToolBarTips.RemoveAll();
	toolbarUsersPressableButtons.RemoveAll(); //!-add-[ToolbarButtonPressed]
	wToolBar.Destroy();
	HWND hwndToolBar = ::CreateWindowEx( 0,
										 TOOLBARCLASSNAME,
										 "",
										 WS_CHILD | WS_CLIPCHILDREN | WS_CLIPSIBLINGS |
										 TBSTYLE_FLAT | TBSTYLE_TOOLTIPS | CCS_NORESIZE,
										 0, 0,
										 100, heightTools,
										 MainHWND(),
										 reinterpret_cast<HMENU>(IDM_TOOLWIN),
										 hInstance,
										 0 );
	wToolBar = hwndToolBar;

	::SendMessage(hwndToolBar, TB_BUTTONSTRUCTSIZE, sizeof(TBBUTTON), 0);

	SString fileNameForExtension = ExtensionFileName();

	//[mhb] 06/19/09 revised: to use only one iconlib from property user.toolbar.iconlib; no obvious reasons to use multiple iconlibs
	//SString sIconlib = props.GetNewExpand("user.toolbar.iconlib.", fileNameForExtension.c_str());
	SString sIconlib = props.GetExpanded("user.toolbar.iconlib");
	
	//[mhb] 06/19/09 : to reuse existing iconlib so as to make the editor faster
	static HICON icons[1000];//allow max 1000 icons
	static int icons_count=0;
	int reload_icons= (icons_count==0);
	
	
	HICON hIcon = NULL;
	HICON hIconBig = NULL;
	int iCount = 0;
	HDC hDesktopDC = ::GetDC( NULL );
	RECT rect = { 0, 0, 16, 16 };
	HBRUSH hBrashBack = ::GetSysColorBrush( COLOR_BTNFACE );
	
	//while ( (int)::ExtractIconEx( sIconlib.c_str(), iCount++, &hIconBig, &hIcon, 1 ) > 0 ) { //[mhb] 06/19/09 commented
	while ( 1 ) { //[mhb] 06/19/09  revised: (int) ... >0
		
		//[mhb] 06/19/09 added: allow to reuse saved icons which are saved in memory when loaded first time
		if (reload_icons) {
			if ((int)::ExtractIconEx( sIconlib.c_str(), iCount, &hIconBig, &hIcon, 1 ) <= 0) break;
			icons[iCount]=CopyIcon(hIcon);
			icons_count=++iCount;
		} else {
			if (iCount>=icons_count) break;
			hIcon=CopyIcon(icons[iCount]);
			iCount++;
		}
	
		if ( hIconBig != NULL )::DestroyIcon( hIconBig );
		if ( hIcon != NULL ) {
			HDC hDC = ::CreateCompatibleDC( hDesktopDC );
			HBITMAP hbm = ::CreateCompatibleBitmap( hDesktopDC, 16, 16 );
			::SelectObject( hDC, hbm );
			::FillRect( hDC, &rect, hBrashBack );
			::DrawIconEx( hDC, 0, 0, hIcon, 16, 16, 0, NULL, DI_NORMAL );
			::DeleteDC( hDC );
			::DestroyIcon( hIcon );
			TBADDBITMAP bitmap = { NULL, (UINT)hbm };
			::SendMessage( hwndToolBar, TB_ADDBITMAP, 1, (LPARAM)&bitmap );
		}
	}
	::DeleteDC( hDesktopDC );
	if ( iCount == 1 )
	{
		TBADDBITMAP addbmp = { hInstance, IDR_BUTTONS };
		::SendMessage( hwndToolBar, TB_ADDBITMAP, 31, (LPARAM)&addbmp );
	}

	TArray<BarButtonIn,BarButtonIn> barbuttons;
	SString userToolbar = props.GetNewExpand("user.toolbar.", fileNameForExtension.c_str());
	userToolbar.substitute('|', '\0');
	const char *userContextItem = userToolbar.c_str();
	const char *endDefinition = userContextItem + userToolbar.length();
	while (userContextItem < endDefinition) {
		const char *tips = userContextItem;
		userContextItem += strlen(userContextItem) + 1;
		const char *command = userContextItem;
		userContextItem += strlen(userContextItem) + 1;
		if (userContextItem < endDefinition) {
			if ( tips[0] != '#') {
				barbuttons.Add(
					BarButtonIn(strlen(userContextItem)?atoi(userContextItem):-1, 
					GetMenuCommandAsInt(command)));
				ToolBarTips[GetMenuCommandAsInt(command)]=tips;
				int id = atoi(command);
				if (id > IDM_TOOLS) {
					SString prefix = "command.checked." + SString(id - IDM_TOOLS) + ".";
					SString val = props.GetNewExpand(prefix.c_str(), fileNameForExtension.c_str());
					if (val != "")
						toolbarUsersPressableButtons.Add(id);
				}
			}
			userContextItem += strlen(userContextItem) + 1;
			
		}
	}

	if (!barbuttons.GetSize()) {
		ToolBarTips[IDM_NEW]			= "New";
		ToolBarTips[IDM_OPEN]			= "Open";
		ToolBarTips[IDM_SAVE]			= "Save";
		ToolBarTips[IDM_CLOSE]			= "Close";
		ToolBarTips[IDM_PRINT]			= "Print";
		ToolBarTips[IDM_CUT]			= "Cut";
		ToolBarTips[IDM_COPY]			= "Copy";
		ToolBarTips[IDM_PASTE]			= "Paste";
		ToolBarTips[IDM_CLEAR]			= "Delete";
		ToolBarTips[IDM_UNDO]			= "Undo";
		ToolBarTips[IDM_REDO]			= "Redo";
		ToolBarTips[IDM_FIND]			= "Find";
		ToolBarTips[IDM_REPLACE]		= "Replace";
		barbuttons.Add(BarButtonIn(-1, 0));
		barbuttons.Add(BarButtonIn(0, IDM_NEW));
		barbuttons.Add(BarButtonIn(1, IDM_OPEN));
		barbuttons.Add(BarButtonIn(2, IDM_SAVE));
		barbuttons.Add(BarButtonIn(12, IDM_CLOSE));
		barbuttons.Add(BarButtonIn(-1, 0));
		barbuttons.Add(BarButtonIn(3, IDM_PRINT));
		barbuttons.Add(BarButtonIn(-1, 0));
		barbuttons.Add(BarButtonIn(4, IDM_CUT));
		barbuttons.Add(BarButtonIn(5, IDM_COPY));
		barbuttons.Add(BarButtonIn(6, IDM_PASTE));
		barbuttons.Add(BarButtonIn(7, IDM_CLEAR));
		barbuttons.Add(BarButtonIn(-1, 0));
		barbuttons.Add(BarButtonIn(8, IDM_UNDO));
		barbuttons.Add(BarButtonIn(9, IDM_REDO));
		barbuttons.Add(BarButtonIn(-1, 0));
		barbuttons.Add(BarButtonIn(10, IDM_FIND));
		barbuttons.Add(BarButtonIn(11, IDM_REPLACE));
	}

	TBBUTTON *tbb = new TBBUTTON[barbuttons.GetSize()];
	for (int i = 0;i < barbuttons.GetSize();i++) {
		tbb[i].idCommand = barbuttons[i].cmd;
		tbb[i].iBitmap = barbuttons[i].id;
		tbb[i].fsState = TBSTATE_ENABLED;
		tbb[i].fsStyle = -1 == tbb[i].iBitmap ? TBSTYLE_SEP : TBSTYLE_BUTTON;
		tbb[i].dwData = 0;
		tbb[i].iString = 0;
	}
	::SendMessage( hwndToolBar, TB_ADDBUTTONS, barbuttons.GetSize(), reinterpret_cast<LPARAM>(tbb) );
	delete []tbb;

	wToolBar.Show();
	SizeSubWindows();
}
//!-end-[user.toolbar]

void SciTEWin::SetMenuItem(int menuNumber, int position, int itemID,
                           const char *text, const char *mnemonic) {
	// On Windows the menu items are modified if they already exist or are created
	HMENU hmenu = ::GetSubMenu(::GetMenu(MainHWND()), menuNumber);
	
	//[mhb] 06/14/09: to put user properties files in a submenu
	if ((menuNumber==menuOptions) && (position>=IMPORT_START)) {
		hmenu = ::GetSubMenu(hmenu, IMPORT_START);
	}
	
	SString sTextMnemonic = text;
	long keycode = 0;
	if (mnemonic && *mnemonic) {
		keycode = SciTEKeys::ParseKeyCode(mnemonic);
		if (keycode) {
			sTextMnemonic += "\t";
			sTextMnemonic += LocaliseAccelerator(mnemonic, itemID);
		}
		// the keycode could be used to make a custom accelerator table
		// but for now, the menu's item data is used instead for command
		// tools, and for other menu entries it is just discarded.
	}

	if (::GetMenuState(hmenu, itemID, MF_BYCOMMAND) == 0xffffffff) {
		if (text[0])
			::InsertMenu(hmenu, position, MF_BYPOSITION, itemID, sTextMnemonic.c_str());
		else
			::InsertMenu(hmenu, position, MF_BYPOSITION | MF_SEPARATOR, itemID, sTextMnemonic.c_str());
	} else {
		::ModifyMenu(hmenu, position, MF_BYCOMMAND, itemID, sTextMnemonic.c_str());
	}

	if (itemID >= IDM_TOOLS && itemID < IDM_TOOLS + toolMax) {
		// Stow the keycode for later retrieval.
		// Do this even if 0, in case the menu already existed (e.g. ModifyMenu)
		MENUITEMINFO mii;
		mii.cbSize = sizeof(MENUITEMINFO);
		mii.fMask = MIIM_DATA;
		mii.dwItemData = reinterpret_cast<DWORD&>(keycode);
		::SetMenuItemInfo(hmenu, itemID, FALSE, &mii);
	}
}

void SciTEWin::RedrawMenu() {
	// Make previous change visible.
	::DrawMenuBar(reinterpret_cast<HWND>(wSciTE.GetID()));
}

void SciTEWin::DestroyMenuItem(int menuNumber, int itemID) {
	// On Windows menu items are destroyed as they can not be hidden and they can be recreated in any position
	HMENU hmenuBar = ::GetMenu(MainHWND());
	if (itemID) {
		HMENU hmenu = ::GetSubMenu(hmenuBar, menuNumber);
		::DeleteMenu(hmenu, itemID, MF_BYCOMMAND);
	} else {
		::DeleteMenu(hmenuBar, menuNumber, MF_BYPOSITION);
	}
}

//!-start-[user.toolbar]
static void CheckToolbarButton(HWND wTools, int id, bool enable) {
	if (wTools) {
		::SendMessage(wTools, TB_CHECKBUTTON, id,
		          Platform::LongFromTwoShorts(static_cast<short>(enable ? TRUE : FALSE), 0));
	}
}
//!-end-[user.toolbar]

void SciTEWin::CheckAMenuItem(int wIDCheckItem, bool val) {
	if (val)
		CheckMenuItem(::GetMenu(MainHWND()), wIDCheckItem, MF_CHECKED | MF_BYCOMMAND);
	else
		CheckMenuItem(::GetMenu(MainHWND()), wIDCheckItem, MF_UNCHECKED | MF_BYCOMMAND);
	::CheckToolbarButton(reinterpret_cast<HWND>(wToolBar.GetID()), wIDCheckItem, val); //!-add-[user.toolbar]
}

void EnableButton(HWND wTools, int id, bool enable) {
	if (wTools) {
		::SendMessage(wTools, TB_ENABLEBUTTON, id,
	              Platform::LongFromTwoShorts(static_cast<short>(enable ? TRUE : FALSE), 0));
	}
}

void SciTEWin::EnableAMenuItem(int wIDCheckItem, bool val) {
	if (val)
		::EnableMenuItem(::GetMenu(MainHWND()), wIDCheckItem, MF_ENABLED | MF_BYCOMMAND);
	else
		::EnableMenuItem(::GetMenu(MainHWND()), wIDCheckItem, MF_DISABLED | MF_GRAYED | MF_BYCOMMAND);
	::EnableButton(reinterpret_cast<HWND>(wToolBar.GetID()), wIDCheckItem, val);
}

void SciTEWin::CheckMenus() {
//!-start-[user.toolbar]
	// check user toolbar buttons status
	if (props.GetInt("toolbar.visible") != 0) {
		SString fileNameForExtension = ExtensionFileName();
		for (int i = 0; i < toolbarUsersPressableButtons.GetSize(); i++) {
			SString prefix = "command.checked." + SString(toolbarUsersPressableButtons[i] - IDM_TOOLS) + ".";
			int ischecked = props.GetNewExpand(prefix.c_str(), fileNameForExtension.c_str()).value();
			::CheckToolbarButton(reinterpret_cast<HWND>(wToolBar.GetID()), toolbarUsersPressableButtons[i], ischecked);
		}
	}
//!-end-[user.toolbar]
	SciTEBase::CheckMenus();
	CheckMenuRadioItem(::GetMenu(MainHWND()), IDM_EOL_CRLF, IDM_EOL_LF,
	                   SendEditor(SCI_GETEOLMODE) - SC_EOL_CRLF + IDM_EOL_CRLF, 0);
	CheckMenuRadioItem(::GetMenu(MainHWND()), IDM_ENCODING_DEFAULT, IDM_ENCODING_UCOOKIE,
	                   CurrentBuffer()->unicodeMode + IDM_ENCODING_DEFAULT, 0);
}

void SciTEWin::MakeAccelerator(SString sAccelerator, ACCEL &Accel) {
	SString s = sAccelerator;

	if (s.contains("null")) {
		Accel.key = 0;
		return ;
	}

	if (s.contains("Ctrl+")) {
		Accel.fVirt |= FCONTROL;
		s.remove("Ctrl+");
	}
	if (s.contains("Shift+")) {
		Accel.fVirt |= FSHIFT;
		s.remove("Shift+");
	}
	if (s.contains("Alt+")) {
		Accel.fVirt |= FALT;
		s.remove("Alt+");
	}
	if (s.length() == 1) {
		Accel.key = s[0];
		Accel.fVirt |= FVIRTKEY;
	} else if ((s.length() > 1) && (s[0] == 'F') && (isdigit(s[1]))) {
		s.remove("F");
		int keyNum = s.value();
		Accel.key = static_cast<WORD>(keyNum + VK_F1 - 1);
		Accel.fVirt |= FVIRTKEY;
	} else if (s.contains("Del")) {
		Accel.key = VK_DELETE;
		Accel.fVirt |= FVIRTKEY;
	} else if (s.contains("Space")) {
		Accel.key = VK_SPACE;
		Accel.fVirt |= FVIRTKEY;
	} else if (s.contains("Enter")) {
		Accel.key = VK_RETURN;
		Accel.fVirt |= FVIRTKEY;
	} else if (s.contains("Back")) {
		Accel.key = VK_BACK;
		Accel.fVirt |= FVIRTKEY;
	} else if (s.contains("Tab")) {
		Accel.key = VK_TAB;
		Accel.fVirt |= FVIRTKEY;
	} else if (s.contains("Num")) {
		Accel.fVirt |= FVIRTKEY;
		s.remove("Num");
		if (isdigit(s[0])) {
			int keyNum = s.value();
			Accel.key = static_cast<WORD>(keyNum + VK_NUMPAD0);
		} else {
			switch (s[0]) {
			case '*':
				Accel.key = VK_MULTIPLY;
				break;
			case '+':
				Accel.key = VK_ADD;
				break;
			case '-':
				Accel.key = VK_SUBTRACT;
				break;
			case '/':
				Accel.key = VK_DIVIDE;
				break;
			default:
				Accel.key = 0;
				break;
			}
		}
	}
}

//SString SciTEWin::LocaliseAccelerator(const char *pAccelerator, int cmd) {
SString SciTEWin::LocaliseAccelerator(const char *pAccelerator, int) {
#ifdef LOCALISE_ACCELERATORS_WORKED
	SString translation = localiser.Text(pAccelerator, true);
	int AccelCount = ::CopyAcceleratorTable(hAccTable, NULL, 0);
	ACCEL *AccelTable = new ACCEL[AccelCount];
	::CopyAcceleratorTable(hAccTable, AccelTable, AccelCount);
	for (int i = 0; i < AccelCount; i++) {
		if (AccelTable[i].cmd == cmd) {
			MakeAccelerator(translation, AccelTable[i]);
		}
	}

	::DestroyAcceleratorTable(hAccTable);
	hAccTable = ::CreateAcceleratorTable(AccelTable, AccelCount);
	delete []AccelTable;

	if (translation.contains("null")) {
		translation.clear();
	}

	return translation;
#else
	return pAccelerator;
#endif
}

void SciTEWin::LocaliseMenu(HMENU hmenu) {
	for (int i = 0; i <= ::GetMenuItemCount(hmenu); i++) {
		char buff[200];
		buff[0] = '\0';
		MENUITEMINFO mii;
		memset(&mii, 0, sizeof(mii));
		// Explicitly use the struct size for NT 4 as otherwise
		// GetMenuItemInfo will fail on NT 4.
		//mii.cbSize = sizeof(mii);
		mii.cbSize = 44;
		mii.fMask = MIIM_CHECKMARKS | MIIM_DATA | MIIM_ID |
		            MIIM_STATE | MIIM_SUBMENU | MIIM_TYPE;
		mii.dwTypeData = buff;
		mii.cch = sizeof(buff) - 1;
		if (::GetMenuItemInfo(hmenu, i, TRUE, &mii)) {
			if (mii.hSubMenu) {
				LocaliseMenu(mii.hSubMenu);
			}
			if (mii.fType == MFT_STRING || mii.fType == MFT_RADIOCHECK) {
				if (mii.dwTypeData) {
					SString text(mii.dwTypeData);
					SString accel(mii.dwTypeData);
					size_t len = text.length();
					int tab = text.search("\t");
					if (tab != -1) {
						text.remove(tab, len - tab);
						accel.remove(0, tab + 1);
					} else {
						accel = "";
					}
					text = localiser.Text(text.c_str(), true);
					if (text.length()) {
						if (accel != "") {
							text += "\t";
							text += LocaliseAccelerator(accel.c_str(), mii.wID);
						}
						mii.dwTypeData = const_cast<char *>(text.c_str());
						::SetMenuItemInfo(hmenu, i, TRUE, &mii);
					}
				}
			}
		}
	}
}

void SciTEWin::LocaliseMenus() {
	LocaliseMenu(::GetMenu(MainHWND()));
	::DrawMenuBar(MainHWND());
}

void SciTEWin::LocaliseAccelerators() {
	LocaliseAccelerator("Alt+1", IDM_BUFFER + 0);
	LocaliseAccelerator("Alt+2", IDM_BUFFER + 1);
	LocaliseAccelerator("Alt+3", IDM_BUFFER + 2);
	LocaliseAccelerator("Alt+4", IDM_BUFFER + 3);
	LocaliseAccelerator("Alt+5", IDM_BUFFER + 4);
	LocaliseAccelerator("Alt+6", IDM_BUFFER + 5);
	LocaliseAccelerator("Alt+7", IDM_BUFFER + 6);
	LocaliseAccelerator("Alt+8", IDM_BUFFER + 7);
	LocaliseAccelerator("Alt+9", IDM_BUFFER + 8);
	LocaliseAccelerator("Alt+0", IDM_BUFFER + 9);

	// todo read keymap from cfg
	// AssignKey('Y', SCMOD_CTRL, SCI_LINECUT);
}

void SciTEWin::LocaliseControl(HWND w) {
	char wtext[200];
	if (::GetWindowText(w, wtext, sizeof(wtext))) {
		SString text = localiser.Text(wtext, false);
		if (text.length())
			::SetWindowText(w, text.c_str());
	}
}

void SciTEWin::LocaliseDialog(HWND wDialog) {
	LocaliseControl(wDialog);
	HWND wChild = ::GetWindow(wDialog, GW_CHILD);
	while (wChild) {
		LocaliseControl(wChild);
		wChild = ::GetWindow(wChild, GW_HWNDNEXT);
	}
}

// Mingw headers do not have this:
#ifndef TBSTYLE_FLAT
#define TBSTYLE_FLAT 0x0800
#endif
#ifndef TB_LOADIMAGES
#define TB_LOADIMAGES (WM_USER + 50)
#endif

/*!-change-[user.toolbar]
struct BarButton {
	int id;
	int cmd;
};

static BarButton bbs[] = {
    { -1,           0 },
    { STD_FILENEW,  IDM_NEW },
    { STD_FILEOPEN, IDM_OPEN },
    { STD_FILESAVE, IDM_SAVE },
    { 0,            IDM_CLOSE },
    { -1,           0 },
    { STD_PRINT,    IDM_PRINT },
    { -1,           0 },
    { STD_CUT,      IDM_CUT },
    { STD_COPY,     IDM_COPY },
    { STD_PASTE,    IDM_PASTE },
    { STD_DELETE,   IDM_CLEAR },
    { -1,           0 },
    { STD_UNDO,     IDM_UNDO },
    { STD_REDOW,    IDM_REDO },
    { -1,           0 },
    { STD_FIND,     IDM_FIND },
    { STD_REPLACE,  IDM_REPLACE },
};
*/

static WNDPROC stDefaultTabProc = NULL;
static LRESULT PASCAL TabWndProc(HWND hWnd, UINT iMessage, WPARAM wParam, LPARAM lParam) {

	static BOOL st_bDragBegin = FALSE;
	static int st_iDraggingTab = -1;
	static int st_iLastClickTab = -1;
	static HWND st_hwndLastFocus = NULL;

	switch (iMessage) {

	case WM_LBUTTONDOWN: {
			Point pt = Point::FromLong(lParam);
			TCHITTESTINFO thti;
			thti.pt.x = pt.x;
			thti.pt.y = pt.y;
			thti.flags = 0;
			st_iLastClickTab = ::SendMessage(hWnd, TCM_HITTEST, (WPARAM)0, (LPARAM) & thti);
		}
		break;
	}

	LRESULT retResult;
	if (stDefaultTabProc != NULL) {
		retResult = CallWindowProc(stDefaultTabProc, hWnd, iMessage, wParam, lParam);
	} else {
		retResult = ::DefWindowProc(hWnd, iMessage, wParam, lParam);
	}

	switch (iMessage) {

	case WM_LBUTTONDBLCLK:
	case WM_MBUTTONDOWN: {
			// Check if on tab bar
			Point pt = Point::FromLong(lParam);
			TCHITTESTINFO thti;
			thti.pt.x = pt.x;
			thti.pt.y = pt.y;
			thti.flags = 0;
			int tab = ::SendMessage(hWnd, TCM_HITTEST, (WPARAM)0, (LPARAM) & thti);
			if (tab >= 0) {
				::SendMessage(::GetParent(hWnd), WM_COMMAND, IDC_TABCLOSE, (LPARAM)tab);
			}
		}
		break;

	case WM_LBUTTONUP: {
			st_iLastClickTab = -1;
			if (st_bDragBegin == TRUE) {
				if (st_hwndLastFocus != NULL) ::SetFocus(st_hwndLastFocus);
				::ReleaseCapture();
				::SetCursor(::LoadCursor(NULL, IDC_ARROW));
				st_bDragBegin = FALSE;
				Point pt = Point::FromLong(lParam);
				TCHITTESTINFO thti;
				thti.pt.x = pt.x;
				thti.pt.y = pt.y;
				thti.flags = 0;
				int tab = ::SendMessage(hWnd, TCM_HITTEST, (WPARAM)0, (LPARAM) & thti);
				if (tab > -1 && st_iDraggingTab > -1 && st_iDraggingTab != tab) {
					::SendMessage(::GetParent(hWnd),
					        WM_COMMAND,
					        IDC_SHIFTTAB,
					        MAKELPARAM(st_iDraggingTab, tab));
				}
				st_iDraggingTab = -1;
			}
		}
		break;

	case WM_KEYDOWN: {
			if (wParam == VK_ESCAPE) {
				if (st_bDragBegin == TRUE) {
					if (st_hwndLastFocus != NULL) ::SetFocus(st_hwndLastFocus);
					::ReleaseCapture();
					::SetCursor(::LoadCursor(NULL, IDC_ARROW));
					st_bDragBegin = FALSE;
					st_iDraggingTab = -1;
					st_iLastClickTab = -1;
					::InvalidateRect(hWnd, NULL, FALSE);
				}
			}
		}
		break;

	case WM_MOUSEMOVE: {

			Point pt = Point::FromLong(lParam);
			TCHITTESTINFO thti;
			thti.pt.x = pt.x;
			thti.pt.y = pt.y;
			thti.flags = 0;
			int tab = ::SendMessage(hWnd, TCM_HITTEST, (WPARAM)0, (LPARAM) & thti);
			int tabcount = ::SendMessage(hWnd, TCM_GETITEMCOUNT, (WPARAM)0, (LPARAM)0);

			if (wParam == MK_LBUTTON &&
			        tabcount > 1 &&
			        tab > -1 &&
			        st_iLastClickTab == tab &&
			        st_bDragBegin == FALSE) {
				st_iDraggingTab = tab;
				::SetCapture(hWnd);
				st_hwndLastFocus = ::SetFocus(hWnd);
				st_bDragBegin = TRUE;
				HCURSOR hcursor = ::LoadCursor(::GetModuleHandle(NULL),
				        MAKEINTRESOURCE(IDC_DRAGDROP));
				if (hcursor) ::SetCursor(hcursor);
			} else {
				if (st_bDragBegin == TRUE) {
					if (tab > -1 && st_iDraggingTab > -1 /*&& st_iDraggingTab != tab*/) {
						HCURSOR hcursor = ::LoadCursor(::GetModuleHandle(NULL),
						        MAKEINTRESOURCE(IDC_DRAGDROP));
						if (hcursor) ::SetCursor(hcursor);
					} else {
						::SetCursor(::LoadCursor(NULL, IDC_NO));
					}
				}
			}
		}
		break;

	case WM_PAINT: {
			if (st_bDragBegin == TRUE && st_iDraggingTab != -1) {

				Point ptCursor;
				::GetCursorPos(reinterpret_cast<POINT*>(&ptCursor));
				Point ptClient = ptCursor;
				::ScreenToClient(hWnd, reinterpret_cast<POINT*>(&ptClient));
				TCHITTESTINFO thti;
				thti.pt.x = ptClient.x;
				thti.pt.y = ptClient.y;
				thti.flags = 0;
				int tab = ::SendMessage(hWnd, TCM_HITTEST, (WPARAM)0, (LPARAM) & thti);

				RECT tabrc;
				if (tab != -1 &&
				        tab != st_iDraggingTab &&
				        TabCtrl_GetItemRect(hWnd, tab, &tabrc)) {

					HDC hDC = ::GetDC(hWnd);
					Surface *surfaceWindow = Surface::Allocate();
					if (surfaceWindow) {
						surfaceWindow->Init(hDC, hWnd);

						int xLeft = tabrc.left + 8;
						int yLeft = tabrc.top + (tabrc.bottom - tabrc.top) / 2;
						Point ptsLeftArrow[] = {
							Point(xLeft, yLeft - 2),
							Point(xLeft - 2, yLeft - 2),
							Point(xLeft - 2, yLeft - 5),
							Point(xLeft - 7, yLeft),
							Point(xLeft - 2, yLeft + 5),
							Point(xLeft - 2, yLeft + 2),
							Point(xLeft, yLeft + 2)
						};

						int xRight = tabrc.right - 10;
						int yRight = tabrc.top + (tabrc.bottom - tabrc.top) / 2;
						Point ptsRightArrow[] = {
							Point(xRight, yRight - 2),
							Point(xRight + 2, yRight - 2),
							Point(xRight + 2, yRight - 5),
							Point(xRight + 7, yRight),
							Point(xRight + 2, yRight + 5),
							Point(xRight + 2, yRight + 2),
							Point(xRight, yRight + 2)
						};

						surfaceWindow->Polygon(tab < st_iDraggingTab ? ptsLeftArrow : ptsRightArrow,
						        7,
						        ColourAllocated(RGB(255, 0, 0)),
						        ColourAllocated(RGB(255, 0, 0)));
						surfaceWindow->Release();
						delete surfaceWindow;
					}
					::ReleaseDC(hWnd, hDC);
				}
			}
		}
		break;
	}

	return retResult;
}

/**
 * Create all the needed windows.
 */
void SciTEWin::Creation() {

	wContent = ::CreateWindowEx(
	               WS_EX_CLIENTEDGE,
	               classNameInternal,
	               "Source",
	               WS_CHILD | WS_CLIPCHILDREN | WS_CLIPSIBLINGS,
	               0, 0,
	               100, 100,
	               MainHWND(),
	               reinterpret_cast<HMENU>(2000),
	               hInstance,
	               reinterpret_cast<LPSTR>(this));
	wContent.Show();

	wEditor = ::CreateWindowEx(
	              0,
	              "Scintilla",
	              "Source",
	              WS_CHILD | WS_VSCROLL | WS_HSCROLL | WS_CLIPCHILDREN | WS_CLIPSIBLINGS,
	              0, 0,
	              100, 100,
	              reinterpret_cast<HWND>(wContent.GetID()),
	              reinterpret_cast<HMENU>(IDM_SRCWIN),
	              hInstance,
	              0);
	if (!wEditor.Created())
		exit(FALSE);
	fnEditor = reinterpret_cast<SciFnDirect>(::SendMessage(
	               reinterpret_cast<HWND>(wEditor.GetID()), SCI_GETDIRECTFUNCTION, 0, 0));
	ptrEditor = ::SendMessage(reinterpret_cast<HWND>(wEditor.GetID()),
	                          SCI_GETDIRECTPOINTER, 0, 0);
	if (!fnEditor || !ptrEditor)
		exit(FALSE);
	wEditor.Show();
	SendEditor(SCI_USEPOPUP, 0);
	WindowSetFocus(wEditor);

	wOutput = ::CreateWindowEx(
	              0,
	              "Scintilla",
	              "Run",
	              WS_CHILD | WS_VSCROLL | WS_HSCROLL | WS_CLIPCHILDREN | WS_CLIPSIBLINGS,
	              0, 0,
	              100, 100,
	              reinterpret_cast<HWND>(wContent.GetID()),
	              reinterpret_cast<HMENU>(IDM_RUNWIN),
	              hInstance,
	              0);
	if (!wOutput.Created())
		exit(FALSE);
	fnOutput = reinterpret_cast<SciFnDirect>(::SendMessage(
	               reinterpret_cast<HWND>(wOutput.GetID()), SCI_GETDIRECTFUNCTION, 0, 0));
	ptrOutput = ::SendMessage(reinterpret_cast<HWND>(wOutput.GetID()),
	                          SCI_GETDIRECTPOINTER, 0, 0);
	if (!fnOutput || !ptrOutput)
		exit(FALSE);
	wOutput.Show();
	// No selection margin on output window
	SendOutput(SCI_SETMARGINWIDTHN, 1, 0);
	//SendOutput(SCI_SETCARETPERIOD, 0);
	SendOutput(SCI_USEPOPUP, 0);
	::DragAcceptFiles(MainHWND(), true);

	HWND hwndToolBar = ::CreateWindowEx(
	               0,
	               TOOLBARCLASSNAME,
	               "",
	               WS_CHILD | WS_CLIPCHILDREN | WS_CLIPSIBLINGS |
	               TBSTYLE_FLAT | TBSTYLE_TOOLTIPS | CCS_NORESIZE,
	               0, 0,
	               100, heightTools,
	               MainHWND(),
	               reinterpret_cast<HMENU>(IDM_TOOLWIN),
	               hInstance,
	               0);
	wToolBar = hwndToolBar;

/*!-change-[user.toolbar]
	::SendMessage(hwndToolBar, TB_BUTTONSTRUCTSIZE, sizeof(TBBUTTON), 0);
	::SendMessage(hwndToolBar, TB_LOADIMAGES, IDB_STD_SMALL_COLOR,
	              reinterpret_cast<LPARAM>(HINST_COMMCTRL));

	TBADDBITMAP addbmp = { hInstance, IDR_CLOSEFILE };
	::SendMessage(hwndToolBar, TB_ADDBITMAP, 1, (LPARAM)&addbmp);

	TBBUTTON tbb[ELEMENTS(bbs)];
	for (unsigned int i = 0;i < ELEMENTS(bbs);i++) {
		if (bbs[i].cmd == IDM_CLOSE)
			tbb[i].iBitmap = STD_PRINT + 1;
		else
			tbb[i].iBitmap = bbs[i].id;
		tbb[i].idCommand = bbs[i].cmd;
		tbb[i].fsState = TBSTATE_ENABLED;
		if ( -1 == bbs[i].id)
			tbb[i].fsStyle = TBSTYLE_SEP;
		else
			tbb[i].fsStyle = TBSTYLE_BUTTON;
		tbb[i].dwData = 0;
		tbb[i].iString = 0;
	}

	::SendMessage(hwndToolBar, TB_ADDBUTTONS, ELEMENTS(bbs), reinterpret_cast<LPARAM>(tbb));
*/

	wToolBar.Show();

	INITCOMMONCONTROLSEX icce;
	icce.dwSize = sizeof(icce);
	icce.dwICC = ICC_TAB_CLASSES;
	InitCommonControlsEx(&icce);

	WNDCLASS wndClass = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
	GetClassInfo(NULL, WC_TABCONTROL, &wndClass);
	stDefaultTabProc = wndClass.lpfnWndProc;
	wndClass.lpfnWndProc = TabWndProc;
	wndClass.style = wndClass.style | CS_DBLCLKS;
	wndClass.lpszClassName = "SciTeTabCtrl";
	wndClass.hInstance = hInstance;
	if (RegisterClass(&wndClass) == 0)
		exit(FALSE);

	wTabBar = ::CreateWindowEx(
	              0,
	              "SciTeTabCtrl",
	              "Tab",
	              WS_CHILD | WS_CLIPCHILDREN | WS_CLIPSIBLINGS |
	              TCS_FOCUSNEVER | TCS_TOOLTIPS,
	              0, 0,
	              100, heightTab,
	              MainHWND(),
	              reinterpret_cast<HMENU>(IDM_TABWIN),
	              hInstance,
	              0 );

	if (!wTabBar.Created())
		exit(FALSE);

	LOGFONT lfIconTitle;
	ZeroMemory(&lfIconTitle, sizeof(lfIconTitle));
	::SystemParametersInfo(SPI_GETICONTITLELOGFONT,sizeof(lfIconTitle),&lfIconTitle,FALSE);
	fontTabs = ::CreateFontIndirect(&lfIconTitle);
	::SendMessage(reinterpret_cast<HWND>(wTabBar.GetID()),
	              WM_SETFONT,
	              reinterpret_cast<WPARAM>(fontTabs),      // handle to font
	              0);    // redraw option

	wTabBar.Show();

	wStatusBar = ::CreateWindowEx(
	                 0,
	                 STATUSCLASSNAME,
	                 "",
	                 WS_CHILD | WS_CLIPSIBLINGS,
	                 0, 0,
	                 100, heightStatus,
	                 MainHWND(),
	                 reinterpret_cast<HMENU>(IDM_STATUSWIN),
	                 hInstance,
	                 0);
	wStatusBar.Show();
	int widths[] = { 4000 };
	// Perhaps we can define a syntax to create more parts,
	// but it is probably an overkill for a marginal feature
	::SendMessage(reinterpret_cast<HWND>(wStatusBar.GetID()),
	              SB_SETPARTS, 1,
	              reinterpret_cast<LPARAM>(widths));

#ifndef NO_LUA
		if (props.GetExpanded("ext.lua.startup.script").length() == 0)
			DestroyMenuItem(menuOptions,IDM_OPENLUAEXTERNALFILE);
#else
		DestroyMenuItem(menuOptions,IDM_OPENLUAEXTERNALFILE);
#endif
}
