#import "MyAVController.h"
#import "Torch.h"


@implementation MyAVController

@synthesize captureSession = _captureSession;
@synthesize imageView = _imageView;
@synthesize customLayer = _customLayer;
@synthesize prevLayer = _prevLayer;
@synthesize meanLabel;
@synthesize nameLabel;
@synthesize inputLabel;
@synthesize imageQueue;
@synthesize messageInput;

#pragma mark -
#pragma mark Initialization
- (id)init {
	self = [super init];
	if (self) {
		/*We initialize some variables (they might be not initialized depending on what is commented or not)*/
		self.imageView = nil;
		self.prevLayer = nil;
		self.customLayer = nil;
		self.imageQueue = [[MyQueue alloc] init];
	}
	return self;
}

- (void)viewDidLoad {
	morseLookupTable = [[NSMutableArray alloc] initWithObjects: 
						@".-",		//A - #0
						@"-...",	//B
						@"-.-.",	//C
						@"-..",		//D
						@".",		//E
						@"..-.",	//F
						@"--.",		//G
						@"....",	//H
						@"..",		//I
						@".---",	//J
						@"-.-",		//K
						@".-..",	//L
						@"--",		//M
						@"-.",		//N
						@"---",		//O
						@".--.",	//P
						@"--.-",	//Q
						@".-.",		//R
						@"...",		//S
						@"-",		//T
						@"..-",		//U
						@"...-",	//V
						@".--",		//W
						@"-..-",	//X
						@"-.--",	//Y
						@"--..",	//Z
						@"-----",  //0						
						@".----",  //1
						@"..---",  //2
						@"...--",  //3
						@"....-",  //4
						@".....",  //5
						@"-....",  //6						
						@"--...",  //7						
						@"---..",  //8						
						@"----.",  //9
						@".......",  //space
						nil];
	[self createLabels ];
	
	[self initCapture];
	// initalize to 0 
	[NSThread detachNewThreadSelector:@selector(imageDecoderHandler) toTarget:self withObject:nil]; 
	frameCount = processedCount = 0;
	
}

- (void) createLabels {

	/*We intialize the capture*/
	CGRect labelFrame = CGRectMake(10, 285, 300, 45);
	nameLabel = [[UILabel alloc] initWithFrame:labelFrame];
	nameLabel.text =[NSString stringWithFormat:@"Decoded symbols"];
	nameLabel.textAlignment = UITextAlignmentRight;
	nameLabel.font = [UIFont fontWithName:@"Courier" size: 14.0];
	nameLabel.backgroundColor = [UIColor lightGrayColor]; // [UIColor brownColor];
	nameLabel.textColor = [UIColor darkGrayColor];
	nameLabel.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"paper.jpg"]];
	nameLabel.layer.cornerRadius = 8;
	
	
	labelFrame = CGRectMake(25,345, 270, 45);
	meanLabel = [[UILabel alloc] initWithFrame:labelFrame];
	meanLabel.text =[NSString stringWithFormat:@"Decoded letter"];
	meanLabel.textAlignment = UITextAlignmentRight;
	meanLabel.font = [UIFont fontWithName:@"Courier-Bold" size: 24.0];
	meanLabel.backgroundColor = [UIColor darkGrayColor]; // [UIColor brownColor];
	meanLabel.textColor = [UIColor blackColor];	
	meanLabel.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"paper.jpg"]];
	meanLabel.layer.cornerRadius = 6;
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button addTarget:self action:@selector(stopMorseDecode) forControlEvents:UIControlEventTouchUpInside];
	
	[button setTitle:@"Stop" forState:UIControlStateNormal];
	button.frame = CGRectMake(130, 410.0, 60.0, 30.0);
	[button setBackgroundImage:[UIImage imageNamed:@"beige-key-template.png"] forState:UIControlStateNormal];
	[button setBackgroundImage:[UIImage imageNamed:@"white-key-press.png"] forState:UIControlStateHighlighted];
	button.titleLabel.textColor = [UIColor blackColor];
	button.titleLabel.highlightedTextColor = [UIColor blackColor];
	[self.view addSubview:button];
	
	labelFrame = CGRectMake(25,5, 270, 40);
	UILabel *msgLabel = [[UILabel alloc] initWithFrame:labelFrame];
	msgLabel.text =[NSString stringWithFormat:@"Use video box to capture blinking Morse-Code Message from another device in transmit mode or a beacon"];
	msgLabel.textAlignment = UITextAlignmentCenter;
	msgLabel.font = [UIFont fontWithName:@"Courier" size: 10.0];
	msgLabel.backgroundColor = [UIColor clearColor];
	msgLabel.numberOfLines = 3;
	msgLabel.alpha = 0.75;
	[self.view addSubview:msgLabel];
}

