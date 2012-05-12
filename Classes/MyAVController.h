#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import "MyQueue.h"


/*!
 @class	AVController 
 @author Benjamin Loulier
 
 @brief    Controller to demonstrate how we can have a direct access to the camera using the iPhone SDK 4
 */
@interface MyAVController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
	AVCaptureSession *_captureSession;
	UIImageView *_imageView;
	CALayer *_customLayer;
	AVCaptureVideoPreviewLayer *_prevLayer;
	
	IBOutlet UILabel *nameLabel;
	IBOutlet UILabel *meanLabel;
	IBOutlet UILabel *meanLabel1;
	IBOutlet UILabel *meanLabel2;
	IBOutlet UILabel *inputLabel;
	int frameCount, startSlot, endSlot, processedCount;
	NSString *messageDecoded;
	NSString *letterDecoded;
	NSString *messageInput;
	NSMutableArray *morseLookupTable;
	float lastIntensity;
	bool enquePaused;
	
	MyQueue* imageQueue;
	//NSAutoreleasePool *pool;
}

/*!
 @brief	The capture session takes the input from the camera and capture it
 */
@property (nonatomic, retain) AVCaptureSession *captureSession;

/*!
 @brief	The UIImageView we use to display the image generated from the imageBuffer
 */
@property (nonatomic, retain) UIImageView *imageView;
/*!
 @brief	The CALayer we use to display the CGImageRef generated from the imageBuffer
 */
@property (nonatomic, retain) CALayer *customLayer;
/*!
 @brief	The CALAyer customized by apple to display the video corresponding to a capture session
 */
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *prevLayer;

@property (nonatomic, retain) MyQueue *imageQueue;
@property (nonatomic, retain) UILabel *nameLabel;
@property (nonatomic, retain) UILabel *meanLabel;
@property (nonatomic, retain) UILabel *inputLabel;

@property (nonatomic, retain) NSString *messageInput;

/*!
 @brief	This method initializes the capture session
 */
- (void)initCapture;
- (char) getAlphaFromMorseCode:(NSString*) morseString;
- (void) imageDecoderHandler;
- (void) createLabels;
- (IBAction) stopMorseDecode;
@end