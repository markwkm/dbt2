/*
 * This file is released under the terms of the Artistic License.
 * Please see the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 */

#include <string.h>

#include <nonsp_common.h>

/* Copy a fetched value into a fixed size output field, tolerating NULL. */
void dbt2_copy_value(char *dest, char *src, size_t n) {
	if (src == NULL || n == 0) {
		return;
	}
	strncpy(dest, src, n - 1);
	dest[n - 1] = '\0';
}

void dbt2_escape_str(char *orig_str, char *esc_str) {
	int i, j;

	if (orig_str && esc_str) {
		int len = strlen(orig_str);
		for (i = 0, j = 0; i < len; i++) {
			if (orig_str[i] == '\'') {
				esc_str[j++] = '\'';
#ifndef HAVE_SQLITE3
			} else if (orig_str[i] == '\\') {
				esc_str[j++] = '\\';
			} else if (orig_str[i] == ')') {
				esc_str[j++] = '\\';
#endif
			}
			esc_str[j++] = orig_str[i];
		}
		esc_str[j] = '\0';
	}
}

int dbt2_init_values(char **values, int max_values) {
	int i;

	for (i = 0; i < max_values; i++) {
		values[i] = NULL;
	}
	return 1;
}

int dbt2_free_values(char **values, int max_values) {
	int i;

	for (i = 0; i < max_values; i++) {
		if (values[i]) {
			free(values[i]);
			values[i] = NULL;
		}
	}
	return 1;
}
