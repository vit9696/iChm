/*
 *  StringUtil.c
 *  quickchm
 *
 *  Created by Qian Qian on 6/29/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifdef CHM_BUILD_WITH_CHMOX

#include "StringUtil.h"


char *concateString(const char *s1, const char *s2) {
	unsigned int len = strlen(s1) + strlen(s2) + 1;
    char *s = calloc(len, sizeof(char));
	strncpy((char *)s, (char *)s1, len);
	strncat((char *)s, (char *)s2, len);
	return s;
}

#endif
