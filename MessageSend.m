//
//  MessageSend.m
//  MyAVController
//
//  Created by Shriniwas Kulkarni on 3/28/11.
//  Copyright 2011 ASU. All rights reserved.
//

#import "MessageSend.h"
#import "Torch.h"


@implementation MessageSend

@synthesize message;
@synthesize morseLookupTable;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (IBAction) startMorseStrobe {
	
	[message resignFirstResponder];
	morseLookupTable = [[NSMutableArray alloc] initWithObjects: 
						@". - ",		//A
						@"- . . . ",    //B    
						@"- . - . ",    //C   
						@"- . . ",      //D  
						@". ",          //E 
						@". . - . ",    //F
						@"- - . ",      //G
						@". . . . ",    //H
						@". . ",        //I
						@". - - - ",    //J
						@"- . - ",      //K
						@". - . . ",    //L
						@"- - ",        //M
						@"- . ",        //N
						@"- - - ",      //O
						@". - - . ",    //P
						@"- - . - ",    //Q
						@". - . ",      //R
						@". . . ",      //S
						@"- ",          //T
						@". . - ",      //U   
						@". . . - ",    //V    
						@". - - ",      //W   
						@"- . . - ",    //X    
						@"- . - - ",    //Y 
						@"- - . . ",    //Z - #25
						@"- - - - - ",  //0 - #26
						@". - - - - ",  //1
						@". . - - - ",  //2
						@". . . - - ",  //3
						@". . . . - ",  //4
						@". . . . . ",  //5
						@"- . . . . ",  //6				
						@"- - . . . ",  //7						
						@"- - - . . ",  //8						
						@"- - - - . ",  //9
						@". . . . . . . ",  //space - #36
						nil];
	
	NSString *outputString = @"";	
	if (message.text != nil && [message.text length] > 0) {
		
		for (int i = 0; i < [message.text length]; i++) {
			char c = [message.text characterAtIndex:i];
			// only allow spaces, alphabets (uppercase) and numerals
			if(c == ' ') {
				NSString *morseString = (NSString*)[morseLookupTable objectAtIndex: 36];
				outputString = [outputString stringByAppendingString: morseString ];
				outputString = [outputString stringByAppendingString:@"_"];
			} else if (c >= 48 && c <= 57) {
				int numIndex = (int)(c-'0') + 26;
				NSLog(@"%c num position %d", c, numIndex);
				NSString *morseString = (NSString*)[morseLookupTable objectAtIndex: numIndex];
				outputString = [outputString stringByAppendingString: morseString ];
				outputString = [outputString stringByAppendingString:@"_"];
			} else if (c >= 65 && c <= 90) {
				int alphaIndex = (int)(c-'A');
				NSLog(@"%c alpha position %d", c, alphaIndex);
				NSString *morseString = (NSString*)[morseLookupTable objectAtIndex: alphaIndex];
				outputString = [outputString stringByAppendingString: morseString ];
				outputString = [outputString stringByAppendingString:@"_"];
			}
			
		}
		// extra space at end 
		NSString *morseSpace = (NSString*)[morseLookupTable objectAtIndex: 36];
		outputString = [outputString stringByAppendingString: morseSpace ];
		outputString = [outputString stringByAppendingString:@"_"];
	}
	
	// Start the torch 
	// disable
	startButton.hidden = YES;
	
	torch = [Torch sharedInstance];
	[torch stopStrobe];
	//defaults to "APPLE"
	NSString *inputM = @"_. -_. - - ._. - - ._. - . ._._ ";
	if(outputString != nil && [outputString length] > 0) {
		inputM = outputString;
	}
	torch.mLineElements = inputM;
	torch.mLineLength = [inputM length];
	[torch stop];
	[torch start];
	[torch startStrobesForMorseString:inputM forCharacterInterval:0.5f];

	NSString *finalString = [inputM stringByReplacingOccurrencesOfString:@" " withString:@""] ;
	
	
	msgText.text = [ NSString stringWithFormat:@"Transmitting Message \nText: %@ \n Morse: %@" , message.text, finalString] ;
	
}

-(BOOL) textFieldShouldReturn:(UITextField*) textField {
    [textField resignFirstResponder]; 
    return YES;
}


- (void)dealloc {
    [super dealloc];
}

- (IBAction) stopMorseStrobe {
	[[Torch sharedInstance] stopStrobe];
	[[Torch sharedInstance] stop];
	startButton.hidden = NO;
	msgText.text = @"";
	//[self dismissModalViewControllerAnimated:YES];
}

- (IBAction) backToMain {
	[self dismissModalViewControllerAnimated:YES];
}


@end
