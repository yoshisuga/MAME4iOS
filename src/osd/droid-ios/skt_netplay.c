/*
 * This file is part of MAME4iOS.
 *
 * Copyright (C) 2013 David Valdeita (Seleuco)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses>.
 *
 * Linking MAME4iOS statically or dynamically with other modules is
 * making a combined work based on MAME4iOS. Thus, the terms and
 * conditions of the GNU General Public License cover the whole
 * combination.
 *
 * In addition, as a special exception, the copyright holders of MAME4iOS
 * give you permission to combine MAME4iOS with free software programs
 * or libraries that are released under the GNU LGPL and with code included
 * in the standard release of MAME under the MAME License (or modified
 * versions of such code, with unchanged license). You may copy and
 * distribute such a system following the terms of the GNU GPL for MAME4iOS
 * and the licenses of the other code concerned, provided that you include
 * the source code of that other code when and as the GNU GPL requires
 * distribution of source code.
 *
 * Note that people who make modified versions of MAME4iOS are not
 * obligated to grant this special exception for their modified versions; it
 * is their choice whether to do so. The GNU General Public License
 * gives permission to release a modified version without this exception;
 * this exception also makes it possible to release a modified version
 * which carries forward this exception.
 *
 * MAME4iOS is dual-licensed: Alternatively, you can license MAME4iOS
 * under a MAME license, as set out in http://mamedev.org/
 */

#include <sys/socket.h>
#include <netdb.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/types.h>
#include <errno.h>

#include <signal.h>

#include <unistd.h>

#include <pthread.h>

#include <stdio.h>
#include <string.h>

#include "netplay.h"
#include "skt_netplay.h"

static skt_netplay_t skt_netplay_impl;
static pthread_t main_tid;

static int skt_init_handle_impl(skt_netplay_t *impl){
    
    memset(impl,0,sizeof(skt_netplay_impl));
    
    impl->fd = -1;
    
    return 1;
}

static skt_netplay_t * skt_get_handle_impl(){
    static int init = 0;
    if(!init)
    {
        skt_init_handle_impl(&skt_netplay_impl);
        
        signal(SIGPIPE, SIG_IGN); // Do not like SIGPIPE killing our app :(

        init = 1;
    }
    return &skt_netplay_impl;
}

static int skt_init_udp_socket(netplay_t *handle, const char *server, uint16_t port)
{
    struct addrinfo hints;
    memset(&hints, 0, sizeof(hints));
        
    skt_netplay_t *impl = (skt_netplay_t *)handle->impl_data;
    
    hints.ai_family = AF_INET;    
    hints.ai_socktype = SOCK_DGRAM;
    if (!server)
        hints.ai_flags = AI_PASSIVE;
    
    char port_buf[16];
    snprintf(port_buf, sizeof(port_buf), "%hu", (unsigned short)port);
    if (getaddrinfo(server, port_buf, &hints, &impl->addr) < 0)
        return 0;
    
    if (!impl->addr)
        return 0;
    
    impl->fd = socket(impl->addr->ai_family, impl->addr->ai_socktype, impl->addr->ai_protocol);
    if (impl->fd < 0)
    {
        return 0;
    }
    
    if (!server)
    {
        int yes = 1;
        setsockopt(impl->fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int));
        
        if (bind(impl->fd, impl->addr->ai_addr, impl->addr->ai_addrlen) < 0)
        {
            char buf[256];
            sprintf(buf,"Failed to bind socket.\nError: %s\n",strerror(errno));
            handle->netplay_warn(buf);
            close(impl->fd);
            impl->fd = -1;
        }
        
        freeaddrinfo(impl->addr);
        impl->addr = NULL;
        if(impl->fd == -1)
            return 0;
    }
    
    return 1;
}

