//============================================================
//
//  droidfile.c - file access functions
//
//  Copyright (c) 1996-2007, Nicola Salmoria and the MAME Team.
//  Visit http://mamedev.org for licensing and usage restrictions.
//
//  MAME4DROID MAME4iOS by David Valdeita (Seleuco)
//
//============================================================
#ifdef ANDROID
#include <android/log.h>
#endif

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>

#define _XOPEN_SOURCE 500

#include <unistd.h>

// MAME headers
#include "osdepend.h"

#define PATHSEPCH '/'
#define INVPATHSEPCH '\\'


static UINT32 create_path_recursive(char *path);

#define NO_ERROR	(0)

//============================================================
//  TYPE DEFINITIONS
//============================================================

struct _osd_file
{
	int		handle;
	char 		filename[1];
};


//============================================================
//  error_to_file_error
//  (does filling this out on non-Windows make any sense?)
//============================================================

static file_error error_to_file_error(UINT32 error)
{
	switch (error)
	{
	case ENOENT:
		return FILERR_NOT_FOUND;

	case EACCES:
	case EROFS:
	case ETXTBSY:
	case EEXIST:
	case EPERM:
	case EISDIR:
	case EINVAL:
		return FILERR_ACCESS_DENIED;

	case ENFILE:
	case EMFILE:
		return FILERR_TOO_MANY_FILES;

	default:
		return FILERR_FAILURE;
	}
}


//============================================================
//  osd_open
//============================================================

file_error osd_open(const char *path, UINT32 openflags, osd_file **file, UINT64 *filesize)
{
	UINT32 access;
	const char *src;
	char *dst;
	struct stat st;

	char *tmpstr, *envstr;
	int i, j;
	file_error filerr = FILERR_NONE;

#ifdef ANDROID
	__android_log_print(ANDROID_LOG_INFO, "mame4", "Leo %s",path);
#endif

	tmpstr = NULL;

	// allocate a file object, plus space for the converted filename
	*file = (osd_file*)malloc(sizeof(**file) + sizeof(char) * strlen(path));
	if (*file == NULL)
	{
		filerr = FILERR_OUT_OF_MEMORY;
		goto error;
	}

	// convert the path into something compatible
	dst = (*file)->filename;
	for (src = path; *src != 0; src++)
		*dst++ = (*src == INVPATHSEPCH) ? PATHSEPCH : *src;
	*dst++ = 0;

	// select the file open modes
	if (openflags & OPEN_FLAG_WRITE)
	{
		access = (openflags & OPEN_FLAG_READ) ? O_RDWR : O_WRONLY;
		access |= (openflags & OPEN_FLAG_CREATE) ? (O_CREAT | O_TRUNC) : 0;
	}
	else if (openflags & OPEN_FLAG_READ)
	{
		access = O_RDONLY;
	}
	else
	{
		filerr = FILERR_INVALID_ACCESS;
		goto error;
	}
	
    //
    //access |= O_SYNC;
    //
    
	tmpstr = (char *)malloc(strlen((*file)->filename)+1);
	strcpy(tmpstr, (*file)->filename);

	// does path start with an environment variable?
	if (tmpstr[0] == '$')
	{
		char *envval;
		envstr = (char*)malloc(strlen(tmpstr)+1);

		strcpy(envstr, tmpstr);

		i = 0;
		while (envstr[i] != PATHSEPCH && envstr[i] != 0 && envstr[i] != '.')
		{
			i++;
		}

		envstr[i] = '\0';

		envval = getenv(&envstr[1]);
		if (envval)
		{
			j = strlen(envval) + strlen(tmpstr) + 1;
			free(tmpstr);
			tmpstr = (char*)malloc(j);
	
			// start with the value of $HOME
			strcpy(tmpstr, envval);
			// replace the null with a path separator again
			envstr[i] = PATHSEPCH;
			// append it
			strcat(tmpstr, &envstr[i]);
		}
		else
			fprintf(stderr, "Warning: Environment variable %s not found.\n", envstr);
		free(envstr);
	}

	// attempt to open the file
	(*file)->handle = open(tmpstr, access, 0666);

	if ((*file)->handle == -1)
	{
		// create the path if necessary
		if ((openflags & OPEN_FLAG_CREATE) && (openflags & OPEN_FLAG_CREATE_PATHS))
		{
			char *pathsep = strrchr(tmpstr, PATHSEPCH);
			if (pathsep != NULL)
			{
				int error;

				// create the path up to the file
				*pathsep = 0;
				error = create_path_recursive(tmpstr);
				*pathsep = PATHSEPCH;

				// attempt to reopen the file
				if (error == NO_ERROR)
				{
					(*file)->handle = open(tmpstr, access, 0666);
				}
			}
		}

		// if we still failed, clean up and free
		if ((*file)->handle == -1)
		{
			free(*file);
			*file = NULL;
			free(tmpstr);
			return error_to_file_error(errno);
		}
	}

	// get the file size
	fstat((*file)->handle, &st);

	*filesize = (UINT64)st.st_size;
#ifdef ANDROID
	__android_log_print(ANDROID_LOG_INFO, "mame4", "Leido %s %uld",path,(unsigned int)filesize);
#endif
error:
	// cleanup
	if (filerr != FILERR_NONE && *file != NULL)
	{
		free(*file);
		*file = NULL;
	}
	if (tmpstr)
		free(tmpstr);
	return filerr;
}


//============================================================
//  osd_read
//============================================================

