#include <linux/i2c-dev.h>
#include <linux/i2c.h>
#include <fcntl.h>
#include <string.h>
#include <stdio.h>
#include <sys/socket.h>
#include "iwlib.h"

#define IFNAME "wlan0"

typedef struct packed_int{
	unsigned char b1;
	unsigned char b2;
	unsigned char b3;
	unsigned char b4;
} packed_int;

typedef union{
	unsigned int i;
	packed_int b;
} packed;

int fd;
char recv_buf[64];
int num_networks = 0;

void init_scan(void);

int main (void)
{
	fd = open("/dev/i2c-1", O_RDWR);
	int flags = fcntl(fd, F_GETFL, 0);
	flags &= ~O_NONBLOCK;
	fcntl(fd, F_SETFL, flags);
	int addr = 0x04;
	ioctl(fd, I2C_SLAVE, addr);
	

	while(1)
	{
		read(fd, recv_buf, 1);
		if(recv_buf[0] == 0x00)
		{
			num_networks = 0;
			init_scan();
			recv_buf[0] = -1;
		}
		else
		{
			if((recv_buf[0] + 1) <= num_networks)
			{
				fprintf(stdout, "%d\n", recv_buf[0]);
				recv_buf[0] = -1;
			}
		}

	}
	
	close(fd);
}

void init_scan()
{

	int skfd = iw_sockets_open();
	wireless_scan_head *context = (wireless_scan_head*) malloc(sizeof(wireless_scan_head));
	context->result = (wireless_scan *)malloc(sizeof(wireless_scan*));

	if(iw_scan(skfd, IFNAME, iw_get_kernel_we_version(), context) < 0)
	{
		perror("iw_scan");
		exit(1);
	}
				
	while(context->result != NULL)
	{
		char *essid = ((context->result)->b).essid;
		int signal = (int)((context->result)->stats).qual.level;
		signal-=255;
		sockaddr sock = (context->result)->ap_addr;
		char mac[64];
		iw_ether_ntop((const struct ether_addr *) sock.sa_data, mac);
		fprintf(stdout, "%s ", mac);
		
		//packed mac;
		//mac.i = sock.sa_data;
		//fprintf(stdout, "%d.%d.%d.%d ", mac.b.b1, mac.b.b2, mac.b.b3, mac.b.b4);


		if(strcmp(essid, ""))
		{
			num_networks++;
			char buf[128];
			//int n = sprintf(buf, "%s;%s;%d", essid, mac, signal);
			int n = sprintf(buf, "%s;%d", essid, signal);
			buf[n] = '\0';
			fprintf(stdout, "%s\n", buf);
			write(fd, buf, n+1);
			fflush(NULL);
			usleep(150000);

		}
		context->result = (context->result)->next;
	}
	
	fprintf(stdout, "Num networks: %d\n", num_networks);

	iw_sockets_close(skfd);
} 