- (void)initCapture {
	/*We setup the input*/
	AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput 
										  deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] 
										  error:nil];
	/*We setupt the output*/
	AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	/*While a frame is processes in -captureOutput:didOutputSampleBuffer:fromConnection: delegate methods no other frames are added in the queue.
	 If you don't want this behaviour set the property to NO */
	captureOutput.alwaysDiscardsLateVideoFrames = YES; 
	/*We specify a minimum duration for each frame (play with this settings to avoid having too many frames waiting
	 in the queue because it can cause memory issues). It is similar to the inverse of the maximum framerate.
	 In this example we set a min frame duration of 1/10 seconds so a maximum framerate of 10fps. We say that
	 we are not able to process more than 10 frames per second.*/
	captureOutput.minFrameDuration = CMTimeMake(1, 10);
	
	/*We create a serial queue to handle the processing of our frames*/
	dispatch_queue_t queue;
	queue = dispatch_queue_create("cameraQueue", NULL);
	[captureOutput setSampleBufferDelegate:self queue:queue];
	dispatch_release(queue);
	// Set the video output to store frame in BGRA (It is supposed to be faster)
	NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey; 
	NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]; 
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key]; 
	[captureOutput setVideoSettings:videoSettings]; 
	/*And we create a capture session*/
	self.captureSession = [[AVCaptureSession alloc] init];
	/*We add input and output*/
	[self.captureSession addInput:captureInput];
	[self.captureSession addOutput:captureOutput];
	/*We add the Custom Layer (We need to change the orientation of the layer so that the video is displayed correctly)*/
	//self.customLayer = [CALayer layer];
	//self.customLayer.frame = self.view.bounds;
	//self.customLayer.transform = CATransform3DRotate(CATransform3DIdentity, M_PI/2.0f, 0, 0, 1);
	//self.customLayer.contentsGravity = kCAGravityResizeAspectFill;
	
	UIColor *background = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"pinebg.png"]];
	self.view.backgroundColor = background;
	[background release];
	
	

	//[self.view.layer addSublayer:self.customLayer];
	//self.view.alpha = 0.75;
	/*We add the imageView*/
	self.imageView = [[UIImageView alloc] init];
	self.imageView.frame = CGRectMake(115, 60, 90, 160);
	self.imageView.layer.cornerRadius = 7;
	
	
	[self.imageView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
	[self.imageView.layer setBorderWidth: 5.0];
	self.imageView.alpha = 1.0;	
	[self.view addSubview:self.imageView];
	self.nameLabel.alpha = 1.0;	
	[self.view addSubview:self.nameLabel];
	self.meanLabel.alpha = 1.0;	
	[self.view addSubview:self.meanLabel];
	
	/*We add the preview layer*/
	//self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
	//self.prevLayer.frame = CGRectMake(100, 10, 100, 100);
	//self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	//[self.view.layer addSublayer: self.prevLayer];
	frameCount = 0;
	startSlot = 0;
	endSlot = 0;
	messageDecoded = @"";
	letterDecoded = @"";
	
	enquePaused = false;
	
	/*We start the capture*/
	[self.captureSession startRunning];	
}

