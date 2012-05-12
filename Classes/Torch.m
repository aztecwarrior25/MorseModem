//
//  Torch.m
//
//  Created by todd hopkinson on 7/10/10.
//  Copyright 2010 Todd Hopkinson. All rights reserved.
//

#import "Torch.h"
#import <AVFoundation/AVFoundation.h>

NSString* const TorchDidStartNotification=@"TorchDidStartNotification";
NSString* const TorchDidStopNotification=@"TorchDidStopNotification";

@implementation Torch

@synthesize mLineLength,mLineElements;

static Torch *_sharedInstance;

+ (Torch *) sharedInstance{
	if (!_sharedInstance){
		_sharedInstance = [[Torch alloc] init];
	}	
	return _sharedInstance;
}

-(void) myInit {
	mSession = [[AVCaptureSession alloc] init];
	mDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	[mDevice lockForConfiguration:&mErr];
	[mSession beginConfiguration];
	mInput = [[AVCaptureDeviceInput alloc] initWithDevice:mDevice error:&mErr];
	mOutput = [[AVCaptureStillImageOutput alloc] init];
	[mSession addInput:mInput];
	[mSession addOutput:mOutput];
	[mSession commitConfiguration];
	[mSession startRunning];
	
	mStrobing = NO;

}

-(id)init{
	if(self = [super init]){
		[self myInit];
	}
	return self;
}

-(void)start{
	[mDevice setTorchMode:AVCaptureTorchModeOn];
	[[NSNotificationCenter defaultCenter] postNotificationName:TorchDidStartNotification object:nil];
}

-(void)stop{
	[mDevice setTorchMode:AVCaptureTorchModeOff];
	[[NSNotificationCenter defaultCenter] postNotificationName:TorchDidStopNotification object:nil];
}

-(void)startStrobesPerSecond:(int)strobesPerSecond forNumberOfSeconds:(int)numberOfSeconds{
	
	//NSLog(@"strobesPerSec: %i   ForSeconds: %i", strobesPerSecond, numberOfSeconds);
	
    // validity
	if(strobesPerSecond <= 0)
		return;
	
	if(mStrobing)
		[self stopStrobe];
		//return;
    
    strobesPerSecond = strobesPerSecond * 2;    // bc strobe is the on and off count together, not just on
    
    // mode
	BOOL isInfinitLoop = (numberOfSeconds == -1);
    
    int strobeCount = strobesPerSecond * numberOfSeconds;
    NSTimeInterval strobeInterval = (double)numberOfSeconds / strobeCount;
    
	if(isInfinitLoop){
		mStrobeTicks = -1;
        strobeInterval = (NSTimeInterval) 1 / strobesPerSecond;
    }
	else
		mStrobeTicks = strobeCount;
	
    //NSLog(@"interval= %f", strobeInterval);
	mStrobeTimer = [NSTimer scheduledTimerWithTimeInterval: strobeInterval
													target: self
												  selector: @selector(strobeTimerLoopAction)
												  userInfo: nil
												   repeats: YES];

	mStrobing = YES;
}

-(void)strobeTimerLoopAction{
	
	if (mStrobeTicks == 0) {
		[self stopStrobe];
		return;
	}
	
	if (mStrobeTicks != -1)
		mStrobeTicks--;
	
	if([self isTorchOn])
		[self stop];
	else {
		[self start];
	}
}


-(void)strobeTimerLoopActionMorse {

	if (mStrobeTicks == 0) {
		if (mLineElements == nil) {
			return;
		}
		//NSLog(mLineElements);
		unichar character =  [mLineElements characterAtIndex:mAplhabetCharacterPos];
		
		if (character == '.') { // dot
			mStrobeTicks = 1;
			mStrobing = true;
		} else	if (character ==' ') { // space between 2 characters i.e between dit and dot
			mStrobeTicks = 1;
 		    mStrobing = false;
		} else	if (character =='-') { // dit
			mStrobeTicks = 3;
			mStrobing = true;
		} else	if (character =='_') { // space between 2 alphabets
			mStrobeTicks = 3;
			mStrobing = false;
		} else {
			return;
		}
 	    mAplhabetCharacterPos = (mAplhabetCharacterPos + 1) % mLineLength;
		//NSLog(@"Now showing character : %c", character);
		
	} 

	
	//
	if (mStrobeTicks != -1)
		mStrobeTicks--;
	
	if(mStrobing) {
		if(![self isTorchOn])
			[self start];
	} else {
		if([self isTorchOn])	
			[self stop];
	}
}

-(void)stopStrobe{
	if (mStrobeTimer != NULL) {
		[mStrobeTimer invalidate];
		mStrobeTimer = nil;
	}
	
	[self stop];
	mStrobing = NO;
}

-(BOOL)isStrobing{
	return mStrobing;
}

-(BOOL)isTorchOn{
	if ([mDevice torchMode] == AVCaptureTorchModeOn) {
		return YES;
	}
	
	return NO;
}

-(void)startStrobesForMorseString:(NSString*)alphabetMorse forCharacterInterval:(float)interval {
	if(mStrobing)
		[self stopStrobe];
	
	mStrobing = false;
	mStrobeTicks = 0;
	mAplhabetCharacterPos = 0;
	//NSLog(@"MorseString %@   ForSecondsIntvl: %i",alphabetMorse , interval);
	NSTimeInterval strobeInterval = (float) interval;
	//mLineElements = [NSString stringWithString:alphabetMorse];
	//mLineElements = alphabetMorse;
	//mLineLength = [alphabetMorse length];
    NSLog(@"interval= %f line elem %@", strobeInterval, mLineElements);
	//[mSession stopRunning];
	//[mSession startRunning];
	mStrobeTimer = [NSTimer scheduledTimerWithTimeInterval: strobeInterval
													target: self
												  selector: @selector(strobeTimerLoopActionMorse)
												  userInfo: nil
												   repeats: YES];
}



- (void)dealloc {
	[mSession stopRunning];
	
	[mInput release];
	[mOutput release];
	[mDevice unlockForConfiguration];
	[mSession release];
	mInput = NULL;
	mOutput = NULL;
	mSession = NULL;
	
	//[_sharedInstance release]; // :TODO: determine best way to dealloc this
    [super dealloc];
}

- (void)softReset {
	[mSession stopRunning];
	
	[mInput release];
	[mOutput release];
	[mDevice unlockForConfiguration];
	[mSession release];
	[self myInit];
	//[_sharedInstance release]; // :TODO: determine best way to dealloc this
}

@end