file_error osd_read(osd_file *file, void *buffer, UINT64 offset, UINT32 length, UINT32 *actual)
{
#if defined(ANDROID) || defined(IOS) || 1
	UINT32 result;

	result = pread(file->handle, buffer, length, offset);
	if (!result)
		return error_to_file_error(errno);
	if (actual != NULL)
		*actual = result;
	return FILERR_NONE;
#else
	size_t count;

	// seek to the new location; note that most fseek implementations are limited to 32 bits
	fseek((FILE *)file, offset, SEEK_SET);

	// perform the read
	count = fread(buffer, 1, length, (FILE *)file);
	if (actual != NULL)
		*actual = count;

	return FILERR_NONE;
#endif
}


//============================================================
//  osd_write
//============================================================

file_error osd_write(osd_file *file, const void *buffer, UINT64 offset, UINT32 length, UINT32 *actual)
{
#if  defined(ANDROID) || defined(IOS) || 1
	UINT32 result;

	result = pwrite(file->handle, buffer, length, offset);
	if (!result)
		return error_to_file_error(errno);

	if (actual != NULL)
		*actual = result;
	return FILERR_NONE;
#else
	size_t count;

	// seek to the new location; note that most fseek implementations are limited to 32 bits
	fseek((FILE *)file, offset, SEEK_SET);

	// perform the write
	count = fwrite(buffer, 1, length, (FILE *)file);
	if (actual != NULL)
		*actual = count;

	return FILERR_NONE;
#endif
}


//============================================================
//  osd_close
//============================================================

file_error osd_close(osd_file *file)
{
	// close the file handle and free the file structure
	close(file->handle);
	free(file);
	return FILERR_NONE;
}

//============================================================
//  osd_rmfile
//============================================================

file_error osd_rmfile(const char *filename)
{
	if (unlink(filename) == -1)
	{
		return error_to_file_error(errno);                                                
	}

	return FILERR_NONE;
}

//============================================================
//  create_path_recursive
//============================================================

static UINT32 create_path_recursive(char *path)
{
	char *sep = strrchr(path, PATHSEPCH);
	UINT32 filerr;
	struct stat st;

	// if there's still a separator, and it's not the root, nuke it and recurse
	if (sep != NULL && sep > path && sep[0] != ':' && sep[-1] != PATHSEPCH)
	{
		*sep = 0;
		filerr = create_path_recursive(path);
		*sep = PATHSEPCH;
		if (filerr != NO_ERROR)
			return filerr;
	}

	// if the path already exists, we're done
	if (!stat(path, &st))
		return NO_ERROR;

	if (mkdir(path, 0777) != 0)
		return error_to_file_error(errno);
	return NO_ERROR;
}

//============================================================
//  osd_get_physical_drive_geometry
//============================================================

int osd_get_physical_drive_geometry(const char *filename, UINT32 *cylinders, UINT32 *heads, UINT32 *sectors, UINT32 *bps)
{
	return FALSE;		// no, no way, huh-uh, forget it
}

/*============================================================ */
/*      osd_is_path_separator */
/*============================================================ */
/*
static int osd_is_path_separator(char c)
{
        return (c == '/') || (c == '\\');
}
*/
/*============================================================ */
/*      osd_is_absolute_path */
/*============================================================ */
int osd_is_absolute_path(const char *path)
{
    int result;

    if ((path[0] == '/') || (path[0] == '\\'))
            result = TRUE;
    else if (path[0] == '.')
            result = TRUE;
    else
            result = FALSE;
    return result;
}       


// these are MESS specific - DO NOT TOUCH!!@!

//============================================================
//	osd_copyfile
//============================================================
/*
file_error osd_copyfile(const char *destfile, const char *srcfile)
{
	char command[1024];

	sprintf(command, "cp %s %s\n", srcfile, destfile);
	system(command);

	return FILERR_NONE;
}
*/
//============================================================
//  osd_stat
//============================================================

osd_directory_entry *osd_stat(const char *path)
{
	osd_directory_entry *result = NULL;
	struct stat st;
	stat(path, &st);

	// create an osd_directory_entry; be sure to make sure that the caller can
	// free all resources by just freeing the resulting osd_directory_entry
	result = (osd_directory_entry *) malloc(sizeof(*result) + strlen(path) + 1);
	strcpy(((char *) result) + sizeof(*result), path);
	result->name = ((char *) result) + sizeof(*result);
	result->type = S_ISDIR(st.st_mode) ? ENTTYPE_DIR : ENTTYPE_FILE;
	result->size = (UINT64)st.st_size;

	return result;
}


//============================================================
//  osd_get_full_path
//============================================================

file_error osd_get_full_path(char **dst, const char *path)
{
	file_error err;
	char path_buffer[512];

	err = FILERR_NONE;

	if (getcwd(path_buffer, 511) == NULL)
	{
		printf("osd_get_full_path: failed!\n");
		err = FILERR_FAILURE;
	}
	else
	{
		*dst = (char *)osd_malloc(strlen(path_buffer)+strlen(path)+3);

		// if it's already a full path, just pass it through
		if (path[0] == '/')
		{
			strcpy(*dst, path);
		}
		else
		{
			sprintf(*dst, "%s%s%s", path_buffer, PATH_SEPARATOR, path);
		}
	}

	return err;
}

//============================================================
//  osd_get_clipboard_text
//============================================================

char *osd_get_clipboard_text(void)
{
	char *result = NULL;

	return result;
}

//============================================================
//  osd_get_volume_name
//============================================================

const char *osd_get_volume_name(int idx)
{
	if (idx!=0) return NULL;
	return "/";
}
