#import <UIKit/UIKit.h>

@interface WelcomeViewController : UIViewController {
	IBOutlet UITextField *message;
	NSMutableArray *morseLookupTable; 
}

@property (nonatomic, retain) UITextField *message;
@property (nonatomic, retain) NSMutableArray *morseLookupTable;

- (IBAction) startFlashcodeDetection;
- (IBAction) startMorseStrobe;

@end
