// Headers
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdbool.h>

// Macros.
#define ERASE "commander-cli device masserase -s "
#define FLASH "commander-cli flash -s "
#define PRE   "bt_"
#define POST  ".s37"
#define DASH  "-"    
#define BUFF_COMPARE "xG24 Dev"
#define PATH " /Users/jenkins/Downloads/hw_fw/"
// Macro for Flashing
#define FLASH_FLAG
#define BOOT  "bootloader-apploader-"
//#define DEBUG
#define DEBUG_PRINT(...) printf("DEBUG: " __VA_ARGS__)
typedef int status_t;
// No error
#define STATUS_OK    ((status_t)0x0000)
// Generic error
#define STATUS_NOK    ((status_t)0x0001)


// Function Declarations
int   read_data(char* , int , int);
int   check_serial_num(int );
int   open_file(char *);
void  get_device_data(char*);
void  get_fw_data_from_config(int , char * ,char *);
void  to_upper(char *);
void  add_node_data(char *, char *, char *, char *);
void  print_data();
void  flash_binaries(char * , char * , char * );
void  report(char *);
char* my_strncat(char* , const char* , size_t);
void  filter(char * );
void  app_log(char *, char * , int , const char* );
void freeLinkedList(void);

// Structure for board details
typedef struct board
{
    char sr_num[10];
    char brd_name[9];
    char fw_name[30];
    char data_buff[1500];
    struct board *link;
}brd;

brd *head=NULL;

/*
Global Variables.
sr_cnt : count of serial device.
sr_buff : sr_buff is the 2d array where serial number  will store 
flag : this flag is used for the reading data from the @read_data() check this function 
*/
int sr_cnt=0;
char cmd_str[60]="commander-cli adapter probe --serialno ";
char cmd_str2[20]=" > board_info.txt";
int flag=0;
char sr_buff[10][10];


int main()
{
    int fp;
    status_t sc;
    // silink -list command lists all the connected serial device
    system("silink -list >serial_devices.txt");
    memset(sr_buff,0,sizeof(sr_buff));
    fp = open_file("serial_devices.txt");
    
    check_serial_num(fp);
    app_log("Serial number checked",__FILE__,__LINE__,__func__);

    if(close(fp)<0)
    {
        perror("fp");
        exit(1);
    }
    else
    {
        head=NULL;  
        app_log("Close Successfully",__FILE__,__LINE__,__func__);
    }
    freeLinkedList();
}
/*
@brief
* Reads data based on flag
* where flag 0 for normal read  and 1 for specific bytes read.
* @param : Character buffer
* @param : file pointer
* @param : flag 1/0
*/
int  read_data(char* buff, int fp,int flag)
{

    int i=0,cnt=0;
    char c;

    switch(flag)
    {
        case 0:
         while(read(fp,&c,1))
        {
            buff[i++]=c;
        }
        buff[i]='\0';
        break;

        case 1:
        read(fp,buff,8);
        buff[8]='\0';
        break;

        case 2:
        while (read(fp,&c,1))
        {
            if(c == ':')
                ++cnt;

            if(cnt == 15)
                break;
        }
        lseek(fp,1,SEEK_CUR);
        read(fp,buff,8);
        buff[8]='\0';
        break;

        case 3:
        while (read(fp,&c,1))
        {
            if(c == ':')
                ++cnt;

            if(cnt == 25)
                break;
        }
        lseek(fp,1,SEEK_CUR);
        read(fp,buff,8);
        buff[8]='\0';
        break;
    }
    
}

/*
* @brief : extract the serial number from the file serial_devices.txt file.
* @param : file pointer
*/
int check_serial_num(int fp )
{
    char c, flag_sr = 0;
    int i=0,j=0,cnt = 0, s = 0,u_cnt=0;
    // separating the serial number 
    while(read(fp,&c,1))
    {
            if(c == ':')
            {
               int mk = lseek(fp,0,SEEK_CUR);
               flag_sr = 1;
            }
            if(flag_sr == 1)
            {
                if(c >=48 && c <=57){
                    //storing the byte into 2d aray
                    sr_buff[j][i++]=c;
                    ++cnt;
                    u_cnt++;
                }
            }
            sr_buff[j][i]='\0';
            
            //when it reaches 9 make flag again 0 and cnt 0.
            if(cnt == 9)
            {
                ++j;
                i = 0;
                flag_sr = 0;
                cnt = 0;
            }
    }
    sr_cnt = u_cnt/9;
    printf("There are %d devices\n",sr_cnt);
    for (int a = 0; a!=sr_cnt ;a++){
        printf("%s\n",sr_buff[a]);
    //get full device data based on serial number.
    get_device_data(sr_buff[a]);
    }
    if(sr_cnt != 0)
        print_data();
    else
        printf("\n---------> Please Connect Hardwares. <----------\n");
    
}

