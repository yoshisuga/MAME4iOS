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

// GKSession is deprecated, dont bother me!
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

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
@synthesize peerId;
@synthesize browser;
@synthesize assistant;

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
        peerId = nil;
        
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
    
    peerId = [[MCPeerID alloc] initWithDisplayName:[NSString stringWithFormat:@"Gamer+%@",server?@"server":@"client"]];
    session =  [[MCSession alloc] initWithPeer:peerId securityIdentity:nil encryptionPreference:nil];

    session.delegate = self;
    
    
    if(server){
        assistant = [[MCNearbyServiceAdvertiser alloc] initWithPeer:peerId discoveryInfo:nil serviceType:@"MAME-NET"];
        assistant.delegate = self;
        [assistant startAdvertisingPeer];

    }else{
        browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerId serviceType:@"MAME-NET"];
        browser.delegate = self;
        [browser startBrowsingForPeers];
    }
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 2.0
                                                  target: self
                                                selector:@selector(onTick:)
                                                userInfo: nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)teardownConnection
{
    printf("Tiro sesion\n");
    
    netplay_t *handle = netplay_get_handle();
    connected = false;
    handle->has_connection = false;
    
    if(peerId != nil){
        [peerId release];
        peerId = nil;
    }
    if(browser != nil){
        [browser stopBrowsingForPeers];
        [browser release];
        browser = nil;
    }
    if(assistant != nil){
        [assistant stopAdvertisingPeer];
        [assistant release];
        assistant = nil;
    }

    if(session != nil)
    {
        [session disconnect];
        [peers removeAllObjects];
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

    NSError *error = nil;
//    NSLog(@"mame -- send data size : %ld B",data.length);
    [session sendData:data toPeers:peers withMode:MCSessionSendDataUnreliable error:&error];
    if(error != nil){
        NSLog(@"Send data error: %@", [error localizedDescription]);
    }
}


#pragma mark -
#pragma mark MCSessionDelegate
- (void) session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    _data = data;
//    NSLog(@"mame -- receive data size : %ld B",data.length);

    netplay_t *handle = netplay_get_handle();
    netplay_read_data(handle);
}


- (void) session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    NSString *str = [NSString stringWithFormat:@"didChangeState %@",peerID.displayName];
    NSLog(@"%@", str);

    if(state == MCSessionStateConnected){
        NSLog(@"Recieved MCSessionStateConnected");
        if([peers count]==0){
            netplay_t *handle = netplay_get_handle();
            handle->has_connection = true;
            [peers addObject:peerID];
            connected = true;
        }
    }else if (state == MCSessionStateNotConnected){
//        if([peers count]==0)
//           [_session connectToPeer:peerID withTimeout:120];
        NSLog(@"lost connect from %@",peerID.displayName);
        if([peers containsObject:peerID]){
            
        }
        for(MCPeerID *item in peers){
            if([item.displayName isEqualToString:peerID.displayName]){
                [peers removeObject:item];
//                [item release];
                break;
            }
        }

    }else if(state == MCSessionStateConnecting){
        NSLog(@"connection ...");

    }
}

#pragma mark -
#pragma mark GKSessionDelegate

//- (void)session:(GKSession *)_session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state{
//    
//    NSString *str = [NSString stringWithFormat:@"didChangeState %@",[session displayNameForPeer:peerID]];
//    NSLog(@"%@", str);
//    
//    if(state == GKPeerStateConnected){
//        NSLog(@"Recieved GKPeerStateConnected");
//        
//        if([peers count]==0)
//        {
//           netplay_t *handle = netplay_get_handle();
//           handle->has_connection = true;
//           [peers addObject:peerID];
//           connected = true;
//        }
//	}
//    else if(state == GKPeerStateAvailable){
//        NSLog(@"Recieved GKPeerStateAvailable");
//        
//        if([peers count]==0)
//           [_session connectToPeer:peerID withTimeout:120];
//        
//        //session.available = NO;
//    }
//    else if(state == GKPeerStateDisconnected)
//    {
//        //[self teardownConnection];
//    }
//
//}

//- (void)session:(GKSession *)_session didReceiveConnectionRequestFromPeer:(NSString *)peerID{
//    NSLog(@"Recieved Connection Request");
//    NSString *str = [NSString stringWithFormat:@"didChangeState %@",[session displayNameForPeer:peerID]];
//    NSLog(@"%@", str);;
//
//    if([peers count]==0)
//       [_session acceptConnectionFromPeer:peerID error:nil]; //acepto la conexion sino tengo ningun par
//    else
//       [_session denyConnectionFromPeer:peerID];
//
//}
// Required because of an apple bug
//- (void) session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL))certificateHandler{
//    certificateHandler(YES);
//    NSLog(@"didReceiveCertificate peerId = %@",peerID.displayName);
//
//}
- (void) session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
    NSLog(@"didReceiveStream peerId = %@",peerID.displayName);
}
- (void) session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
    NSLog(@"didStartReceivingResourceWithName peerId = %@ ,resourceName = %@ ",resourceName,peerID.displayName);

}
-(void) session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{
       NSLog(@"didFinishReceivingResourceWithName peerId = %@ ,resourceName = %@, error = %@",resourceName,peerID.displayName,error.localizedDescription);


}
#pragma mark - browser delegate
-(void) browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary<NSString *,NSString *> *)info{
    NSLog(@"Recieved Connection Request");
    NSString *str = [NSString stringWithFormat:@"foundPeer %@",peerID.displayName];
    NSLog(@"%@", str);;
        
    if(peers.count == 0){
        [browser invitePeer:peerID toSession:session withContext:nil timeout:120];
    }
}
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error{
    NSLog(@"didNotStartBrowsingForPeers error %@",error.localizedDescription);

}
- (void) browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"MCNearbyServiceBrowser lost %@", peerID.displayName);

}

- (void) advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error{
    NSLog(@"didNotStartAdvertisingPeer error %@",error.localizedDescription);

}
- (void) advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession * _Nullable))invitationHandler{
    NSLog(@"didReceiveInvitationFromPeer peerID %@", peerID.displayName);
    invitationHandler(YES, session);

}

-(void)onTick:(NSTimer *)timer {
    
    //printf("Comprobando conexion\n");
    
    netplay_t *handle = netplay_get_handle();

    if(!handle->has_connection && connected)
        [self teardownConnection];
}

@end
