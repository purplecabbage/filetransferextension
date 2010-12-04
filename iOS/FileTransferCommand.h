//
//  FileExtCommand.h
//
//  Created by Jesse MacFadyen on 10-10-09.
//  Copyright 2010 Nitobi. All rights reserved.
//
#import "PhoneGapCommand.h"
#import "ASIHTTPRequest.h"


@interface FileTransferCommand : PhoneGapCommand<ASIProgressDelegate> {

	NSOperationQueue* queue;
}



- (void) download:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

- (void) upload:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

-(void)uploadRequestFinished:(ASIHTTPRequest*)request;

-(void)uploadRequestFailed:(ASIHTTPRequest*)request;



@end
