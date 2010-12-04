//
//  FileExtCommand.m
//
//  Created by Jesse MacFadyen on 10-10-09.
//  Copyright 2010 Nitobi. All rights reserved.
//

#import "FileTransferCommand.h"
#import "ASIFormDataRequest.h"


@implementation FileTransferCommand

- (void) download:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	if (!queue) 
	{
		queue = [[[NSOperationQueue alloc] init] autorelease];
	}
	
	int argc = arguments.count;
	if(argc < 3)
	{
		NSLog(@"Error: FileTransferCommand called with too few arguments. aborting",0);
		return;
	}
	
	NSString  *src      = [arguments objectAtIndex:0];
    NSString  *dest     = [arguments objectAtIndex:1];
	NSString  *reqId = [ arguments objectAtIndex:2];
	
	NSURL* url = [NSURL URLWithString:src];
	
	
	ASIHTTPRequest* req = [[ASIHTTPRequest alloc] initWithURL:url];
	
	req.requestMethod = @"GET";
	
	[req setDelegate:self];
	req.downloadProgressDelegate = self;
	
	[req setDidFinishSelector: @selector(downloadRequestFinished:)];
	[req setDidFailSelector: @selector(downloadRequestFailed:)];	
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* path = [[paths objectAtIndex:0] stringByAppendingPathComponent:dest];
	
	[req setDownloadDestinationPath:path];
	
	NSMutableDictionary* userData = [NSMutableDictionary dictionary];
	[userData setValue:dest forKey:@"dest"];
	[userData setValue:reqId forKey:@"reqId"];
	req.userInfo = userData;
	
	[queue addOperation:req];

	
}

//- (void)setProgress:(float)newProgress
//{
//	NSLog(@"New Progress = %f",newProgress);
//	NSString* jsCallback = [NSString stringWithFormat:@"onProgress(%f);",newProgress];
//	[ webView stringByEvaluatingJavaScriptFromString:jsCallback];
//}


- (void)downloadRequestFinished:(ASIHTTPRequest *)request
{	
	int responseStatusCode = [request responseStatusCode];
	NSLog(@"downloadRequestFinished : %d",responseStatusCode);
	
	
	NSString* reqId = [request.userInfo valueForKey:@"reqId"];
	NSString* jsCallback;
	
	if(responseStatusCode == 404)
	{
		jsCallback = [NSString stringWithFormat:@"navigator.plugins.fileTransfer._downloadError(\"%@\",\"%d\",\"%@\");",
						reqId,
						responseStatusCode,
						@""];	
	}
	else 
	{
		jsCallback = [NSString stringWithFormat:@"navigator.plugins.fileTransfer._downloadComplete(\"%@\",%d,%d);",
					  reqId,
					  responseStatusCode,
					  request.totalBytesRead];
	}

	[ webView stringByEvaluatingJavaScriptFromString:jsCallback];
	
}

- (void)downloadRequestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	NSLog(@"%@",[ error localizedDescription]);
	
	NSString* reqId = [request.userInfo valueForKey:@"reqId"];
	NSString* responseStr = [request responseString];
	
	NSString* escapedUrlString = [responseStr stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	
	NSString* jsCallback = [NSString stringWithFormat:@"navigator.plugins.fileTransfer._downloadError(\"%@\",\"%@\",\"%@\");",
							reqId,
							[ error localizedDescription ],
							escapedUrlString];
	
	[ webView stringByEvaluatingJavaScriptFromString:jsCallback];	
}

-(void)uploadRequestFinished:(ASIHTTPRequest*)request
{
	NSLog(@"uploadRequestFinished ResponseData : %@",[request responseString]);
	// userInfo
	// totalBytesUploaded
	
	NSString* reqId = [request.userInfo valueForKey:@"reqId"];
	NSString* responseStr = [request responseString];
	
	NSString* escapedUrlString = [responseStr stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	
	NSString* jsCallback = [NSString stringWithFormat:@"navigator.plugins.fileTransfer._uploadComplete(\"%@\",\"%@\",%d,%d);",
							reqId,
							escapedUrlString,
							request.totalBytesSent,
							[request responseStatusCode]];
	
	[ webView stringByEvaluatingJavaScriptFromString:jsCallback];
}

-(void)uploadRequestFailed:(ASIHTTPRequest*)request
{
	NSError *error = [request error];
	NSLog(@"%@",[ error localizedDescription]);
	
	NSString* reqId = [request.userInfo valueForKey:@"reqId"];
	NSString* responseStr = [request responseString];
	
	NSString* escapedUrlString = [responseStr stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	
	NSString* jsCallback = [NSString stringWithFormat:@"navigator.plugins.fileTransfer._uploadError(\"%@\",\"%@\",\"%@\");",
							reqId,
							[ error localizedDescription ],
							escapedUrlString];
							
	[ webView stringByEvaluatingJavaScriptFromString:jsCallback];						
	
}



- (void) upload:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	if (!queue) 
	{
		queue = [[[NSOperationQueue alloc] init] autorelease];
	}
	
	int argc = arguments.count;
	if(argc < 3)
	{
		NSLog(@"Error: FileTransferCommand called with too few arguments. aborting",0);
		return;
	}
	
	NSString  *srcUrl      = [arguments objectAtIndex:0];
    NSString  *postUrl     = [arguments objectAtIndex:1];
	NSString  *reqId	   = [arguments objectAtIndex:2];
	
	
	NSString  *mediaKey	   = @"media";
	NSString  *mimeType    = @"image/jpeg";
	if(argc > 3)
	{
		mediaKey = [arguments objectAtIndex:3];
	}
	if(argc > 4)
	{
		mimeType = [arguments objectAtIndex:4];
	}
	
	NSURL* url = [NSURL URLWithString:postUrl];
	
	
	ASIFormDataRequest *req = [ASIFormDataRequest requestWithURL:url];
	req.postFormat = ASIMultipartFormDataPostFormat;
	
	NSEnumerator *enumerator = [options keyEnumerator];
	
	id key;
	
	while ((key = [enumerator nextObject])) {
		
		NSString* str = (NSString*)key;
		NSString* value = [options valueForKey:str];
		//NSLog(@"Setting key:%@ value:%@",str,value);
		[req addPostValue:value forKey:str];
	}

	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* path = [[paths objectAtIndex:0] stringByAppendingPathComponent:srcUrl];
	
	[req setFile:path withFileName:srcUrl andContentType:@"image/jpeg" forKey:@"media"];

	[req setDelegate:self];
	
	NSMutableDictionary* userData = [NSMutableDictionary dictionary];
	[userData setValue:reqId forKey:@"reqId"];
	req.userInfo = userData;
	
	req.uploadProgressDelegate = self;
	
	[req setDidFinishSelector: @selector(uploadRequestFinished:)];
	[req setDidFailSelector: @selector(uploadRequestFailed:)];	
	
	[queue addOperation:req];
	
}

- (void) dealloc
{	
	[super dealloc];
}


@end