int open_file(char *path)
{
//  opening the file.txt
    int fp1;
    fp1 = open(path, O_RDWR);
    if(fp1==-1)
    {
        printf("Error while opening function is %s\n",__func__);
    }
    else
    {
      //printf("File open successfully %d \n",fp1);
    }
    return fp1;
}

/* 
* @brief : execute the system command to fetch the boadr detail based on serial number and copy board_info.txt.
* comand is commander adapter probe --serialno.
* @param : serial number
*/

void get_device_data(char  *sr_buff)
{
    char brd_name[8],run_cmd[120],fw_name[30],brd_type[9];
    char board_detail_buff[2000];
    strcpy(run_cmd,cmd_str);
    my_strncat(run_cmd,sr_buff,10);
    my_strncat(run_cmd,cmd_str2,20);
    system(run_cmd);
    int fp =open_file("board_info.txt");
        
    // Getting full Board info
    read_data(board_detail_buff,fp,0);
    lseek(fp,76,SEEK_SET);
    read(fp,brd_type,8);
    brd_type[8]='\0';
    lseek(fp,0,SEEK_SET);
    if((strcmp(brd_type,"xG24 Dev")==0) || strcmp(brd_type,"Thunderb")==0)
        read_data(brd_name,fp,2);
    else
        read_data(brd_name,fp,3);
   
    // flag=1;
    // Whatever Board name  eg. BRD4187C
    // open the config file
    fp=open_file("config.txt");
    // getting fw_info
    get_fw_data_from_config(fp,brd_name,fw_name);
    // passing serail num, board name , firmware name and board detail.
    add_node_data(sr_buff,brd_name,fw_name,board_detail_buff);
    if(sr_cnt != 0)
        flash_binaries(sr_buff,brd_name,fw_name);
    memset(run_cmd,0,sizeof(run_cmd));
    close(fp);

}
/*
 * @brief : fetch the board number and firmware name from the config.txt and checking it in link list.
 */
void get_fw_data_from_config(int fp,char * buff, char * fw_name)
{
    brd *temp=head;
    int whence=0,whnc;
    whnc=lseek(fp,0,SEEK_END);
    char result[8];

    memset(fw_name,0,sizeof(fw_name));
   l1: while(whence!=whnc)
    {
        int i=0;
        char c;
        lseek(fp,whence++,SEEK_SET);    
        read(fp,result,8);
        result[8]='\0';
        // converting lower case to upper  case becasue the data is in lower case
        to_upper(result);
        //int n=strcmp(result,buff);
        if(strcmp(result,buff)==0)
        {
                whence=whence+10;
                lseek(fp,whence,SEEK_SET);
                while(c!='\n')
                {
                    read(fp,&c,1);
                    fw_name[i++]=c;
                }
                fw_name[--i]='\0';
                c='\0';
                if(head==NULL)
                {
                    break;
                }
                else
                {
                    while(temp)
                    {
                        int k=strcmp(temp->fw_name,fw_name);
                        if(k==0)
                        {
                            whence++;
                            goto l1;
                        }
                        temp=temp->link;
                    }
                    break;
                }
            }
    }
    close(fp);
}

// function for converting lower case to upper case.
void to_upper(char *buff)
{
    
    for (int i = 0; buff[i]; ++i)
    {
        if(buff[i]>=97 && buff[i]<=122)
            buff[i]=buff[i]-32;
        
    }
}
// own strncat.

char* my_strncat(char* destination, const char* source, size_t num)
{
    // make ptr point to the end of the destination string
    char* ptr = destination + strlen(destination);
 
    // Appends characters of the source to the destination string
    while (*source != '\0' && num--) {
        *ptr++ = *source++;
    }
 
    // null terminate destination string
    *ptr = '\0';
 
    // destination string is returned by standard `strncat()`
    return destination;
}

// converting Upper case to Lower case.
void to_lower(char *buff)
{
    for (int i = 0; buff[i]; ++i)
    {
        if(buff[i]>=64 && buff[i]<=90)
            buff[i]=buff[i]+32;
    }
}

// filter fun.
void filter(char * fw_name)
{
    char buffer[30];
    int i=0;
    while(fw_name[i])
    {
    
            buffer[i++] =  fw_name[i];
    }
    buffer[--i] ='\0';
    strcpy(fw_name,buffer);
}
           
