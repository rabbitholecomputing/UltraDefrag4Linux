/*
 *  UltraDefrag - a powerful defragmentation tool for Windows NT.
 *  Copyright (c) 2007-2011 by Dmitri Arkhangelski (dmitriar@gmail.com).
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef _UDEFRAG_GUI_MAIN_H_
#define _UDEFRAG_GUI_MAIN_H_

/*
* We use STATUS_WAIT_0...
* #define WIN32_NO_STATUS
*/

#include <windows.h>
/*
* Next definition is very important for mingw:
* _WIN32_IE must be no less than 0x0400
* to include some important constant definitions.
*/
#ifndef _WIN32_IE
#define _WIN32_IE 0x0400
#endif
#include <commctrl.h>
#include <shellapi.h>
#include <commdlg.h>

#ifndef SHTDN_REASON_MAJOR_OTHER
#define SHTDN_REASON_MAJOR_OTHER   0x00000000
#endif
#ifndef SHTDN_REASON_MINOR_OTHER
#define SHTDN_REASON_MINOR_OTHER   0x00000000
#endif
#ifndef SHTDN_REASON_FLAG_PLANNED
#define SHTDN_REASON_FLAG_PLANNED  0x80000000
#endif
#ifndef EWX_FORCEIFHUNG
#define EWX_FORCEIFHUNG     0x00000010
#endif

#ifndef KEY_WOW64_32KEY
#define KEY_WOW64_32KEY    (0x0200)
#endif

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <math.h>
#include <ctype.h>
#include <wchar.h>
#include <process.h>
#include <io.h>
#include <direct.h>
#include <errno.h>

#include "prb.h"

#define lua_c
#include "../lua5.1/lua.h"
#include "../lua5.1/lauxlib.h"
#include "../lua5.1/lualib.h"

#include "../dll/wgx/wgx.h"
#include "../dll/udefrag/udefrag.h"
#include "../include/ultradfgver.h"

#include "resource.h"

/* default GUI preferences */
#define DEFAULT_MAP_BLOCK_SIZE  4
#define DEFAULT_GRID_LINE_WIDTH 1

/* Main window layout constants (in pixels for 96 DPI). */
#define DEFAULT_WIDTH         658 /* default window width */
#define DEFAULT_HEIGHT        513 /* default window height */
#define MIN_WIDTH             500 /* minimal window width */
#define MIN_HEIGHT            400 /* minimal window height */
#define SPACING               7   /* spacing between controls */
#define PADDING_X             14  /* horizontal padding between borders and controls */
#define PADDING_Y             14  /* vertical padding between top border and controls */
#define VLIST_HEIGHT          130 /* volume list height */
#define MIN_LIST_HEIGHT       40  /* minimal list height */

/*
* An article of Mumtaz Zaheer from Pakistan helped us very much
* to make a valid subclassing:
* http://www.codeproject.com/KB/winsdk/safesubclassing.aspx
*/

/*
* The 'Flicker Free Drawing' article of James Brown
* helped us to reduce GUI flicker on window resize:
* http://www.catch22.net/tuts/flicker
*/

/*
* Due to some reason GetClientRect returns
* improper coordinates, therefore we're
* calculating width as right - left instead of
* right - left + 1, which would be more correct.
*/

typedef struct _udefrag_map {
    HBITMAP hbitmap;      /* bitmap used to draw map on */
    HDC hdc;              /* device context of the bitmap */
    int width;            /* width of the map, in pixels */
    int height;           /* height of the map, in pixels */
    char *buffer;         /* internal map representation */
    int size;             /* size of internal representation, in bytes */
    char *scaled_buffer;  /* scaled map representation */
    int scaled_size;      /* size of scaled representation, in bytes */
} udefrag_map;

typedef struct _volume_processing_job {
    char volume_letter;
    udefrag_job_type job_type;
    int termination_flag;
    udefrag_progress_info pi;
    udefrag_map map;
} volume_processing_job;

/* a type of the job being never executed */
#define NEVER_EXECUTED_JOB 0x100

/* prototypes */
int init_jobs(void);
volume_processing_job *get_job(char volume_letter);
int get_job_index(volume_processing_job *job);
void update_status_of_all_jobs(void);
void start_selected_jobs(udefrag_job_type job_type);
void stop_all_jobs(void);
void release_jobs(void);

