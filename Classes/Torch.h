//
//  Torch.h
//
//  Created by todd hopkinson on 7/10/10.
//  Copyright 2010 Todd Hopkinson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

// Notification strings for observers of Torch, used in torch start and stop
extern NSString * const TorchDidStartNotification;
extern NSString * const TorchDidStopNotification;

@interface Torch : NSObject {
	AVCaptureSession*            mSession;
	AVCaptureDevice*             mDevice;
	NSError*                     mErr;
	AVCaptureInput*              mInput;
	AVCaptureStillImageOutput*   mOutput;
	
	NSString*		mLineElements;
	NSInteger	mLineLength;
	
	NSTimer*    mStrobeTimer;
	BOOL        mStrobing;
	NSInteger   mStrobeTicks;
	int   mAplhabetCharacterPos;
}

@property (nonatomic, retain) NSString *mLineElements;
@property (nonatomic, assign) NSInteger mLineLength;

+ (Torch *) sharedInstance;

-(id)init;

-(void)start;

-(void)stop;

-(void)startStrobesPerSecond:(int)strobesPerSecond forNumberOfSeconds:(int)numberOfSeconds;

-(void)startStrobesForMorseString:(NSString*)alphabetMorse forCharacterInterval:(float)numberOfSeconds;
-(void)stopStrobe;

-(BOOL)isTorchOn;

-(BOOL)isStrobing;

-(void)softReset;

@end
