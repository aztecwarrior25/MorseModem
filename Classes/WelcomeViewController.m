#import "WelcomeViewController.h"
#import "MyAVController.h"
#import "MessageSend.h"
#import "Torch.h"

@implementation WelcomeViewController

@synthesize message;
@synthesize morseLookupTable;

- (void)viewDidLoad {
     
}

/* Moved to other page
- (IBAction) startMorseStrobe {
	
	morseLookupTable = [[NSMutableArray alloc] initWithObjects: 
						@". - ",
						@"- . . . ",        
						@"- . - . ",       
						@"- . . ",         
						@". ",           
						@". . - . ",        
						@"- - . ",         
						@". . . . ",        
						@". . ",          
						@". - - - ",        
						@"- . - ",         
						@". - . . ",        
						@"- - ",        
						@"- . ",          
						@"- - - ",         
						@". - - . ",        
						@"- - . - ",        
						@". - . ",         
						@". . . ",         
						@"- ",           
						@". . - ",         
						@". . . - ",        
						@". - - ",         
						@"- . . - ",        
						@"- . - - ",
						@"- - . . ", nil];
	
	NSString *outputString = @"";	
	if (message.text != nil && [message.text length] > 0) {
		
		for (int i = 0; i < [message.text length]; i++) {
			char c = [message.text characterAtIndex:i];
			if(c == ' ') {
	 		    outputString = [outputString stringByAppendingString:@"_"];
			} else {
				int alphaIndex = (int)(c-'A');
				NSLog(@"%c alpha position %d", c, alphaIndex);
				NSString *morseString = (NSString*)[morseLookupTable objectAtIndex: alphaIndex];
				outputString = [outputString stringByAppendingString: morseString ];
				outputString = [outputString stringByAppendingString:@"_"];
			}
			
		}
	}
	
	//Start the torch move this to main app
	
	Torch* torch = [Torch sharedInstance];
	//defaults to "APPLE"
	NSString *inputM = @"_. -_. - - ._. - - ._. - . ._._ ";
	if(outputString != nil && [outputString length] > 0) {
		inputM = outputString;
	}
	
	[torch startStrobesForMorseString:inputM forCharacterInterval:0.5f];
		
}
*/

- (IBAction) startMorseStrobe {
	[self presentModalViewController:[[MessageSend alloc] init] animated:YES];
}

- (IBAction)startFlashcodeDetection {
	
	[self presentModalViewController:[[MyAVController alloc] init] animated:YES];
}



- (void)dealloc {
    [super dealloc];
}

@end
