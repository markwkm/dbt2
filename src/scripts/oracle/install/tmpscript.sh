#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

find_replace_strings ()
{
   declare l_find=${1}
   declare l_replace=${2}
   declare l_filename=${3}

   if [ -z "${l_find}"  -o -z "${l_replace}" -o  -z "${l_filename}" ]
   then
      echo " parameters not enough.. "
      return 1
   fi

   perl -p -i -e "s%${l_find}%${l_replace}%g" ${l_filename}

   return 0
}