int CreateMainMenu(void);
int CreateToolbar(void);
void UpdateToolbarTooltips(void);

int Init_I18N_Events(void);
void ApplyLanguagePack(void);
void BuildLanguageMenu(void);
void Destroy_I18N_Events(void);

/*void InitProgress(void);
void ShowProgress(void);
void HideProgress(void);
void SetProgress(wchar_t *message, int percentage);
*/
void AboutBox(void);
void ShowReports(void);

void InitFont(void);

void InitVolList(void);
void VolListNotifyHandler(LPARAM lParam);
void VolListGetColumnWidths(void);
void UpdateVolList(void);
void VolListUpdateStatusField(volume_processing_job *job);
void VolListRefreshItem(volume_processing_job *job);
void ReleaseVolList(void);
void SelectAllDrives(void);

void InitMap(void);
void RedrawMap(volume_processing_job *job, int map_refill_required);
void ReleaseMap(void);

void CreateStatusBar(void);
void UpdateStatusBar(udefrag_progress_info *pi);

void ResizeMap(int x, int y, int width, int height);
int  ResizeVolList(int x, int y, int width, int height, int expand);
int  GetMinVolListHeight(void);
int  GetMaxVolListHeight(void);
int  ResizeStatusBar(int bottom, int width);

void GetPrefs(void);
void SavePrefs(void);
void DeleteEnvironmentVariables(void);
int IsBootTimeDefragEnabled(void);

void CheckForTheNewVersion(void);

void StartPrefsChangesTracking();
void StopPrefsChangesTracking();
void StartBootExecChangesTracking();
void StopBootExecChangesTracking();
void StartLangIniChangesTracking();
void StopLangIniChangesTracking();
void StartI18nFolderChangesTracking();
void StopI18nFolderChangesTracking();

int ShutdownOrHibernate(void);

void OpenWebPage(char *page);

/* common global variables */
extern HINSTANCE hInstance;
extern HWND hWindow;
extern HWND hList;
extern HWND hMap;
extern HWND hStatus;
extern HMENU hMainMenu;
extern HWND hToolbar;
extern double pix_per_dialog_unit;
extern WGX_FONT wgxFont;
extern WGX_I18N_RESOURCE_ENTRY i18n_table[];
extern volume_processing_job *current_job;
extern HANDLE hMapEvent;
extern int busy_flag;
extern int when_done_action;
extern int shutdown_requested;
extern int exit_pressed;
extern int boot_time_defrag_enabled;
extern HANDLE hLangPackEvent;
extern HANDLE hLangMenuEvent;
extern int use_custom_font_in_dialogs;
extern int portable_mode;
extern int btd_installed;

extern int stop_pressed;

/* common preferences */
extern int seconds_for_shutdown_rejection;
extern int scale_by_dpi;
extern int restore_default_window_size;
extern int maximized_window;
extern int init_maximized_window;
extern int skip_removable;
extern int disable_latest_version_check;
extern int user_defined_column_widths[];
extern int list_height;
extern int dry_run;
extern int job_flags;
extern int repeat_action;

/*
* Note:
* 
* + You should not wait for one SendMessage handler completion
*   from another SendMessage handler. Because it will be a deadlock cause.
*
* + Example:
*
* int done;
*
* window_proc()
* {
*   if(stop button was pressed)
*   {
*     stop_the_driver();
*     wait for done flag;
*   }
* }
*
* analyse_thread_proc()
* {
*   done = 0;
*   analyse();
*   RedrawMap();
*   done = 1;
* }
*
* + How it works:
* 
* RedrawMap() will send message to the map control 
* that can not be handled by system before window_proc() returns.
* But window_proc() is waiting for done flag, that can be set
* after(!) RedrawMap() call. Therefore we have a deadlock.
*/

#define create_thread(func,param,ph) \
        CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)func,(void *)param,0,ph)

#define UNDEFINED_COORD (-10000)

/* This macro converts pixels from 96 DPI to the current one. */
#define PIX_PER_DIALOG_UNIT_96DPI 1.74
#define DPI(x) ((int)((double)x * pix_per_dialog_unit / PIX_PER_DIALOG_UNIT_96DPI))

#endif /* _UDEFRAG_GUI_MAIN_H_ */
