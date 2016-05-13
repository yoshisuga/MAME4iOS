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


#import "NetplayGameKit.h"
#import "Globals.h"

#include "netplay.h"

static NetplayGameKit *sharedInstance = nil;

NSData *_data;

@interface NetplayGameKit()

-(void)sendData:(NSData *)data;
-(void)onTick:(NSTimer *)timer;
-(void)teardownConnection;
-(void)teardownConnectionWithWarn;

@end

static int read_pkt_data(netplay_t *handle,netplay_msg_t *msg)
{
    if(_data.length != sizeof(netplay_msg_t))
    {
        return 0;
    }
    [_data getBytes:msg length:sizeof(netplay_msg_t)];
    return 1;
}

static int send_pkt_data(netplay_t *handle,netplay_msg_t *msg)
{
    [sharedInstance sendData:[NSData dataWithBytesNoCopy:msg length:sizeof(netplay_msg_t) freeWhenDone:NO]];
    return 1;
}

@implementation NetplayGameKit

@synthesize session;
@synthesize connected;

+(NetplayGameKit *) sharedInstance{
    @synchronized(self){
        if (!sharedInstance) {
            sharedInstance = [[self alloc] init];
        }
    }
    return sharedInstance;
}

- (id)init {
    
    if (self = [super init]) {
        peers=[[NSMutableArray alloc] init];
        session = nil;
        timer = nil;
        
        /*
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        
        [defaultCenter addObserver:self
                          selector:@selector(teardownConnectionWithWarn)
                              name:UIApplicationDidEnterBackgroundNotification
                            object:nil];
        */
    }
    
    return self;
}

- (void)dealloc {
    [self teardownConnection];
	[peers release];
    [super dealloc];
}

- (void) connect:(bool)server{

    netplay_t *handle = netplay_get_handle();
    netplay_init_handle(handle);
    handle->read_pkt_data = read_pkt_data;
    handle->send_pkt_data = send_pkt_data;
    handle->type = NETPLAY_TYPE_GAMEKIT;
    
    handle->player1 = server ? 1 : 0;
    
    [self teardownConnection];
    
    
    session = server ? [[GKSession alloc] initWithSessionID:@"com.seleuco.mame4ios" displayName:nil
                                                sessionMode: GKSessionModeServer] :
                       [[GKSession alloc] initWithSessionID:@"com.seleuco.mame4ios" displayName:nil
                             sessionMode: GKSessionModeClient];
    
    //session = [[GKSession alloc] initWithSessionID:@"com.seleuco.mame4ios" displayName:nil
    //                                  sessionMode: GKSessionModePeer];

    session.delegate = self;
    //session.disconnectTimeout = 20;
    [session setDataReceiveHandler:self withContext:nil];
    
    session.available = YES;
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 2.0
                                                  target: self
                                                selector:@selector(onTick:)
                                                userInfo: nil repeats:YES];
}

- (void)teardownConnection
{
    printf("Tiro sesion\n");
    
    netplay_t *handle = netplay_get_handle();
    connected = false;
    handle->has_connection = false;
    
    if(session != nil)
    {
        [session disconnectFromAllPeers];
        [peers removeAllObjects];
        session.available = NO;
        session.delegate = nil;
        [session release];
        session = nil;
    }
    if(timer!=nil)
    {
        [timer invalidate];
        timer = nil;
    }
}

- (void)teardownConnectionWithWarn{
    netplay_t *handle = netplay_get_handle();
    if(handle->has_connection && handle->has_begun_game)
        netplay_warn_hangup(handle);
    [self teardownConnection];
}

-(void)sendData:(NSData *)data{
   // NSError *error = nil;
   //[session sendDataToAllPeers:data withDataMode:/*GKSendDataReliable*/GKSendDataUnreliable error:&error];
    [session sendData:data toPeers:peers withDataMode: /*GKSendDataReliable*/ GKSendDataUnreliable error:nil];
    //if(error!=nil)
        //NSLog(@"Send data error: %@", [error localizedDescription]);
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{
    _data = data;
    
    netplay_t *handle = netplay_get_handle();
    netplay_read_data(handle);
}

#pragma mark -
#pragma mark GKSessionDelegate

- (void)session:(GKSession *)_session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state{
    
    NSString *str = [NSString stringWithFormat:@"didChangeState %@",[session displayNameForPeer:peerID]];
    NSLog(@"%@", str);
    
    if(state == GKPeerStateConnected){
        NSLog(@"Recieved GKPeerStateConnected");
        
        if([peers count]==0)
        {
           netplay_t *handle = netplay_get_handle();
           handle->has_connection = true;
           [peers addObject:peerID];
           connected = true;
        }
	}
    else if(state == GKPeerStateAvailable){
        NSLog(@"Recieved GKPeerStateAvailable");
        
        if([peers count]==0)
           [_session connectToPeer:peerID withTimeout:120];
        
        //session.available = NO;
    }
    else if(state == GKPeerStateDisconnected)
    {
        //[self teardownConnection];
    }

}

- (void)session:(GKSession *)_session didReceiveConnectionRequestFromPeer:(NSString *)peerID{
    NSLog(@"Recieved Connection Request");
    NSString *str = [NSString stringWithFormat:@"didChangeState %@",[session displayNameForPeer:peerID]];
    NSLog(@"%@", str);;
    
    if([peers count]==0)
       [_session acceptConnectionFromPeer:peerID error:nil]; //acepto la conexion sino tengo ningun par
    else
       [_session denyConnectionFromPeer:peerID];
     
}

-(void)onTick:(NSTimer *)timer {
    
    //printf("Comprobando conexion\n");
    
    netplay_t *handle = netplay_get_handle();

    if(!handle->has_connection && connected)
        [self teardownConnection];
}

@end
