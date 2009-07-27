/*
 *  Copyright (c) 2006           Ji YongGang <jungle@soforge-studio.com>
 *
 *  ChmSee is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2, or (at your option)
 *  any later version.

 *  ChmSee is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with ChmSee; see the file COPYING.  If not, write to
 *  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 */

/***************************************************************************
 *   Copyright (C) 2003 by zhong                                           *
 *   zhongz@163.com                                                        *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 ***************************************************************************/

#ifndef __CHMSEE_H__
#define __CHMSEE_H__

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <glib-object.h>
#include <gtk/gtkwindow.h>
#include <gtk/gtk.h>

#include "models/ichmfile.h"

G_BEGIN_DECLS

typedef struct _ChmSee      ChmSee;
typedef struct _ChmSeePrivate ChmSeePrivate;
typedef struct _ChmSeeClass ChmSeeClass;

#define TYPE_CHMSEE \
        (chmsee_get_type ())
#define CHMSEE(o) \
        (G_TYPE_CHECK_INSTANCE_CAST ((o), TYPE_CHMSEE, ChmSee))
#define CHMSEE_CLASS(k) \
        (G_TYPE_CHECK_CLASS_CAST ((k), TYPE_CHMSEE, ChmSeeClass))
#define IS_CHMSEE(o) \
        (G_TYPE_CHECK_INSTANCE_TYPE ((o), TYPE_CHMSEE))
#define IS_CHMSEE_CLASS(k) \
        (G_TYPE_CHECK_CLASS_TYPE ((k), TYPE_CHMSEE))
#define CHMSEE_GET_CLASS(o) \
        (G_TYPE_INSTANCE_GET_CLASS ((o), TYPE_CHMSEE, ChmSeeClass))


struct _ChmSee {
        GtkWindow        parent;
        ChmSeePrivate*  priv;
};

struct _ChmSeeClass {
        GtkWindowClass   parent_class;
};

GType chmsee_get_type(void);
ChmSee * chmsee_new(const gchar* fname);
gboolean chmsee_jump_index_by_name(ChmSee* self, const gchar* name);
/* void chmsee_open_file(ChmSee *, const gchar *); */
int chmsee_get_hpaned_position(ChmSee* self);
void chmsee_set_hpaned_position(ChmSee* self, int hpaned_position);
const gchar* chmsee_get_cache_dir(ChmSee* self);

const gchar* chmsee_get_variable_font(ChmSee* self);
void chmsee_set_variable_font(ChmSee* self, const gchar* font_name);

const gchar* chmsee_get_fixed_font(ChmSee* self);
void chmsee_set_fixed_font(ChmSee* self, const gchar* font_name);

int chmsee_get_lang(ChmSee* self);
void chmsee_set_lang(ChmSee* self, int lang);

gboolean chmsee_has_book(ChmSee* self);

G_END_DECLS

#endif /* !__CHMSEE_H__ */