// adding serail num, board name , firmware name and board detail to link list.
void add_node_data(char *sr_num, char *brd_name, char *fw_name, char *bufff)
{
    brd *newnode=NULL, *temp=head;
    newnode=calloc(1,sizeof(brd));
    /* assigning data into the structure*/
    strcpy(newnode->sr_num,sr_num);
    strcpy(newnode->brd_name,brd_name);
    strcpy(newnode->fw_name,fw_name);
    strcpy(newnode->data_buff,bufff);
    if(temp==NULL)
    {
        head=newnode;
    }
    else
    {
        while(temp->link!=NULL)
        {
            temp=temp->link;
        }
        temp->link=newnode;
    }
}
           
// printing link list data.
void print_data()
{
    brd *temp=head;

    if(head==NULL)
    {
        printf("THere is no node\n");
        exit(0);
    }
    else
    {
        while(temp)
        {
            printf(" The serial number is %s and board name is %s and firmwre name is %s \n",temp->sr_num,temp->brd_name,temp->fw_name );
            temp=temp->link;
        }
        printf("\n");
    }
}


// flash the firmware anf bootloader based on the congfig file data.

void flash_binaries(char * sr_num, char *brd_name , char * fw_name)
{
    char ch_flash[200],fw_name1[15];
    char buff[50];
    if(strlen(fw_name)==0)
    {
        report(brd_name);
        goto LAST;
    }
   
    // convert board name to lower case bacause board name is in upper case.
    to_lower(brd_name);

    // for erasing the chip
    memset(ch_flash,0,sizeof(ch_flash));
    strcat(ch_flash,ERASE);
    strncat(ch_flash,sr_num,9);

    /* system(clear */
    #ifdef FLASH_FLAG
    system(ch_flash);  
    #endif
    
    
    memset(ch_flash,0,sizeof(ch_flash));

    // flashing the bootloader
    strcat(ch_flash,FLASH);
    strncat(ch_flash,sr_num,9);
    strcat(ch_flash,PATH);
    strcat(ch_flash,BOOT);
    strcat(ch_flash,brd_name);
    strcat(ch_flash,POST);
    printf("%s\n",ch_flash);
    #ifdef FLASH_FLAG
    system(ch_flash);
    #endif
        
    memset(ch_flash,0,sizeof(ch_flash));

    // flashing the firmware.
    filter(fw_name);
    if(((strcmp(fw_name,"soc_blinky") && strcmp(fw_name,"soc_motion") && strcmp(fw_name,"soc_env"))==0) && strcmp(brd_name,"brd4184b")==0)
    {
         strcat(ch_flash,FLASH);
         strncat(ch_flash,sr_num,9);
         strcat(ch_flash,PATH);
         strcat(ch_flash,"bt_soc_thunderboard_brd4184b-brd4184b.s37");
         printf("%s\n",ch_flash);
         #ifdef FLASH_FLAG
         system(ch_flash);
         #endif
    }
    else
    {   
        
        my_strncat(ch_flash,FLASH,strlen(FLASH));
        my_strncat(ch_flash,sr_num,9);
        strcat(ch_flash,PATH);
        my_strncat(ch_flash,PRE,strlen(PRE));
        my_strncat(ch_flash,fw_name,strlen(fw_name));
        my_strncat(ch_flash,DASH,strlen(DASH));
        my_strncat(ch_flash,brd_name,strlen(brd_name));
        my_strncat(ch_flash,POST,strlen(POST)); 
        printf("%s\n",ch_flash);
        #ifdef FLASH_FLAG
        system(ch_flash);
        #endif
    }
    printf("\nflashing of Firmware & Bootloader is successfully DONE !!!!!!!!!!!!!!!! for Board %s & Serial Number -%s \n",brd_name,sr_num);
    LAST: printf("\n");
}

void report(char * data)
{
    printf("Warning !!!!!!!!!!!!!!!!!!!\n");
    printf("\n");
    printf("The Given Board %s has not configured Firmware name In the Config file..\n",data);
}

void app_log(char *str, char * file, int line, const char* func)
{
#ifdef DEBUG
    DEBUG_PRINT("Debug msg is [%s], file -[ %s], line - [%d], func [%s.]\n",str,file,line,func);
#endif
}

void freeLinkedList() {
    brd* current = head;
    brd* next;

    while (current != NULL) {
        next = current->link;
        free(current);
        current = next;
    }
}
