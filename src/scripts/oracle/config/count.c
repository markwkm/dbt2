/*##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################*/

#include <stdio.h>
#include <stdlib.h>

int main(int argc,char *argv[]) {
char c[20];  
FILE *fp;
double val=0,sum=0,count=0;  

  fp = fopen(argv[1], "r"); 

  if(fp==NULL) {
    printf("can't open file.\n");
    return 1;
  }
    while(fgets(c, 20, fp)!=NULL) { 
     val=atof(c);
	sum+=val;	
     count++;		
    }
   
    printf(" %.8f\n",sum/count>0?sum/count:0);
    fclose(fp);
    return 0;
}