#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection 
{ 
	/*We create an autorelease pool because as we are not in the main_queue our code is
	 not executed in the main thread. So we have to create an autorelease pool for the thread we are in*/
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
	
    /*Lock the image buffer*/
    CVPixelBufferLockBaseAddress(imageBuffer,0); 
    /*Get information about the image*/
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer); 
   //size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
   //size_t width = CVPixelBufferGetWidth(imageBuffer); 
   //size_t height = CVPixelBufferGetHeight(imageBuffer);
	
    /*Create a CGImageRef from the CVImageBufferRef*/
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 	
    //CGContextRef largeContext = CGBitmapContextCreate(baseAddress, width/2, height/2, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
	//CGImageRef largeImage = CGBitmapContextCreateImage(largeContext);
	
	/*We release some components*/
    //CGContextRelease(largeContext); 
	

	//UIImage *lgImage= [UIImage imageWithCGImage:largeImage scale:1.0 orientation:UIImageOrientationRight];
	/*We display the result on the custom layer. All the display stuff must be done in the main thread because
	 UIKit is no thread safe, and as we are not in the main thread (remember we didn't use the main_queue)
	 we use performSelectorOnMainThread to call our CALayer and tell it to display the CGImage.*/
	//[self.customLayer performSelectorOnMainThread:@selector(setContents:) withObject: largeImage waitUntilDone:YES];
	
	
	//CGImageRelease(largeImage);
	
	 //This is for scaling down the image
	size_t newHt = 90;
	size_t newWt = 160;
	
	uint8_t *newBaseAddress = (uint8_t *) malloc(4*newHt*newWt);
	//	capture window starts at 195,260
	int startAt = (4*1280*315);  // 720px width/2 minus half of tiny window 45
	for (int i=0; i<newHt; i++) {
		// move to middle
		startAt+= (4*560);
		int rowBase = 4*newWt*i;
		for (int j =0 ; j < newWt ; j++) {
			int pixelBase = rowBase + 4*j;
			
			newBaseAddress[pixelBase] = baseAddress[startAt];
			newBaseAddress[pixelBase + 1] = baseAddress[startAt + 1];
			newBaseAddress[pixelBase + 2] = baseAddress[startAt + 2];
			newBaseAddress[pixelBase + 3] = baseAddress[startAt + 3];
			startAt+=4;
			
		}
		// move to end
		startAt+= (4*560);
	}
    CGContextRef newContext = CGBitmapContextCreate(newBaseAddress, newWt, newHt, 8, 4*newWt, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
	
    CGImageRef newImage = CGBitmapContextCreateImage(newContext); 
	
    /*We release some components*/
    CGContextRelease(newContext); 
    CGColorSpaceRelease(colorSpace);
    
	/*We display the result on the custom layer. All the display stuff must be done in the main thread because
	 UIKit is no thread safe, and as we are not in the main thread (remember we didn't use the main_queue)
	 we use performSelectorOnMainThread to call our CALayer and tell it to display the CGImage.*/
	//[self.customLayer performSelectorOnMainThread:@selector(setContents:) withObject: (id) newImage waitUntilDone:YES];
	
	
	/*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly).
	 Same thing as for the CALayer we are not in the main thread so ...*/
	//UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
	UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
	
	/*We relase the CGImageRef*/
	
	CGImageRelease(newImage);
	// we deallocate the buffer here as documentation says the buffer is regenerated
	if(newBaseAddress) {
		free(newBaseAddress);
	}
	
	
	[self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
	// enque image (dunno about memory leaks yet)
	frameCount++;
	if(frameCount%3 == 0 && !enquePaused) {
		[imageQueue addObject:image];
		//NSLog(@"enque frame %d", frameCount);
	}
	
	
	/*We unlock the  image buffer*/
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
	
	[pool drain];
} 

#pragma mark -
#pragma mark Memory management


- (void)viewDidUnload {
	self.imageView = nil;
	self.customLayer = nil;
	self.prevLayer = nil;
}

- (void)dealloc {
	[self.captureSession release];
    [super dealloc];
}

- (void)imageDecoderHandler {
	//bool calibrated = false;
	NSString *characterDecoded = @"";
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 
	//NSLog(@"Dequeue fc %d", frameCount);
	while (TRUE) {
		UIImage* queuedImage = (UIImage*) [imageQueue takeObject];
		if (queuedImage != nil) {
			// start getting pixels
			// this wont be required if we only enqueue the pixel data
			// First get the image into your data buffer
			CGImageRef imageRef = [queuedImage CGImage];
			NSUInteger width = CGImageGetWidth(imageRef);
			NSUInteger height = CGImageGetHeight(imageRef);
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			//unsigned char *pixelBytes = malloc(height * width * 4);
			unsigned char *pixelBytes = malloc(height * width * 4);
			NSUInteger bytesPerPixel = 4;
			NSUInteger bytesPerRow = bytesPerPixel * width;
			NSUInteger bitsPerComponent = 8;
			CGContextRef context = CGBitmapContextCreate(pixelBytes, width, height,
														 bitsPerComponent, bytesPerRow, colorSpace,
														 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
			CGColorSpaceRelease(colorSpace);
			
			CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
			CGContextRelease(context);
			
			// end getting pixels
			
			// calculate mean
			float meanAll = 0.0f;		
			
			//NSLog(@"Calculating mean after dequeue, %d", processedCount++);
			
			//unsigned char* pixelBytes = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);		
			int totalPixels = width*height*4;
			
			// sum, assuming 32-bit RGBA (sub sample by 4 pixels (see only every 4th pixel))
			for(int i = 0; i < totalPixels; i += 4) {
				// grayscaled
				meanAll +=  (float)(pixelBytes[i] + pixelBytes[i+1] + pixelBytes[i+2]) /3.0f;
			}
			
			meanAll = meanAll*4/totalPixels;
			
			if(pixelBytes) {
				free(pixelBytes);
			}
			//if (queuedImage)
			//	[queuedImage release];
			
			processedCount++;
			
			//NSLog(@"Calc MeanTotal: %d of %d is %1.2f grayscaled, startslot=%d, endslot=%d", processedCount, frameCount, meanAll, startSlot, endSlot);
			
			// start decode here
			
			float delta = 20; //should be configureable - denotes difference in RGB intensity to qualify a transition from bright to dark
			// try to calibrate the changes for first 5 frames 
			//skip first 3 frames to stabilize
			if (processedCount < 3) {
				continue;
			}
			
			// use next to configure
			if (processedCount < 11) {
				[self.nameLabel performSelectorOnMainThread:@selector(setText:)  withObject:@"Calibrating ..." waitUntilDone:YES];
				delta =  MAX( (abs(lastIntensity - meanAll) - 10), delta );
				continue;
			} else if (processedCount == 11) {
				if (delta > 170) {
					delta = 170;
				}
				NSLog(@"Delta set to %f - beginning decode", delta);
			}
			

			
			// check if light changed 
			if(abs(lastIntensity - meanAll) > delta) {
				if(startSlot > 0) {
					if ((endSlot - startSlot) > 2) { // dash 
						// if became dark then dash else space
						if(lastIntensity > meanAll) {
							messageDecoded = [messageDecoded stringByAppendingString:@"-" ];
							characterDecoded = [NSString stringWithFormat:@"%@%@", characterDecoded, @"-"];
							//NSLog(@"appended dash/dit");
							
						} else {

								
							char charFromMorse = '?';
							for (int i = 0; i < [morseLookupTable count]; i++) {
								NSString* morseAlpha =  (NSString*) [morseLookupTable objectAtIndex:i];
								
								if([morseAlpha compare:characterDecoded] == NSOrderedSame) {
									if(i <= 25) {
										charFromMorse = (char)('A' + i);
									} else if (i < 36) {
										charFromMorse = (char)('0' + (i - 26));
									} else {
										charFromMorse = ' ';
									}

									break;
								}
							}
							
							NSString* decodedPart = [NSString stringWithFormat:@"%c", charFromMorse];
							if (charFromMorse == '?' && characterDecoded != nil && [characterDecoded length] > 0) {
								// try to see if there is an extra bit 
								
								char charFromMorse1 = '?';
								for (int i = 0; i < [morseLookupTable count]; i++) {
									NSString* morseAlpha =  (NSString*) [morseLookupTable objectAtIndex:i];
									NSString* characterDecodedMinusFirst = [characterDecoded substringFromIndex:1];
									if([morseAlpha compare:characterDecodedMinusFirst] == NSOrderedSame) {
										if(i <= 25) {
											charFromMorse1 = (char)('A' + i);
										} else if (i < 36) {
											charFromMorse1 = (char)('0' + (i - 26));
										} else {
											charFromMorse1 = ' ';
										}
										break;
									}
								}

								char charFromMorse2 = '?';								
								for (int i = 0; i < [morseLookupTable count]; i++) {
									NSString* morseAlpha =  (NSString*) [morseLookupTable objectAtIndex:i];
									NSString* characterDecodedMinusLast = [characterDecoded substringToIndex:([characterDecoded length] - 2)];
									
									if([morseAlpha compare:characterDecodedMinusLast] == NSOrderedSame) {
										if(i <= 25) {
											charFromMorse2 = (char)('A' + i);
										} else if (i < 36) {
											charFromMorse2 = (char)('0' + (i - 26));
										} else {
											charFromMorse2 = ' ';
										}
										break;
									}
								}
								if (charFromMorse2 != '?' || charFromMorse1 != '?') {
									decodedPart = [NSString stringWithFormat:@"%c|%c", charFromMorse1, charFromMorse2];
								}
								 

							}
							
							messageDecoded = [NSString stringWithFormat:@"%@[%@] ", messageDecoded, decodedPart];
							letterDecoded = [NSString stringWithFormat:@"%@%c", letterDecoded, charFromMorse];
							
							// clear running string
							characterDecoded = @"";

						}

					} else {
						// if became dark then dot 
						if(lastIntensity > meanAll && abs(lastIntensity - meanAll) >= delta) {
							//NSLog(@"appended dot");
							messageDecoded = [messageDecoded stringByAppendingString:@"."];
							characterDecoded = [NSString stringWithFormat:@"%@%@", characterDecoded, @"."];
						}
					}
				}
				// calibrate start and end to this slot 
				startSlot = endSlot = 1;
			} else {
				// increment end slot when light intensity same
				endSlot++;
			}
			
			// this means the video is idle so stop
			if(endSlot > 25) {
				[self.nameLabel performSelectorOnMainThread:@selector(setText:)  withObject:@"No activity - stopping decoding" waitUntilDone:YES];
				break;
			}
			lastIntensity = meanAll;

			if ([messageDecoded length] > 30) {
				int advancedby = [messageDecoded length] - [[self nameLabel].text length];
				messageDecoded = [messageDecoded substringFromIndex:advancedby];
			}
			if ([letterDecoded length] > 18) {
				letterDecoded = [letterDecoded substringFromIndex:1];
			}

			[self.nameLabel performSelectorOnMainThread:@selector(setText:)  withObject:messageDecoded waitUntilDone:YES];
			[self.meanLabel performSelectorOnMainThread:@selector(setText:)  withObject:letterDecoded waitUntilDone:YES];
		} else {
			// resume enque if you paused it and queue was emptied
			if (enquePaused && [imageQueue count] == 0) {
				enquePaused = FALSE;
			}
		}
	}
	//if(pool != nil) {
		// give some time before you release
		[NSThread sleepForTimeInterval:5.0];
		//[pool drain];
		//[pool release]; 
	//}
} 

- (char)getAlphaFromMorseCode:(NSString*) morseString {
	char ret = '?';
	for (int i = 0; i < [morseLookupTable count]; i++) {
		NSString* morseAlpha =  (NSString*) [morseLookupTable objectAtIndex:i];
		if([morseAlpha isEqualToString:morseString]) {
			ret = (char)('A' + i);
		}
	}
	return ret;
}

- (IBAction)stopMorseDecode {
	[self.captureSession stopRunning];
	[self dismissModalViewControllerAnimated:YES];
	[[Torch sharedInstance] stopStrobe];
	[[Torch sharedInstance] softReset];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
	// stop enqueing until all are decoded
	enquePaused = true;
	
}

@end