/*
static int skt_init_tcp_socket(netplay_t *handle, const char *server, uint16_t port)
{
    struct addrinfo hints;
    skt_netplay_t *impl = (skt_netplay_t *)handle->impl_data;
    
    memset(&hints, 0, sizeof(hints));
    
    hints.ai_family = AF_INET;    
    hints.ai_socktype = SOCK_STREAM;
    if (!server)
        hints.ai_flags = AI_PASSIVE;
    
    char port_buf[16];
    snprintf(port_buf, sizeof(port_buf), "%hu", (unsigned short)port);
    if (getaddrinfo(server, port_buf, &hints, &impl->addr) < 0)
        return 0;
    
    if (!impl->addr)
        return 0;
    
    if (!server)
    {
        int new_fd;
        
        while (impl->addr)
        {
            
            impl->fd = socket(impl->addr->ai_family, impl->addr->ai_socktype, impl->addr->ai_protocol);
            if (impl->fd < 0)
            {
                printf("Failed to init socket...\n");
                return 0;
            }
            
            int yes = 1;
            setsockopt(impl->fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int));
            if(setsockopt(impl->fd, IPPROTO_TCP, TCP_NODELAY, &yes, sizeof(int))<0)
            {
                printf("an error: %s\n", strerror(errno));
            }
            
            if (bind(impl->fd, impl->addr->ai_addr, impl->addr->ai_addrlen) < 0 ||
                listen(impl->fd, 6))
            {
                printf("Failed to bind socket.\n");
                printf("an error: %s\n", strerror(errno));
                close(impl->fd);
                impl->fd = -1;
            }
            
            if(impl->fd == -1)
                return 0;
            
            socklen_t clilen = sizeof(impl->client_addr);
            
            new_fd = accept(impl->fd, (struct sockaddr*)&impl->client_addr, &clilen);
            if (new_fd < 0)
            {
                printf("Failed to accept socket.\n");
                printf("an error: %s\n", strerror(errno));
            }
            else
            {
                printf(" accept socket.\n");
            }
            
            impl->addr = impl->addr->ai_next;
        }
        
        close(impl->fd);
        impl->fd = new_fd;
        
        freeaddrinfo(impl->addr);
        impl->addr = NULL;
    }
    else
    {
        impl->fd = socket(impl->addr->ai_family, impl->addr->ai_socktype, impl->addr->ai_protocol);
        if (impl->fd < 0)
        {
            printf("Failed to init socket...\n");
            return 0;
        }
        
        if (connect(impl->fd, impl->addr->ai_addr, impl->addr->ai_addrlen) < 0)
        {
            {
                printf("Failed to conect to socket.\n");
                printf("an error: %s\n", strerror(errno));
                close(impl->fd);
                impl->fd = -1;
                return 0;
            }
        }
        else
        {
            printf("conect to socket.\n");
        }
    }
    
    return 1;
}*/

int skt_netplay_get_address(const char *name, char*ip)
{
    struct ifaddrs *allInterfaces;
    int find = 0;
    
    // Get list of all interfaces on the local machine:
    if (getifaddrs(&allInterfaces) == 0) {
        struct ifaddrs *interface;
        
        // For each interface ...
        for (interface = allInterfaces; interface != NULL; interface = interface->ifa_next) {
            unsigned int flags = interface->ifa_flags;
            struct sockaddr *addr = interface->ifa_addr;
            
            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if ((flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING)) {
                if (addr->sa_family == AF_INET /*|| addr->sa_family == AF_INET6*/) {
                    
                    // Convert interface address to a human readable string:
                    char host[NI_MAXHOST];
                    getnameinfo(addr, addr->sa_len, host, sizeof(host), NULL, 0, NI_NUMERICHOST);
                    
                    //en0 es WIFI, pdp_ip0 es 3g
                    //printf("address %s %s\n",interface->ifa_name, host);
                    
                    if(strcmp(interface->ifa_name,name)==0)
                    {
                        if(ip!=NULL)
                           strcpy(ip,host);
                        find = 1;
                    }
                }
            }
        }
        freeifaddrs(allInterfaces);
    }
    return find;
}

