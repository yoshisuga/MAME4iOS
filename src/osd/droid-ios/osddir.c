//============================================================
//
//  droiddir.c - core directory access functions
//
//  Copyright (c) 1996-2007, Nicola Salmoria and the MAME Team.
//  Visit http://mamedev.org for licensing and usage restrictions.
//
//  MAME4DROID MAME4iOS by David Valdeita (Seleuco)
//
//============================================================

#include "osdcore.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>

#include "osdcore.h"

struct _osd_directory
{
	osd_directory_entry ent;

	struct dirent *data;

	DIR *fd;
};


static osd_dir_entry_type get_attributes_stat(const char *file)
{
	struct stat st;
	if(stat(file, &st))
		return(osd_dir_entry_type)0;

	if (S_ISDIR(st.st_mode)) return ENTTYPE_DIR;

	return ENTTYPE_FILE;
}


static UINT64 osd_get_file_size(const char *file)
{

	struct stat st;
	if(stat(file, &st))
		return 0;

	return st.st_size;
}

//============================================================
//  osd_opendir
//============================================================

osd_directory *osd_opendir(const char *dirname)
{
	osd_directory *dir = NULL;

	dir = (osd_directory *) malloc(sizeof(osd_directory));
	if (dir)
	{
		memset(dir, 0, sizeof(osd_directory));
		dir->fd = NULL;
	}

	dir->fd = opendir(dirname);

	if (dir && (dir->fd == NULL))
	{
		free(dir);
		dir = NULL;
	}

	return dir;
}


//============================================================
//  osd_readdir
//============================================================

const osd_directory_entry *osd_readdir(osd_directory *dir)
{

	dir->data = readdir(dir->fd);

	if (dir->data == NULL)
		return NULL;

	dir->ent.name = dir->data->d_name;
	dir->ent.type = get_attributes_stat(dir->data->d_name);
	dir->ent.size = osd_get_file_size(dir->data->d_name);
	return &dir->ent;
}


//============================================================
//  osd_closedir
//============================================================

void osd_closedir(osd_directory *dir)
{
	if (dir->fd != NULL)
		closedir(dir->fd);
	free(dir);
}