static void* skt_threaded_data(void* args)
{
    fd_set fds;
    struct timeval tv = {0};
    tv.tv_sec = 0;
    //tv.tv_usec = 1;
    tv.tv_usec = 500 * 1000;
    
    struct timeval tmp_tv = tv;
    
    netplay_t *handle = (netplay_t *)args;
    skt_netplay_t *impl = (skt_netplay_t *)handle->impl_data;
    
    printf("Creada threaded_data\n");
    
    while(handle->has_connection){
        
        //printf("waiting!\n");
        
        FD_ZERO(&fds);
        FD_SET(impl->fd, &fds);
        
        if (select(impl->fd + 1, &fds, NULL, NULL, &tmp_tv) < 0)
        {
            handle->has_connection = 0;
            netplay_warn_hangup(handle);
            break;
        }
        
        if (FD_ISSET(impl->fd, &fds)) // packet arrive
        {
            //printf("packet recived!\n");
            
            if(!netplay_read_data(handle))
                break;
        }
    }
    
    close(impl->fd);
    impl->fd = -1;
    
    printf("Muere threaded_data y cierro socket!\n");
    
	return 0;
}

static int skt_read_pkt_data(netplay_t *handle,netplay_msg_t *msg)
{
    skt_netplay_t *impl = (skt_netplay_t *)handle->impl_data;
    socklen_t addrlen = sizeof(impl->client_addr);

    //printf("read_pkt_data!\n");
    
    int l = recvfrom(impl->fd, msg,  sizeof(netplay_msg_t), 0, (struct sockaddr*)&impl->client_addr, &addrlen);
    
    if (l != sizeof(netplay_msg_t))
    {
        netplay_warn_hangup(handle);
        handle->has_connection = 0;
        return 0;
    }
    
    impl->has_client_addr = 1;
    return 1;
}

static int skt_send_pkt_data(netplay_t *handle,netplay_msg_t *msg)
{
    const struct sockaddr *addr = NULL;
    skt_netplay_t *impl = (skt_netplay_t *)handle->impl_data;
    
    //printf("send_pkt_data!\n");
    
    if (impl->addr)
        addr = impl->addr->ai_addr;
    else if (impl->has_client_addr)
        addr = (const struct sockaddr*)&impl->client_addr;
    
    if (addr)
    {
        
        if (sendto(impl->fd, msg,
                   sizeof(netplay_msg_t), 0, addr,
                   sizeof(struct sockaddr)) != sizeof(netplay_msg_t))
        {
            char buf[256];
            sprintf(buf,"Failed to send data.\nError: %s\n",strerror(errno));
            handle->netplay_warn(buf);
            handle->has_connection = 0;
            return 0;
        }
        
        //printf("sent target_frame %d peer_frame: %d [uid:%d]\n",handle->target_frame,handle->peer_frame_count,packet_uid);
    }
    return 1;
}

int skt_netplay_init(netplay_t *handle,const char *server, uint16_t port, void (*warn_cb)(char *))
{
    int res = 0;
    
    skt_netplay_t *impl = skt_get_handle_impl();
    
    printf("Init Netplay %s %d\n",server,port);
    
    if(impl->fd != -1)
    {
        usleep(1000 * 1000);//Thread?
        close(impl->fd );//anyway
    }
    
    skt_init_handle_impl(impl);
    
    netplay_init_handle(handle);
    
    handle->impl_data = impl;
    handle->read_pkt_data = skt_read_pkt_data;
    handle->send_pkt_data = skt_send_pkt_data;
    handle->netplay_warn = warn_cb;
    
    handle->player1 = server ? 0 : 1;
    handle->type = NETPLAY_TYPE_SKT;
        
    if (!skt_init_udp_socket(handle, server, port))
        return 0;
    
    handle->has_connection = 1;
    
    res = pthread_create(&main_tid, NULL, skt_threaded_data,  (void *)handle);
    if(res!=0)
    {
        printf("Error setting creating pthread %d \n",res);
        close(impl->fd);
        impl->fd = -1;
        return 0;
    }
    
    printf("Conexion creada OK!\n");
    
    return 1;
}

